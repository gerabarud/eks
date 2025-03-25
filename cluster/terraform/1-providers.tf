provider "aws" {
  region = local.region
}

terraform {
  # https://registry.terraform.io/providers/hashicorp/aws/latest
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.92.0"
    }
  }
  # https://github.com/hashicorp/terraform
  required_version = ">=  1.0"
}

