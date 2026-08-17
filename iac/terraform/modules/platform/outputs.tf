output "ingress_class_name" {
  description = "IngressClass the components should target, or empty when this module installed no controller and the cluster's own is used."
  value       = var.ingress_nginx ? "nginx" : ""
}

output "cluster_issuer_name" {
  description = "ClusterIssuer the provider profiles must annotate against, or empty when cert-manager is off."
  value       = var.cert_manager ? var.cluster_issuer_name : ""
}

output "ingress_namespace" {
  description = "Namespace the controller runs in. The load balancer address is on its Service — kubectl -n <ns> get svc ingress-nginx-controller."
  value       = var.ingress_nginx ? "ingress-nginx" : ""
}
