# Both providers read an existing kubeconfig. No cluster is created here, so
# nothing in this environment is unknown at plan time — this is the one
# environment that delivers in a single apply.

provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kube_context != "" ? var.kube_context : null
}

provider "helm" {
  kubernetes = {
    config_path    = var.kubeconfig_path
    config_context = var.kube_context != "" ? var.kube_context : null
  }
}
