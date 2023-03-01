terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.8.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  region = var.sns_topic_region
  alias  = "snsregion"
}
