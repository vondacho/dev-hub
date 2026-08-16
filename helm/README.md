# Helm charts

Deployment charts for the dev-hub components. Following the same
monorepo-of-standalone-modules convention as api-hub and arch-hub, **each
component gets its own independent chart** — there is no umbrella chart.

| Chart | Component | Status |
|-------|-----------|--------|
| `dev-portal/` | `dev-portal` Astro frontend | present |

The chart is **built from this repo**: `values-local.yaml` pins `tag: dev` with
`pullPolicy: Never`, so the image has to be built into the node's image store
first — there is nothing to pull.

The ingress is enabled **by default**, matching the arch-hub charts and
deviating from the api-hub ones. A browser frontend nobody can open is not a
useful default, and `*.localhost` costs nothing on a local cluster.

## Prerequisites

- A local Kubernetes cluster. This machine's kubeconfig has `rancher-desktop`
  as the current context.
- `helm` v3+ and `kubectl` — Rancher Desktop ships both at `~/.rd/bin/`.
- A container build tool (`docker`, or `nerdctl` when Rancher Desktop runs
  containerd — see *Build engine gotcha*).

## Deploy

```bash
./helm/dev-portal/deploy.sh
```

That is the whole thing: it builds the image with whichever engine Rancher
Desktop is configured for, installs the release into the `dev-hub` namespace
(creating it), restarts the pods onto the rebuilt image, waits for the rollout,
prints the running pods with their image IDs, and runs `helm test`.

| Flag | Effect |
|------|--------|
| `--no-build` | Skip the image build — chart-only changes |
| `--no-test` | Skip `helm test` |

| Variable | Default |
|----------|---------|
| `NAMESPACE` | `dev-hub` |
| `RELEASE` | `dev-portal` |
| `IMAGE_TAG` | `dev` (must match `image.tag` in `values-local.yaml`) |

By hand, the same three steps:

```bash
# 1. build into the store the kubelet reads
cd dev-portal && docker build -t dev-portal:dev .

# 2. reconcile the release
helm upgrade --install dev-portal helm/dev-portal \
  --namespace dev-hub --create-namespace \
  -f helm/dev-portal/values-local.yaml

# 3. force the pods onto the new image
kubectl rollout restart deployment/dev-portal -n dev-hub
kubectl rollout status  deployment/dev-portal -n dev-hub --timeout=300s
```

**Why step 3 is not optional.** `values-local.yaml` pins `tag: dev` with
`pullPolicy: Never`. Rebuilding produces a new image under the *same* tag, so
the rendered Deployment is byte-identical to the one already applied —
Kubernetes sees no change and leaves the old pods running, while `helm upgrade`
still reports `STATUS: deployed` and bumps the revision. The `checksum/config`
annotation covers *ConfigMap* changes only; it does nothing for an image
rebuilt under a fixed tag.

Confirm the pod actually picked the image up rather than trusting the rollout,
and print the `DELETING` column instead of filtering on `status.phase` — a
terminating pod still reports `Running`, so for a few seconds it can still be
`items[0]` and report the *old* digest:

```bash
kubectl get pods -n dev-hub -l app.kubernetes.io/name=dev-portal \
  -o custom-columns='NAME:.metadata.name,DELETING:.metadata.deletionTimestamp,IMAGEID:.status.containerStatuses[0].imageID'
docker inspect dev-portal:dev --format '{{.Id}}'
```

## Verify

```bash
helm test dev-portal -n dev-hub
open http://dev-portal.localhost
```

Rancher Desktop runs Traefik as the default IngressClass and `*.localhost`
resolves to 127.0.0.1, so the portal is reachable from the host with no
port-forward. With `ingress.enabled=false`:

```bash
kubectl -n dev-hub port-forward svc/dev-portal 4321:4321
```

`helm test` fetches one URL per thing that can independently fail — `/healthz`,
`/`, `/catalog`, `/catalog/stacks/ios`, `/doc/` and `/doc/practices/bdd/`. A
bare health check passes while every rendered page is broken, `/catalog` is the
page that reads the outbound addresses from the ConfigMap, `/catalog/stacks/ios`
proves the dynamic route resolves, and the two `/doc/` URLs prove the
prerendered Starlight output shipped in the image.

