# Delivery profiles

Helm values overlays, one per cloud provider. They exist so that the chart under
`helm/` stays the contract and every environment stays a *thin* difference from
it.

## The layering

Values are merged in this order, last wins:

| # | Layer | Owned by | Answers |
|---|-------|----------|---------|
| 1 | `helm/<chart>/values.yaml` | the chart | what the component needs to run at all |
| 2 | `common.yaml` | this directory | what is true of every real cluster |
| 3 | `<provider>.yaml` | this directory | what is true of EKS / DOKS / a bare cluster |
| 4 | environment overlay | Terraform or Ansible | what is true of *this* account, registry and domain |

Layer 4 is computed, never written by hand: it carries the registry host, the
image tag, the ingress hosts derived from the environment's base domain, the TLS
secret names and the pull secret. Those are the values that change per
environment; everything else changes per provider at most.

`helm/<chart>/values-local.yaml` is **not** part of this stack. It is the local
single-node path (`./helm/dev-portal/deploy.sh`), which builds straight into the
node's image store with `pullPolicy: Never` and needs none of this. Use the
`generic` environment here only when you want the *cloud* delivery mechanics
against a local cluster.

## Adding a provider

1. Copy `generic.yaml` to `<provider>.yaml` and add only what that provider does
   differently — ingress class, load balancer annotations, storage class,
   pull-secret shape.
2. Point an environment at it: `profile = "<provider>"` in the Terraform env or
   `profile: <provider>` in the Ansible group_vars.

A cluster module is only needed if you also want Terraform to *create* the
cluster. Delivering to a cluster somebody else provisioned needs nothing beyond
step 1 and the `generic` environment.

## Rule for editing

Only keys the chart declares have any effect — Helm ignores an unknown key
without a word, so a typo is a setting that silently never applies. Check
against `helm/<chart>/values.yaml` before adding one, and verify a change with:

```bash
helm template dev-portal helm/dev-portal \
  -f iac/profiles/common.yaml \
  -f iac/profiles/aws.yaml
```
