terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # The bucket name is account-specific, so it is passed at init time:
  #   terraform init -backend-config="bucket=<state bucket>"
  backend "s3" {
    key          = "persistent/terraform.tfstate"
    region       = "eu-west-3"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      project = "forge"
      stack   = "persistent"
    }
  }
}
