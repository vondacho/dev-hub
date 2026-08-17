provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "dev-hub"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# The Kubernetes and Helm providers are configured from the cluster this same
# root module creates. That is why delivery happens in two applies — see the
# comment on deploy_platform in variables.tf. Terraform tolerates an unknown
# provider configuration as long as no resource of that provider is created in
# the same plan, which is exactly what deploy_platform=false buys.
#
# Authentication is an exec plugin rather than a token, on purpose: the EKS
# token lasts fifteen minutes, so anything captured into state is expired before
# it is read. `aws eks get-token` mints a fresh one on every call, using
# whatever credentials the AWS provider itself is using.

locals {
  kube_exec = {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks", "get-token",
      "--cluster-name", module.cluster.cluster_name,
      "--region", var.region,
      "--output", "json",
    ]
  }
}

provider "kubernetes" {
  host                   = module.cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.cluster.cluster_ca_certificate)

  exec {
    api_version = local.kube_exec.api_version
    command     = local.kube_exec.command
    args        = local.kube_exec.args
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.cluster.cluster_ca_certificate)

    exec = {
      api_version = local.kube_exec.api_version
      command     = local.kube_exec.command
      args        = local.kube_exec.args
    }
  }
}
