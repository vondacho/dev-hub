# dev-hub on a cluster nobody here provisioned.
#
# The "any Kubernetes provider" path: GKE, AKS, Scaleway, Hetzner, OVH, a
# self-managed k3s or RKE2, a shared platform cluster, or a laptop. It creates
# no cloud resources at all — it takes a kubeconfig and a registry that already
# exist and delivers the same charts through the same profile stack as the AWS
# and DigitalOcean environments.
#
# There is no cluster module underneath, so nothing is unknown at plan time and
# this environment applies in one go.

locals {
  repo_root = abspath("${path.module}/../../../..")
  iac_root  = abspath("${path.module}/../../..")

  components_file = "${local.iac_root}/components.yaml"
}

module "platform" {
  source = "../../modules/platform"
  count  = var.deploy_platform ? 1 : 0

  acme_email   = var.acme_email
  acme_staging = var.acme_staging

  # Unknown provider: no annotations that assume one. A cluster that needs
  # them can pass its own here.
  ingress_service_annotations = {}

  # Almost every managed cluster ships one already, and two fight over the
  # metrics.k8s.io APIService.
  metrics_server = false
}

module "components" {
  source = "../../modules/components"

  repo_root       = local.repo_root
  components_file = local.components_file
  profiles_dir    = "${local.iac_root}/profiles"
  profile         = var.profile

  registry    = var.registry
  image_tag   = var.image_tag
  base_domain = var.base_domain
  url_scheme  = var.url_scheme

  only             = var.components
  component_values = var.component_values

  image_pull_secrets = var.image_pull_secrets
  create_namespaces  = var.create_namespaces

  # The controller installed above when there is one, otherwise whatever the
  # environment names, otherwise the profile's — which for `generic` means the
  # cluster's default class.
  ingress_class_name = var.deploy_platform ? module.platform[0].ingress_class_name : var.ingress_class_name

  tls_enabled = var.tls_enabled

  depends_on = [module.platform]
}
