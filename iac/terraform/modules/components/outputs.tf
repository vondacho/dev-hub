output "releases" {
  description = "Installed releases, keyed by component name."
  value = {
    for name, c in local.components : name => {
      release   = helm_release.component[name].name
      namespace = helm_release.component[name].namespace
      # metadata is a single object on the helm provider v3, not a list.
      revision = helm_release.component[name].metadata.revision
      chart    = c.chart
      image    = "${var.registry}/${c.image}:${var.image_tag}"
    }
  }
}

output "urls" {
  description = "Where each component is reachable once DNS points at the ingress load balancer."
  value = {
    for name, c in local.components : name => "${var.url_scheme}://${c.host}.${var.base_domain}"
  }
}

output "dns_names" {
  description = "Every hostname that has to resolve to the ingress load balancer, ready to hand to a DNS zone."
  value       = sort([for c in local.components : "${c.host}.${var.base_domain}"])
}

output "images" {
  description = "Fully qualified images this environment expects to exist. Feed to iac/scripts/build-push.sh."
  value = {
    for name, c in local.components : name => "${var.registry}/${c.image}:${var.image_tag}"
  }
}
