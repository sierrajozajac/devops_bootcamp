# ==============================================================================
# EKS CLUSTER OUTPUTS (From Step 3 Module)
# ==============================================================================

output "eks_cluster_endpoint" {
  description = "The API server endpoint for your EKS cluster control plane."
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  description = "The security group ID attached to the EKS cluster control plane."
  value       = module.eks.cluster_security_group_id
}

output "eks_node_security_group_id" {
  description = "The security group ID attached to the managed EC2 worker nodes."
  value       = module.eks.node_security_group_id
}

# ==============================================================================
# CI/CD EC2 INSTANCE DETAILS (From Step 2 Manual Setup)
# ==============================================================================

# Note: Because this instance was provisioned via the AWS Console UI,
# you can hardcode its static details here for central documentation.
output "cicd_instance_public_ip" {
  description = "The public IPv4 address of the Jenkins/Nexus CI/CD server."
  value       = "35.88.32.152"
}