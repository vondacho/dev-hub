# Ansible delivery

The same delivery as `iac/terraform`, without Terraform. Same registry
(`iac/components.yaml`), same profiles (`iac/profiles/`), same charts
(`helm/`), same issuer chart (`iac/charts/cluster-issuer`).

## Where the line is

Ansible here **delivers to a cluster; it does not create one.** That is not a
gap waiting to be filled — a cluster is long-lived state with a lifecycle,
which is what Terraform is for, and reimplementing that against three cloud
APIs in playbooks would buy nothing.

Use this path when:

- the cluster already exists and is somebody else's to manage;
- delivery runs from a pipeline that is Ansible-shaped;
- you want to roll one component forward without a Terraform plan over the
  whole environment.

Use Terraform when the cluster, the registry and the network are yours too.

The two are interchangeable at the release level: both run `helm upgrade
--install` with the same values stack, so whichever runs second reconciles the
first's release rather than fighting it.

## Setup

```bash
ansible-galaxy collection install -r requirements.yml
pip install kubernetes      # kubernetes.core needs the Python client
```

Then point an inventory at a cluster. `inventories/<provider>/group_vars/all.yml`
is the Ansible equivalent of a `terraform.tfvars` — the registry, the domain,
the profile and the kubeconfig context:

```bash
aws eks update-kubeconfig --name dev-hub-prod --region eu-central-1
# or
doctl kubernetes cluster kubeconfig save dev-hub-prod
```

There are no managed hosts. Every task runs on the controller and talks to the
cluster API; the inventory exists to carry variables, not machines.

## Running

```bash
ansible-playbook playbooks/site.yml -i inventories/aws

# or one stage at a time
ansible-playbook playbooks/build-push.yml -i inventories/aws -e image_tag=$(git rev-parse --short HEAD)
ansible-playbook playbooks/platform.yml   -i inventories/aws
ansible-playbook playbooks/deploy.yml     -i inventories/aws -e image_tag=$(git rev-parse --short HEAD)
ansible-playbook playbooks/verify.yml     -i inventories/aws
```

| Playbook | Does |
|----------|------|
| `site.yml` | images → platform → components → verify, in that order |
| `build-push.yml` | builds every component image and pushes it |
| `platform.yml` | ingress-nginx, cert-manager, the ClusterIssuer |
| `deploy.yml` | the components, from the charts under `helm/` |
| `verify.yml` | waits for the rollout, then runs each chart's own `helm test` |
| `uninstall.yml` | removes the releases; `-e drop_namespaces=true` for their namespaces too |

Useful overrides on any of them:

```bash
-e image_tag=abc1234
-e '{"only": ["dev-portal"]}'      # one component
--skip-tags images                  # site.yml, when the images already exist
```

## What verify actually checks

`helm test` runs the hooks the chart ships, not a second opinion written here.
For dev-portal that is one URL per thing that can independently fail —
`/healthz`, `/`, `/catalog`, and three `/doc/*` pages that only answer if the
prerendered Starlight output shipped in the image. A bare health check passes
while every rendered page is broken.

## Secrets

Cloud credentials come from the environment (`AWS_PROFILE`,
`DIGITALOCEAN_TOKEN`), never from `group_vars`. Anything else that has to be
per-environment and secret goes in an ansible-vault file the `.gitignore`
already excludes:

```bash
ansible-vault create inventories/aws/vault.yml
ansible-playbook playbooks/site.yml -i inventories/aws --ask-vault-pass
```
