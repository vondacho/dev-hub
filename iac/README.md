# Infrastructure as code

Delivery of the dev-hub components to a cloud — AWS, DigitalOcean, or any
Kubernetes cluster somebody else provisioned.

**Nothing here re-authors a manifest.** The charts under `helm/` stay the only
place a Kubernetes object is described; this directory provisions the cluster
underneath them and layers the values that differ per environment on top. Adding
a component is one entry in `components.yaml` plus its chart in `helm/` — both
delivery paths, and all three environments, pick it up with no further edit.

For everyday local work, keep using `./helm/dev-portal/deploy.sh`. It builds
straight into the node's image store and needs no registry, no domain and no
cloud account. This directory is for the case where those three exist.

## Layout

```
iac/
  components.yaml          registry of deliverable components — read by both paths
  Makefile                 the order of operations, so it is not folklore
  profiles/                Helm values overlays, one per provider
  charts/cluster-issuer/   one ClusterIssuer, installed by both paths
  terraform/
    modules/
      cluster-aws/           VPC + EKS + ECR
      cluster-digitalocean/  VPC + DOKS + DOCR
      platform/              ingress-nginx, cert-manager, the issuer
      components/            one helm_release per registry entry, from helm/
    envs/
      aws/                   root module: cluster + platform + components
      digitalocean/          the same file with the cluster module swapped
      generic/               no cloud at all — deliver to an existing cluster
  ansible/                 the same delivery without Terraform
  scripts/
    build-push.sh          build every component image and push it
    preflight.sh           check tools and credentials before anything is created
```

## The two axes

Everything here is the crossing of two independent choices, and keeping them
independent is the point.

**Where the cluster comes from.** `envs/aws` and `envs/digitalocean` create one.
`envs/generic` creates nothing and delivers to whatever the kubeconfig points at
— GKE, AKS, Scaleway, Hetzner, OVH, a self-managed k3s, a shared platform
cluster. Supporting a new cloud *properly* means one new `cluster-<provider>`
module; supporting one *at all* means nothing, because `generic` already works.

**How the components are configured.** The profile stack, layered last-wins:

| # | Layer | Owned by |
|---|-------|----------|
| 1 | `helm/<chart>/values.yaml` | the chart |
| 2 | `iac/profiles/common.yaml` | every real cluster |
| 3 | `iac/profiles/<provider>.yaml` | that provider |
| 4 | computed overlay | this environment: registry, tag, hosts, TLS, pull secrets |

See `profiles/README.md`. Layer 4 is never written by hand — Terraform and
Ansible each compute the same structure from `components.yaml` and the
environment's `base_domain`.

## Delivering

```bash
make preflight PROVIDER=aws          # tools, credentials, charts
cd terraform/envs/aws
cp terraform.tfvars.example terraform.tfvars   # then edit it
cd ../../..
make up     PROVIDER=aws             # cluster, then platform and components
make images PROVIDER=aws TAG=$(git rev-parse --short HEAD)
make apply  PROVIDER=aws             # roll the releases onto that tag
make output PROVIDER=aws             # URLs, DNS names, load balancer address
```

Then point the names in the `dns_names` output at the load balancer address
(`ingress_load_balancer_hostname` on AWS, `ingress_load_balancer_ip` on
DigitalOcean). No DNS zone is managed here: the zone usually belongs to
somebody who is not deploying a portal.

Certificates cannot be issued until those names resolve — that is what the
HTTP-01 challenge checks. Start with `acme_staging = true` and flip it once a
name answers, so a few failed attempts do not spend the production rate limit.

### Why `make up` applies twice

Only on the first run, and only for the cloud environments. The Kubernetes and
Helm providers are configured from the cluster the same root module creates, so
on the very first plan their configuration is not yet known. Terraform tolerates
that exactly while no resource of those providers is in the plan, which is what
`-var deploy_platform=false -var deploy_components=false` buys. Every later
apply is a single pass, because the cluster is in state by then.

`envs/generic` never has this problem — it creates no cluster, so it applies in
one go.

### Ansible instead

Same registry, same profiles, same charts, no Terraform:

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml
ansible-playbook playbooks/site.yml -i inventories/aws
```

The two paths install the same releases from the same sources, so whichever runs
second reconciles the first's work rather than fighting it. What Ansible does
*not* do is create a cluster — see `ansible/README.md` for where the line is.

## Image tags

Prefer a git SHA. A moving tag re-pushed under the same name renders a
byte-identical Deployment, so Kubernetes sees no change and leaves the old pods
running — while Helm and Terraform both report success. `helm/README.md`
documents the same trap on the local path, where `deploy.sh` works around it
with an explicit rollout restart. Here, an immutable tag removes it instead.

Images are built for `linux/amd64` by default. On an Apple Silicon laptop the
default would otherwise be arm64, which lands on an amd64 node and dies with
`exec format error` — a failure that looks nothing like its cause.

## State

Local until a `backend.tf` says otherwise, which is fine for the first apply
from one machine and wrong from the second. Copy `backend.tf.example` in the
environment and `terraform init -migrate-state` before anyone else applies.

`terraform.tfvars`, `backend.tf` and `*.tfstate` are gitignored; the `.example`
files next to them are the ones that get committed. `.terraform.lock.hcl` is
written by the first `terraform init` in an environment and **is** committed
once it appears — it is the record of which provider builds were verified.

## Costs, briefly

Neither environment is free, and both default to the cheap end of sane:

- **AWS** — an EKS control plane is charged per hour whether or not anything
  runs on it, plus two `t3.medium` nodes, one NAT gateway (`single_nat_gateway`
  is on) and one NLB.
- **DigitalOcean** — the DOKS control plane is free unless `ha_control_plane` is
  on, plus two `s-2vcpu-4gb` nodes, one load balancer and a registry
  subscription.

`make destroy PROVIDER=<provider>` removes everything the environment created,
the cluster included.

## Adding a component

1. Add its chart under `helm/<component>/`, following `helm/README.md`.
2. Add an entry to `components.yaml` — chart path, build context, image name,
   namespace, host label, and any browser-facing links it renders.

Both delivery paths and all three environments pick it up. Its ECR repository is
created from the same list, so nothing has to be listed twice.

## Adding a cloud

If you only need to *deliver* there, use `envs/generic` — it needs a kubeconfig
and a registry, nothing else.

If you want the cluster created here too: copy `modules/cluster-digitalocean`
(the smaller of the two), give it the same outputs — `cluster_endpoint`,
`cluster_ca_certificate`, `registry`, `ingress_service_annotations` — and copy
`envs/digitalocean` with the cluster module swapped. The platform and components
modules do not change, and neither does anything under `helm/`. That is the
property this whole directory is arranged to keep.
