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

resource "aws_ecr_repository" "private_repo_justreadit" {
  name                 = "private-repo-justreadit"
  image_tag_mutability = "MUTABLE" # Necessary to move the "latest" tag to each newly pushed image
  force_delete         = true      # Deletes all images in the repository when it is destroyed

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Product = "justreadit"
  }
}