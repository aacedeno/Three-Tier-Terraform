terraform {
  backend "s3" {
    bucket = "tf-state-mia"
    key    = "prod/terraform.tfstate"
    region = "us-west-2"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}
