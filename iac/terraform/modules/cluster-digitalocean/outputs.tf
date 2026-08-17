output "cluster_name" {
  description = "DOKS cluster name."
  value       = digitalocean_kubernetes_cluster.this.name
}

output "cluster_id" {
  description = "Cluster UUID, which is what doctl and the API take."
  value       = digitalocean_kubernetes_cluster.this.id
}

output "cluster_endpoint" {
  description = "API server endpoint."
  value       = digitalocean_kubernetes_cluster.this.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64 CA bundle for the API server."
  value       = digitalocean_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate
}

output "cluster_token" {
  description = <<-EOT
    Bearer token from the generated kubeconfig.

    It expires after seven days. Fine for an apply, wrong for anything
    long-lived: a pipeline should call `doctl kubernetes cluster kubeconfig
    save` instead, or configure the providers with an exec block — see
    providers.tf in the digitalocean environment.
  EOT
  value       = digitalocean_kubernetes_cluster.this.kube_config[0].token
  sensitive   = true
}

output "cluster_version" {
  description = "Kubernetes version actually running, which auto_upgrade moves without asking."
  value       = digitalocean_kubernetes_cluster.this.version
}

output "vpc_id" {
  description = "VPC the cluster runs in."
  value       = digitalocean_vpc.this.id
}

output "registry" {
  description = "Registry prefix to hand the components module — images resolve as <registry>/<image>:<tag>."
  value       = "registry.digitalocean.com/${var.registry_name}"
}

output "image_pull_secret_name" {
  description = <<-EOT
    Name of the pull secret DOKS maintains in every namespace when
    registry_integration is on — it is the registry name. Empty otherwise, and
    then a secret has to be created some other way.
  EOT
  value       = var.registry_integration ? var.registry_name : ""
}

output "kubeconfig_command" {
  description = "Write this cluster into the local kubeconfig, with a credential that refreshes rather than expiring in a week."
  value       = "doctl kubernetes cluster kubeconfig save ${digitalocean_kubernetes_cluster.this.name}"
}

output "registry_login_command" {
  description = "Authenticate a local container engine against the registry."
  value       = "doctl registry login"
}

output "ingress_service_annotations" {
  description = <<-EOT
    Annotations to put on the ingress controller's Service on this provider.

    PROXY protocol rather than X-Forwarded-For: a DigitalOcean load balancer
    passing TCP through has no other way to tell the controller who the client
    was. It has to be enabled on both sides — the matching
    `use-proxy-protocol: "true"` goes into the controller config, which is what
    ingress_nginx_extra_values in the environment is for. Enable neither or
    both; one alone breaks every request.
  EOT
  value = {
    "service.beta.kubernetes.io/do-loadbalancer-name"                  = var.name
    "service.beta.kubernetes.io/do-loadbalancer-enable-proxy-protocol" = "true"
  }
}
