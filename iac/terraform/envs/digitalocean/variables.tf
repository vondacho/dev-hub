variable "environment" {
  description = "Environment this root module manages. Part of the cluster name, so two of them can share an account."
  type        = string
  default     = "prod"
}

variable "region" {
  description = "DigitalOcean region slug. The registry has to live in a region that hosts one — fra1, ams3, nyc3, sfo3, sgp1, blr1, syd1."
  type        = string
  default     = "fra1"
}

variable "cluster_name" {
  description = "Cluster name. Empty derives dev-hub-<environment>."
  type        = string
  default     = ""
}

variable "kubernetes_version_prefix" {
  description = "Minor version to track, resolved against what DOKS currently offers — \"1.34.\"."
  type        = string
  default     = "1.34."
}

variable "base_domain" {
  description = <<-EOT
    Domain the components are published under: dev-portal.<base_domain>.

    DNS is not managed here. After the first apply, point the names in
    `dns_names` at `ingress_load_balancer_ip` with A records. A DigitalOcean
    load balancer gets an IP, not a hostname — unlike the AWS environment.
  EOT
  type        = string
}

variable "registry_name" {
  description = <<-EOT
    Container registry name. A DigitalOcean account has exactly one registry,
    account-wide — this is its name, whether it was created here or already
    existed.
  EOT
  type        = string
}

variable "create_registry" {
  description = "Create the registry. Leave off when the account already has one: a second cannot be created, and destroying this one takes every image with it."
  type        = bool
  default     = false
}

variable "acme_email" {
  description = "Contact address for Let's Encrypt. Required while cert-manager is enabled."
  type        = string
}

variable "acme_staging" {
  description = "Issue from the Let's Encrypt staging CA while DNS is still moving."
  type        = bool
  default     = false
}

variable "image_tag" {
  description = "Tag the component images are delivered at. Prefer a git SHA — a re-pushed moving tag renders an identical Deployment and rolls nothing."
  type        = string
  default     = "latest"
}

variable "deploy_platform" {
  description = <<-EOT
    Install the platform (ingress controller, cert-manager).

    **First apply only:** the Kubernetes and Helm providers are configured from
    the cluster created in this same root module, so their configuration is
    unknown until it exists. Terraform allows that while no resource of those
    providers is in the plan:

      terraform apply -var deploy_platform=false -var deploy_components=false
      terraform apply

    `make up` in iac/Makefile does both.
  EOT
  type        = bool
  default     = true
}

variable "deploy_components" {
  description = "Install the dev-hub components. See deploy_platform: false on the first apply."
  type        = bool
  default     = true
}

variable "components" {
  description = "Restrict delivery to these components. Empty means every component in iac/components.yaml."
  type        = list(string)
  default     = []
}

variable "component_values" {
  description = "Raw YAML per component, applied last. The escape hatch for anything true of this environment only."
  type        = map(string)
  default     = {}
}

variable "node_size" {
  description = "Droplet size for the default pool."
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "node_min_nodes" {
  description = "Lower autoscaling bound."
  type        = number
  default     = 2
}

variable "node_max_nodes" {
  description = "Upper autoscaling bound, and the ceiling on the bill."
  type        = number
  default     = 4
}

variable "ha_control_plane" {
  description = "Replicated control plane. A paid add-on — production yes, preview no."
  type        = bool
  default     = false
}
