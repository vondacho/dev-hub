output "cluster_name" {
  description = "DOKS cluster name."
  value       = module.cluster.cluster_name
}

output "kubeconfig_command" {
  description = "Write this cluster into the local kubeconfig, with a credential that refreshes."
  value       = module.cluster.kubeconfig_command
}

output "registry" {
  description = "Registry prefix images are delivered from."
  value       = module.cluster.registry
}

output "registry_login_command" {
  description = "Authenticate a local container engine against the registry before pushing."
  value       = module.cluster.registry_login_command
}

output "images" {
  description = "Images this environment expects to exist. iac/scripts/build-push.sh builds and pushes exactly these."
  value       = var.deploy_components ? module.components[0].images : {}
}

output "urls" {
  description = "Where each component answers, once DNS resolves and the certificate is issued."
  value       = var.deploy_components ? module.components[0].urls : {}
}

output "dns_names" {
  description = "Names that must resolve to ingress_load_balancer_ip. No zone is managed by this root module."
  value       = var.deploy_components ? module.components[0].dns_names : []
}

output "ingress_load_balancer_ip" {
  description = <<-EOT
    The DigitalOcean load balancer the ingress controller provisioned. Point
    every name in dns_names at it with an A record.

    Empty for the first minutes after the platform apply, while the load
    balancer is still being created. Re-read it with `terraform refresh`.
  EOT
  value = try(
    data.kubernetes_service_v1.ingress[0].status[0].load_balancer[0].ingress[0].ip,
    "",
  )
}

output "releases" {
  description = "Installed releases with their revision and image."
  value       = var.deploy_components ? module.components[0].releases : {}
}
