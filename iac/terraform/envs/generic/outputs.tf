output "urls" {
  description = "Where each component answers, once its name resolves to the cluster's ingress."
  value       = module.components.urls
}

output "dns_names" {
  description = "Names that must resolve to the ingress this cluster terminates on."
  value       = module.components.dns_names
}

output "images" {
  description = "Images this environment expects to exist. iac/scripts/build-push.sh builds and pushes exactly these."
  value       = module.components.images
}

output "releases" {
  description = "Installed releases with their revision and image."
  value       = module.components.releases
}
