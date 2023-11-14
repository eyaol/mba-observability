terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  profile    = local.profile
  access_key = local.access_key
  secret_key = local.secret_key
  token      = local.token
}