terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.69"
    }
  }

  # backend "s3" {
  #   bucket         = "<<BUCKET_NAME>>"
  #   key            = "demo-repo/terraform.tfstate"
  #   region         = "<<REGION>>"
  #   dynamodb_table = "terraform-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project = "demo-github"
    }
  }
}
