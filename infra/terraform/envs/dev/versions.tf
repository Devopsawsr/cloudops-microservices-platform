terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Supply the existing S3 bucket at terraform init time.
  # Backend state survives between GitHub Actions runs.
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "cloudops-microservices-platform"
      Environment = "dev"
      ManagedBy   = "Terraform"
      Purpose     = "temporary-eks-learning-lab"
    }
  }
}
