provider "aws" {
  region  = "us-west-2"
  profile = "bootcamp" 
}

# Reference your existing VPC infrastructure
data "aws_vpc" "eks_vpc" {
  id = "vpc-0696ec02df4087d60"
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.eks_vpc.id]
  }
  filter {
    name   = "tag:kubernetes.io/role/internal-elb"
    values = ["1"]
  }
}

# Official AWS EKS Module Configuration
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "dev-eks-cluster"
  cluster_version = "1.30"

  enable_cluster_creator_admin_permissions = true
  
  # Allows cluster access via your local workstation/CI-CD terminal
  cluster_endpoint_public_access = true

  vpc_id     = data.aws_vpc.eks_vpc.id
  subnet_ids = data.aws_subnets.private.ids

  # EKS Managed Node Groups Configuration
  eks_managed_node_groups = {
    app_and_monitoring = {
      min_size     = 2
      max_size     = 4
      desired_size = 2

      instance_types = ["t3.large"]
      capacity_type  = "SPOT" 

      labels = {
        Environment = "dev"
        Workload    = "apps-and-monitoring"
      }

      update_config = {
        max_unavailable_percentage = 33
      }
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}