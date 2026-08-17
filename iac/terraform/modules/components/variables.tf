variable "repo_root" {
  description = <<-EOT
    Absolute path to the repository root. Charts are resolved from it as
    <repo_root>/<component.chart>, which is what makes this module reuse the
    charts under helm/ rather than carry copies.
  EOT
  type        = string
}

variable "components_file" {
  description = "Absolute path to iac/components.yaml — the registry of deliverable components."
  type        = string
}

variable "profiles_dir" {
  description = "Absolute path to iac/profiles."
  type        = string
}

variable "profile" {
  description = "Provider profile to layer on: aws, digitalocean, generic, or any file <profile>.yaml in profiles_dir."
  type        = string
}

variable "only" {
  description = <<-EOT
    Restrict delivery to these component names. Empty means every component in
    the registry — the normal case. Useful to roll one component of a hub
    forward without touching the others.
  EOT
  type        = list(string)
  default     = []
}

variable "registry" {
  description = <<-EOT
    Registry prefix images are pulled from, without a trailing slash and
    without the image name: "123456789012.dkr.ecr.eu-west-1.amazonaws.com" or
    "registry.digitalocean.com/dev-hub" or "ghcr.io/vondacho".
  EOT
  type        = string
}

variable "image_tag" {
  description = <<-EOT
    Tag every component image is delivered at.

    Prefer something immutable — a git SHA, or a semver the build never
    republishes. A moving tag re-pushed under the same name renders a
    byte-identical Deployment, so Kubernetes sees no change and leaves the old
    pods running while Terraform and Helm both report success. helm/README.md
    documents the same trap on the local path, where deploy.sh works around it
    with an explicit rollout restart.
  EOT
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_][A-Za-z0-9._-]{0,127}$", var.image_tag))
    error_message = "image_tag must be a valid OCI tag."
  }
}

variable "base_domain" {
  description = <<-EOT
    Domain the components are published under. Each component's ingress host
    becomes "<component.host>.<base_domain>", and the browser-facing links it
    renders resolve the same way.
  EOT
  type        = string
}

variable "url_scheme" {
  description = "Scheme used for the browser-facing links between components. http only makes sense without TLS."
  type        = string
  default     = "https"

  validation {
    condition     = contains(["http", "https"], var.url_scheme)
    error_message = "url_scheme must be http or https."
  }
}

variable "tls_enabled" {
  description = <<-EOT
    Add a TLS block to each ingress, with secret "<release>-tls". The
    certificate itself is issued by cert-manager from the cluster-issuer
    annotation carried by the provider profile — this only asks the ingress
    controller to terminate.
  EOT
  type        = bool
  default     = true
}

variable "ingress_class_name" {
  description = "Override the IngressClass from the profile. Empty keeps the profile's value."
  type        = string
  default     = ""
}

variable "ingress_annotations" {
  description = "Extra ingress annotations merged over the profile's, for environment-specific concerns (WAF, rate limits, an ACM certificate ARN)."
  type        = map(string)
  default     = {}
}

variable "image_pull_secrets" {
  description = "Names of imagePullSecrets in the component namespaces. Empty on EKS, where the node role reads ECR directly; the registry name on DOKS."
  type        = list(string)
  default     = []
}

variable "create_namespaces" {
  description = "Create the namespaces the components declare. Turn off where a cluster policy owns namespace creation."
  type        = bool
  default     = true
}

variable "namespace_labels" {
  description = "Labels applied to namespaces this module creates — pod-security levels, mesh injection, cost tags."
  type        = map(string)
  default     = {}
}

variable "component_values" {
  description = <<-EOT
    Raw YAML per component, applied last — after the chart defaults, the common
    profile, the provider profile and the computed overlay. The escape hatch
    for anything that is true of one environment only:

      component_values = {
        dev-portal = yamlencode({ app = { apiPortalUrl = "https://api.corp.example" } })
      }
  EOT
  type        = map(string)
  default     = {}
}

variable "atomic" {
  description = "Roll a failed release back instead of leaving it half-applied. Off in dev, where the broken pods are the diagnosis."
  type        = bool
  default     = true
}

variable "wait_timeout" {
  description = "Seconds Helm waits for a release to become ready."
  type        = number
  default     = 600
}
