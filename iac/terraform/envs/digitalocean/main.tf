# dev-hub on DigitalOcean: DOKS, the platform that fronts it, and the components
# from the charts under helm/.
#
# Line for line the AWS environment with one module swapped. Everything that is
# not the cluster — the ingress controller, the issuer, the releases, the whole
# profile stack — is the same code reached by the same inputs, which is the
# claim the two environments exist to keep honest.

locals {
  repo_root = abspath("${path.module}/../../../..")
  iac_root  = abspath("${path.module}/../../..")

  components_file = "${local.iac_root}/components.yaml"

  cluster_name = var.cluster_name != "" ? var.cluster_name : "dev-hub-${var.environment}"
}

module "cluster" {
  source = "../../modules/cluster-digitalocean"

  name                      = local.cluster_name
  region                    = var.region
  kubernetes_version_prefix = var.kubernetes_version_prefix

  node_size      = var.node_size
  node_min_nodes = var.node_min_nodes
  node_max_nodes = var.node_max_nodes

  ha_control_plane = var.ha_control_plane

  create_registry = var.create_registry
  registry_name   = var.registry_name

  tags = ["dev-hub", var.environment]
}

module "platform" {
  source = "../../modules/platform"
  count  = var.deploy_platform ? 1 : 0

  ingress_service_annotations = module.cluster.ingress_service_annotations

  # The other half of the PROXY protocol annotation on the load balancer. The
  # two are one setting split across two systems: enable neither or both, or
  # every request arrives mangled.
  ingress_nginx_extra_values = yamlencode({
    controller = {
      config = {
        use-proxy-protocol = "true"
      }
    }
  })

  acme_email   = var.acme_email
  acme_staging = var.acme_staging

  # DOKS installs its own. A second one fights the first over the
  # metrics.k8s.io APIService, and the loser is whichever you needed.
  metrics_server = false
}

module "components" {
  source = "../../modules/components"
  count  = var.deploy_components ? 1 : 0

  repo_root       = local.repo_root
  components_file = local.components_file
  profiles_dir    = "${local.iac_root}/profiles"
  profile         = "digitalocean"

  registry    = module.cluster.registry
  image_tag   = var.image_tag
  base_domain = var.base_domain

  only             = var.components
  component_values = var.component_values

  # Maintained in every namespace by DOKS when registry_integration is on. The
  # chart runs under its own ServiceAccount, so it has to be named — patching
  # the default ServiceAccount, which is all DigitalOcean does, is not enough.
  image_pull_secrets = compact([module.cluster.image_pull_secret_name])

  ingress_class_name = var.deploy_platform ? module.platform[0].ingress_class_name : ""

  tls_enabled = var.deploy_platform

  depends_on = [module.platform]
}

data "kubernetes_service_v1" "ingress" {
  count = var.deploy_platform ? 1 : 0

  metadata {
    name      = "ingress-nginx-controller"
    namespace = module.platform[0].ingress_namespace
  }

  depends_on = [module.platform]
}
