terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.2"
}

provider "aws" {
  region  = "ca-central-1"
  profile = "terraform-process" # Uses aws cli profile "terraform-process", which uses short-lived credentials
}