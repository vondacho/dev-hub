output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "API server endpoint."
  value       = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "Base64 CA bundle for the API server."
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_version" {
  description = "Kubernetes version actually running, which is not always the one requested after an EKS auto-upgrade."
  value       = module.eks.cluster_version
}

output "oidc_provider_arn" {
  description = "IRSA provider ARN, for the day a component needs an AWS API of its own."
  value       = module.eks.oidc_provider_arn
}

output "node_security_group_id" {
  description = "Security group attached to the nodes — the place to open a path to an RDS or an ElastiCache later."
  value       = module.eks.node_security_group_id
}

output "vpc_id" {
  description = "VPC the cluster runs in."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnets: nodes, control plane ENIs, internal load balancers."
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "Public subnets: internet-facing load balancers and the NAT gateway."
  value       = module.vpc.public_subnets
}

output "registry" {
  description = "Registry prefix to hand the components module — images resolve as <registry>/<image>:<tag>."
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.region}.amazonaws.com"
}

output "repository_urls" {
  description = "ECR repository URLs, keyed by image name."
  value       = { for name, repo in aws_ecr_repository.component : name => repo.repository_url }
}

output "kubeconfig_command" {
  description = "Write this cluster into the local kubeconfig."
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${data.aws_region.current.region}"
}

output "registry_login_command" {
  description = "Authenticate a local container engine against ECR. The token is valid for 12 hours."
  value       = "aws ecr get-login-password --region ${data.aws_region.current.region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.region}.amazonaws.com"
}

output "ingress_service_annotations" {
  description = <<-EOT
    Annotations to put on the ingress controller's Service on this provider.
    An NLB rather than the legacy Classic ELB: it is cheaper, it does not
    terminate TLS on our behalf, and it hands the ingress controller the
    connection it expects.
  EOT
  value = {
    "service.beta.kubernetes.io/aws-load-balancer-type"            = "external"
    "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "instance"
    "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
  }
}
