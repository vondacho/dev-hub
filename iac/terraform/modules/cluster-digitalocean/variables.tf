variable "name" {
  description = "Cluster name, and the prefix every resource this module creates is named after."
  type        = string
}

variable "region" {
  description = "DigitalOcean region slug — fra1, ams3, nyc3, sfo3. The registry can only live in a region that hosts one."
  type        = string
  default     = "fra1"
}

variable "kubernetes_version_prefix" {
  description = <<-EOT
    Version prefix resolved against what DOKS currently offers, e.g. "1.34.".
    A prefix rather than an exact version because DigitalOcean retires patch
    releases quickly — an exact pin here breaks the plan a few weeks later,
    while the prefix keeps the minor version under control.
  EOT
  type        = string
  default     = "1.34."
}

variable "auto_upgrade" {
  description = "Let DOKS apply patch upgrades in the maintenance window. On: the alternative is a cluster that quietly falls out of support."
  type        = bool
  default     = true
}

variable "surge_upgrade" {
  description = "Add a node before draining one during an upgrade, instead of draining first. Costs one node-hour, saves the capacity dip."
  type        = bool
  default     = true
}

variable "ha_control_plane" {
  description = "Replicated control plane. It is a paid add-on — worth it for production, not for a preview environment."
  type        = bool
  default     = false
}

variable "maintenance_day" {
  description = "Day the maintenance window opens: monday..sunday, or `any`."
  type        = string
  default     = "sunday"
}

variable "maintenance_start_time" {
  description = "Start of the 4-hour maintenance window, UTC, on the hour."
  type        = string
  default     = "03:00"
}

variable "node_size" {
  description = <<-EOT
    Droplet size for the default pool. s-2vcpu-4gb is the smallest that leaves
    room for the ingress controller, cert-manager and two portal replicas after
    the DOKS system daemonsets have taken their share.
  EOT
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "node_count" {
  description = "Nodes when autoscaling is off, and the starting count when it is on."
  type        = number
  default     = 2
}

variable "node_auto_scale" {
  description = "Let the pool grow and shrink between the bounds below."
  type        = bool
  default     = true
}

variable "node_min_nodes" {
  description = "Lower autoscaling bound. Two, so the anti-affinity in iac/profiles/common.yaml has somewhere to spread to."
  type        = number
  default     = 2
}

variable "node_max_nodes" {
  description = "Upper autoscaling bound, and the ceiling on the bill."
  type        = number
  default     = 4
}

variable "vpc_cidr" {
  description = "CIDR for the VPC the cluster runs in. Empty lets DigitalOcean pick a free range."
  type        = string
  default     = ""
}

variable "create_registry" {
  description = <<-EOT
    Create the container registry.

    A DigitalOcean account has **one** registry, account-wide, not one per
    cluster or per project. Leave this off and set `registry_name` when the
    account already has one — creating a second is not a thing that can
    succeed, and destroying this one takes every other project's images with it.
  EOT
  type        = bool
  default     = false
}

variable "registry_name" {
  description = "Registry name. Globally unique across DigitalOcean when created here; the existing registry's name otherwise."
  type        = string
}

variable "registry_tier" {
  description = "starter (1 repository, 500 MB), basic (5 GB) or professional (100 GB). starter cannot hold a second component."
  type        = string
  default     = "basic"

  validation {
    condition     = contains(["starter", "basic", "professional"], var.registry_tier)
    error_message = "registry_tier must be starter, basic or professional."
  }
}

variable "registry_integration" {
  description = <<-EOT
    Let DOKS maintain a pull secret for the registry in every namespace. On:
    without it every namespace needs a secret created and rotated by hand, and
    the failure mode is an ImagePullBackOff hours after the token expired.
  EOT
  type        = bool
  default     = true
}

variable "tags" {
  description = "DigitalOcean tags applied to the cluster and its pool. Lowercase, no spaces — the API rejects anything else."
  type        = list(string)
  default     = ["dev-hub"]
}
