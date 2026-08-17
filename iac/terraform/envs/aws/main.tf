# dev-hub on AWS: EKS, the platform that fronts it, and the components from the
# charts under helm/.
#
# Three modules, in the order the traffic flows: a cluster, an ingress
# controller with an issuer, then the releases. Only the first of the three is
# AWS-specific — envs/digitalocean is the same file with a different cluster
# module, which is the whole point of the split.

locals {
  # The repository root, four levels up: aws -> envs -> terraform -> iac -> root.
  # Charts are resolved from here, so helm/ stays the only copy of them.
  repo_root = abspath("${path.module}/../../../..")
  iac_root  = abspath("${path.module}/../../..")

  components_file = "${local.iac_root}/components.yaml"
  registry        = yamldecode(file(local.components_file)).components

  cluster_name = var.cluster_name != "" ? var.cluster_name : "dev-hub-${var.environment}"

  # One ECR repository per component image, taken from the registry rather than
  # listed again here.
  component_images = [for c in local.registry : c.image]
}

module "cluster" {
  source = "../../modules/cluster-aws"

  name               = local.cluster_name
  kubernetes_version = var.kubernetes_version

  single_nat_gateway           = var.single_nat_gateway
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs

  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_max_size       = var.node_max_size

  ecr_repositories = local.component_images

  tags = {
    Environment = var.environment
  }
}

module "platform" {
  source = "../../modules/platform"
  count  = var.deploy_platform ? 1 : 0

  ingress_service_annotations = module.cluster.ingress_service_annotations

  acme_email   = var.acme_email
  acme_staging = var.acme_staging

  # EKS ships without one, so `kubectl top` and every HPA are dead until this
  # is installed. DOKS already has it — hence the difference between the envs.
  metrics_server = true
}

module "components" {
  source = "../../modules/components"
  count  = var.deploy_components ? 1 : 0

  repo_root       = local.repo_root
  components_file = local.components_file
  profiles_dir    = "${local.iac_root}/profiles"
  profile         = "aws"

  registry    = module.cluster.registry
  image_tag   = var.image_tag
  base_domain = var.base_domain

  only             = var.components
  component_values = var.component_values

  # ECR is read through the node role, so nothing to carry here.
  image_pull_secrets = []

  # Empty unless the platform module was skipped and the cluster's own class
  # should be used instead.
  ingress_class_name = var.deploy_platform ? module.platform[0].ingress_class_name : ""

  tls_enabled = var.deploy_platform

  depends_on = [module.platform]
}

# The address the DNS records have to point at. Read back from the Service
# rather than from an aws_lb data source: the controller's Service is what
# actually provisioned the load balancer, so this cannot drift from it.
data "kubernetes_service_v1" "ingress" {
  count = var.deploy_platform ? 1 : 0

  metadata {
    name      = "ingress-nginx-controller"
    namespace = module.platform[0].ingress_namespace
  }

  depends_on = [module.platform]
}
