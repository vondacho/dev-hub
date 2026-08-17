# AWS landing zone for dev-hub: a VPC, an EKS cluster, and one ECR repository
# per component image.
#
# The module stops at the cluster boundary on purpose — nothing in here knows
# what a dev-portal is. What gets installed *into* the cluster is the platform
# and components modules' business, so that delivering to DigitalOcean or to a
# cluster nobody here provisioned reuses everything except this file.

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  tags = merge(
    {
      "app.kubernetes.io/part-of" = "dev-hub"
      ManagedBy                   = "terraform"
    },
    var.tags,
  )
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = var.name
  cidr = var.vpc_cidr
  azs  = local.azs

  # /20 each: 4091 usable addresses per subnet. The VPC CNI hands every pod a
  # real VPC address, so subnet sizing is pod capacity, not node count.
  private_subnets = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 4, i)]
  public_subnets  = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 4, i + 8)]

  enable_nat_gateway     = true
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = !var.single_nat_gateway

  # The VPC CNI resolves cluster DNS through the VPC resolver; both are needed
  # or the nodes join and nothing in them can resolve anything.
  enable_dns_hostnames = true
  enable_dns_support   = true

  # How a LoadBalancer Service finds its subnets. Without these tags the
  # ingress controller's Service stays <pending> forever with no useful event.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = local.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.name
  kubernetes_version = var.kubernetes_version

  vpc_id = module.vpc.vpc_id
  # Nodes and the control plane ENIs both live in the private subnets. Public
  # subnets carry the load balancers only.
  subnet_ids = module.vpc.private_subnets

  endpoint_public_access       = var.endpoint_public_access
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs
  endpoint_private_access      = true

  # The identity that runs `terraform apply` gets cluster-admin. Without it the
  # apply creates a cluster it cannot then talk to, and the helm releases in the
  # same run fail on a 401 that reads like a network problem.
  enable_cluster_creator_admin_permissions = true

  addons = merge(
    {
      coredns    = {}
      kube-proxy = {}
      # before_compute: the CNI has to be in place before a node tries to join,
      # or the first node group comes up with pods stuck at ContainerCreating.
      vpc-cni                = { before_compute = true }
      eks-pod-identity-agent = { before_compute = true }
    },
    var.enable_ebs_csi_driver ? { aws-ebs-csi-driver = {} } : {},
  )

  eks_managed_node_groups = {
    default = {
      instance_types = var.node_instance_types
      capacity_type  = var.node_capacity_type
      ami_type       = "AL2023_x86_64_STANDARD"

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      disk_size = var.node_disk_size

      # Pulling from the ECR repositories below needs no imagePullSecret —
      # this is the policy that makes iac/profiles/aws.yaml able to leave
      # imagePullSecrets empty.
      iam_role_additional_policies = {
        ecr_read = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        # Node logs and metrics without an agent of their own.
        ssm = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      labels = {
        "dev-hub.io/pool" = "default"
      }
    }
  }

  tags = local.tags
}

# One repository per component image, driven by the same list the delivery
# pushes to. A repository that exists without a component pointing at it is a
# bill nobody reads.
resource "aws_ecr_repository" "component" {
  for_each = toset(var.ecr_repositories)

  name                 = each.value
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = var.ecr_scan_on_push
  }

  tags = local.tags
}

resource "aws_ecr_lifecycle_policy" "component" {
  for_each = aws_ecr_repository.component

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images — build leftovers, never deployed"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep the last ${var.ecr_keep_last_images} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.ecr_keep_last_images
        }
        action = { type = "expire" }
      },
    ]
  })
}