## Remove

```bash
./helm/dev-portal/uninstall.sh              # the release
./helm/dev-portal/uninstall.sh --namespace  # and the namespace, if empty
```

## Build engine gotcha

`nerdctl build` fails with `no buildkit host is available` when Rancher Desktop
is configured for **moby** rather than containerd. `deploy.sh` reads the setting
and picks the right command; to check by hand:

```bash
grep -o '"name":"[a-z]*"' ~/Library/Preferences/rancher-desktop/settings.json
```

`moby` means `docker build`; `containerd` means `nerdctl --namespace k8s.io
build`. This machine currently reports `moby`.

## Notes on the dev-portal chart

- **The portal is server-rendered** (`output: 'server'` + `@astrojs/node` in
  standalone mode). The Starlight documentation under `/doc/*` is prerendered
  inside that same server, because prose has no reason to be rendered per
  request and Pagefind builds its search index from the emitted HTML. A docs
  change therefore needs a rebuild, not just a restart.
- **Five config knobs**, all rendered into a ConfigMap and injected with
  `envFrom`. `src/lib/links.ts` reads each through `process.env` at call time
  and falls back to the same default the chart ships, so an unset value and the
  default look identical in the page — override one to something obviously
  wrong if you ever need to prove the wiring works.

  | Key | Points at |
  |-----|-----------|
  | `API_PORTAL_URL` | api-hub's portal — the API catalog panel |
  | `ARCH_PORTAL_URL` | arch-hub's portal — the footer link |
  | `ARCH_C4_URL` | arch-hub's `arch-c4` — the C4 catalog panel |
  | `ARCH_EVENTCATALOG_URL` | arch-hub's `arch-eventcatalog` — the Events panel |
  | `ARCH_APPMAP_URL` | arch-hub's `arch-appmap` — the Components panel |

- **They are browser-facing links, not in-cluster calls.** Each points at a
  Traefik ingress host because the *visitor's browser* resolves it.
  `http://api-portal:4321` would be wrong here even though the portal is
  server-rendered — and it would also be wrong because those releases live in
  the `api-hub` and `arch-hub` namespaces, not this one.
- **The prerendered docs reach them through `/go/*`.** A page under `/doc/*` is
  emitted at build time, so calling `apiPortalUrl()` from one would resolve it
  on the build machine and bake the answer into the image, leaving the ConfigMap
  silently doing nothing. Those pages link to `/go/api`, `/go/c4`, `/go/events`,
  `/go/components` or `/go/arch` instead — server-rendered routes that read the
  environment per request and 302. The portal's own pages skip the hop.
- Probes hit `/healthz`, served by `dev-portal/src/pages/healthz.ts`.
- `readOnlyRootFilesystem: true` with `emptyDir`s at `/tmp` and
  `/app/node_modules/.astro`. `@astrojs/node` bakes that session path into the
  bundle at build time and creates it lazily. Nothing in the portal uses
  `Astro.session` today, so the mount is insurance: without it, the first page
  that ever does would fail in the cluster and nowhere else.
- The pod runs as **uid/gid 10001**, matching the `app` user in the Dockerfile.
  1000 is deliberately avoided — the `node` base image already uses it.
- The ingress is routed at `/`, not per-section: one server owns the home page,
  `/catalog` and its stack pages, `/academy`, the `/go/*` redirects, `/doc/*`
  and the hashed assets under `/_astro/*`, and Pagefind fetches its index by
  absolute path.

## Chart layout

```
dev-portal/
  Chart.yaml
  values.yaml                     # defaults
  values-local.yaml               # local-cluster overrides
  deploy.sh                       # build + upgrade + restart + test
  uninstall.sh
  templates/
    _helpers.tpl
    configmap.yaml                # app config, injected with envFrom
    deployment.yaml
    service.yaml
    serviceaccount.yaml
    ingress.yaml
    NOTES.txt
    tests/test-connection.yaml
```

No storage: the release is stateless, so `replicaCount` is free to move.
