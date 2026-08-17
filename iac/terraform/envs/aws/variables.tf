variable "environment" {
  description = "Environment this root module manages. Part of the cluster name, so two of them can share an account without colliding."
  type        = string
  default     = "prod"
}

variable "region" {
  description = "AWS region."
  type        = string
  default     = "eu-central-1"
}

variable "cluster_name" {
  description = "Cluster name. Empty derives dev-hub-<environment>."
  type        = string
  default     = ""
}

variable "kubernetes_version" {
  description = "EKS control plane version."
  type        = string
  default     = "1.34"
}

variable "base_domain" {
  description = <<-EOT
    Domain the components are published under: dev-portal.<base_domain>.

    DNS is not managed here — this root module creates no zone and no record.
    After the first apply, point the names in the `dns_names` output at the
    ingress load balancer from `ingress_load_balancer_hostname`, as a CNAME or
    an ALIAS. Certificates cannot be issued until that resolves.
  EOT
  type        = string
}

variable "acme_email" {
  description = "Contact address for Let's Encrypt. Required while cert-manager is enabled."
  type        = string
}

variable "acme_staging" {
  description = "Issue from the Let's Encrypt staging CA while DNS is still moving. Untrusted certificates, workable rate limits."
  type        = bool
  default     = false
}

variable "image_tag" {
  description = <<-EOT
    Tag the component images are delivered at. A git SHA in CI; something
    immutable in any case — a re-pushed moving tag renders an identical
    Deployment and quietly leaves the old pods running.
  EOT
  type        = string
  default     = "latest"
}

variable "deploy_platform" {
  description = <<-EOT
    Install the platform (ingress controller, cert-manager) into the cluster.

    **This is the first apply's switch.** The Kubernetes and Helm providers are
    configured from the cluster created in this same root module, so on the
    very first run their configuration is not known until the cluster exists.
    Terraform accepts that only while no resource of those providers is in the
    plan. So:

      terraform apply -var deploy_platform=false -var deploy_components=false
      terraform apply

    The Makefile at iac/Makefile does both as `make up`. Every later apply is a
    single one — the cluster is in state by then.
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

variable "node_instance_types" {
  description = "Instance types for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Nodes at creation."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Ceiling on the node group."
  type        = number
  default     = 4
}

variable "single_nat_gateway" {
  description = "One NAT gateway instead of one per AZ. Cheaper, and a single point of failure for outbound traffic."
  type        = bool
  default     = true
}

variable "endpoint_public_access_cidrs" {
  description = "Who may reach the public API server endpoint. Narrow this to the office and the CI egress."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
