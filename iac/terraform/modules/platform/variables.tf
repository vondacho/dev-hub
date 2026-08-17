variable "ingress_nginx" {
  description = <<-EOT
    The ingress controller every environment terminates on. Turn it off for a
    cluster that already has one — a shared platform cluster, or k3s/Rancher
    Desktop with Traefik — and point the components at that class instead
    (`ingress_class_name` on the components module).
  EOT
  type        = bool
  default     = true
}

variable "ingress_nginx_version" {
  description = "ingress-nginx chart version. Pinned: an ingress controller that upgrades itself under you is an outage waiting for a Tuesday."
  type        = string
  default     = "4.15.1"
}

variable "ingress_nginx_replicas" {
  description = "Controller replicas. Two so a node drain does not drop every connection at once."
  type        = number
  default     = 2
}

variable "ingress_service_annotations" {
  description = <<-EOT
    Annotations on the controller's LoadBalancer Service. This is where the
    cloud provider actually shows through, and the reason the profiles under
    iac/profiles/ can stay nearly identical:

      AWS   service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
      DO    service.beta.kubernetes.io/do-loadbalancer-name: "dev-hub"
  EOT
  type        = map(string)
  default     = {}
}

variable "ingress_service_type" {
  description = "LoadBalancer everywhere a cloud can provision one; NodePort on a bare cluster that cannot."
  type        = string
  default     = "LoadBalancer"

  validation {
    condition     = contains(["LoadBalancer", "NodePort", "ClusterIP"], var.ingress_service_type)
    error_message = "ingress_service_type must be LoadBalancer, NodePort or ClusterIP."
  }
}

variable "ingress_external_traffic_policy" {
  description = <<-EOT
    Local preserves the client source IP, at the cost of only routing to nodes
    that run a controller pod. Cluster hides the client IP behind SNAT but
    survives an uneven spread. Local is right when the controller is a
    DaemonSet or has a replica per node; check before changing it.
  EOT
  type        = string
  default     = "Local"
}

variable "ingress_nginx_extra_values" {
  description = "Raw YAML merged last into the ingress-nginx release, for anything this module does not model."
  type        = string
  default     = ""
}

variable "cert_manager" {
  description = "Install cert-manager. Required for the TLS the provider profiles ask for through the cert-manager.io/cluster-issuer annotation."
  type        = bool
  default     = true
}

variable "cert_manager_version" {
  description = "cert-manager chart version."
  type        = string
  default     = "v1.21.1"
}

variable "cluster_issuer_name" {
  description = "Name of the ClusterIssuer created here. Must match the cert-manager.io/cluster-issuer annotation in iac/profiles/*.yaml."
  type        = string
  default     = "letsencrypt"
}

variable "acme_email" {
  description = <<-EOT
    Contact address Let's Encrypt sends expiry warnings to. Required when
    cert_manager is on: ACME registration fails without it, and the warnings
    are the only thing standing between a renewal loop that quietly broke and a
    site that stops answering on a Sunday.
  EOT
  type        = string
  default     = ""
}

variable "acme_staging" {
  description = <<-EOT
    Issue from the Let's Encrypt staging CA. The certificates are untrusted by
    browsers, but the rate limits are not the production ones — use this while
    the DNS and the ingress are still moving, then flip it once.
  EOT
  type        = bool
  default     = false
}

variable "metrics_server" {
  description = <<-EOT
    Install metrics-server. EKS ships without it, so `kubectl top` and any HPA
    are dead on arrival there; DOKS and most managed clusters already have one,
    and a second install will fight the first.
  EOT
  type        = bool
  default     = false
}

variable "metrics_server_version" {
  description = "metrics-server chart version."
  type        = string
  default     = "3.13.1"
}

variable "wait_timeout" {
  description = "Seconds Helm waits for each platform release. Longer than the app default: these wait on a cloud load balancer being provisioned."
  type        = number
  default     = 900
}
