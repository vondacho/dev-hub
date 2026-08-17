variable "name" {
  description = "Cluster name, and the prefix every resource this module creates is named after."
  type        = string
}

variable "kubernetes_version" {
  description = <<-EOT
    EKS control plane version. Pinned deliberately: EKS auto-upgrades a version
    that falls out of support, and finding out from a pager is worse than
    finding out from a diff.
  EOT
  type        = string
  default     = "1.34"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC. /16 leaves room for the /20 subnets below and for a second cluster later."
  type        = string
  default     = "10.20.0.0/16"
}

variable "az_count" {
  description = "Availability zones to spread over. Three is the usual answer; two is defensible when the bill matters more than a zone failure."
  type        = number
  default     = 3

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 4
    error_message = "az_count must be between 2 and 4."
  }
}

variable "single_nat_gateway" {
  description = <<-EOT
    One NAT gateway for the whole VPC instead of one per AZ. Saves real money
    and costs cross-AZ egress plus a single point of failure for outbound
    traffic — the right trade for a portal, the wrong one for a payment system.
  EOT
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Reach the API server from the internet. Needed for a laptop or a hosted CI runner to apply anything."
  type        = bool
  default     = true
}

variable "endpoint_public_access_cidrs" {
  description = "Who may reach the public API endpoint. 0.0.0.0/0 is the default only because a narrower list has to come from somewhere real — narrow it."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "Instance types for the managed node group. Several types let the capacity pool be deeper, which matters for spot."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "ON_DEMAND or SPOT. Spot is fine for a stateless portal behind a rolling update; it is not fine for the only two replicas you have."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "node_capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "node_min_size" {
  description = "Minimum nodes."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum nodes. Nothing scales the group on its own here — this is the ceiling for a manual or autoscaler-driven change."
  type        = number
  default     = 4
}

variable "node_desired_size" {
  description = "Nodes at creation. Two, so the anti-affinity in iac/profiles/common.yaml has somewhere to spread to."
  type        = number
  default     = 2
}

variable "node_disk_size" {
  description = "Root volume per node, in GiB. Images and the container runtime, not application data."
  type        = number
  default     = 40
}

variable "ecr_repositories" {
  description = <<-EOT
    Image names to create ECR repositories for — pass the `image` fields from
    iac/components.yaml, so the registry has exactly the repositories the
    delivery will push to and no others.
  EOT
  type        = list(string)
  default     = []
}

variable "ecr_keep_last_images" {
  description = "Untagged and superseded images to keep per repository before the lifecycle policy expires them."
  type        = number
  default     = 20
}

variable "ecr_scan_on_push" {
  description = "Scan images for CVEs on push. Basic scanning is free; the finding still has to be read by somebody."
  type        = bool
  default     = true
}

variable "enable_ebs_csi_driver" {
  description = <<-EOT
    Install the EBS CSI driver addon. Off: every dev-hub component is stateless
    today, and the addon is not free — it wants an IAM role of its own. Turn it
    on with the first PersistentVolumeClaim, not before.
  EOT
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to everything this module creates."
  type        = map(string)
  default     = {}
}
