variable "kubeconfig_path" {
  description = "Kubeconfig to talk to the cluster with."
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = <<-EOT
    Context within that kubeconfig. Empty uses the current one — convenient,
    and the reason somebody once deployed to production from a laptop. Name it.
  EOT
  type        = string
  default     = ""
}

variable "profile" {
  description = <<-EOT
    Profile from iac/profiles to layer on. `generic` assumes nothing but an
    IngressClass; add a file of your own next to it for a provider that
    deserves more (GKE, AKS, Scaleway, Hetzner) and name it here.
  EOT
  type        = string
  default     = "generic"
}

variable "registry" {
  description = <<-EOT
    Registry prefix images are pulled from, without a trailing slash:
    "ghcr.io/vondacho", "registry.gitlab.com/team/dev-hub",
    "harbor.corp.example/dev-hub".
  EOT
  type        = string
}

variable "image_tag" {
  description = "Tag the component images are delivered at."
  type        = string
  default     = "latest"
}

variable "base_domain" {
  description = "Domain the components are published under: dev-portal.<base_domain>."
  type        = string
}

variable "url_scheme" {
  description = "Scheme for the links between components. http on a cluster with no TLS in front."
  type        = string
  default     = "https"
}

variable "tls_enabled" {
  description = "Ask the ingress to terminate TLS, with a secret named <release>-tls. Needs an issuer in the cluster, or the secret created by hand."
  type        = bool
  default     = true
}

variable "ingress_class_name" {
  description = <<-EOT
    IngressClass to target. Empty falls back to the profile's, which for
    `generic` is empty too — meaning the cluster's default class. Name it
    explicitly on a cluster with several, or with none marked default:
    "traefik" on k3s and Rancher Desktop, "nginx" where the platform module
    installed one.
  EOT
  type        = string
  default     = ""
}

variable "image_pull_secrets" {
  description = "Pull secret names, which must already exist in the component namespaces. Empty for a public registry or a node-level credential."
  type        = list(string)
  default     = []
}

variable "deploy_platform" {
  description = <<-EOT
    Install ingress-nginx and cert-manager here too.

    Off by default, unlike the cloud environments: a cluster somebody else
    provisioned usually has both already, and installing a second ingress
    controller is a good way to find out which one owns the LoadBalancer.
  EOT
  type        = bool
  default     = false
}

variable "acme_email" {
  description = "Contact address for Let's Encrypt. Required only when deploy_platform is on."
  type        = string
  default     = ""
}

variable "acme_staging" {
  description = "Issue from the Let's Encrypt staging CA."
  type        = bool
  default     = false
}

variable "components" {
  description = "Restrict delivery to these components. Empty means every component in iac/components.yaml."
  type        = list(string)
  default     = []
}

variable "component_values" {
  description = "Raw YAML per component, applied last."
  type        = map(string)
  default     = {}
}

variable "create_namespaces" {
  description = "Create the namespaces the components declare. Turn off where a cluster policy owns namespace creation — a shared cluster usually does."
  type        = bool
  default     = true
}
