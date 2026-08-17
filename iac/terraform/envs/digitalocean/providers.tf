provider "digitalocean" {
  # Read from DIGITALOCEAN_TOKEN. Not a variable on purpose: a token in a
  # tfvars file is a token in somebody's shell history.
  #
  # Spaces keys, if a Spaces backend is configured, come from
  # SPACES_ACCESS_KEY_ID / SPACES_SECRET_ACCESS_KEY.
}

# Configured from the cluster this same root module creates, which is why the
# first delivery takes two applies — see deploy_platform in variables.tf.
#
# The credential is an exec plugin rather than the token from the generated
# kubeconfig. That token expires after seven days; captured into state, it
# turns into an apply that fails a week later with a 401 and no obvious cause.
# `doctl kubernetes cluster kubeconfig exec-credential` mints a fresh one.
locals {
  kube_exec = {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "doctl"
    args = [
      "kubernetes", "cluster", "kubeconfig", "exec-credential",
      "--version=v1beta1",
      "--context=default",
      module.cluster.cluster_id,
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
