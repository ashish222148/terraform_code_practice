terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.12.0"
    }
  }
    cloud { 
    
    organization = "ashish-222148" 

    workspaces { 
      name = "ashish-test" 
    } 
  } 
}

provider "aws" {
region = "ap-south-1"
}

resource "aws_vpc" "mahadev" {
  cidr_block = "10.0.0.0/16"
}
locals {
  bucket_name=["ailiya-2221481","ailiya-2221482","ailiya-2221483"]
}
module "s3-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.7.0"
  for_each = toset(local.bucket_name)
  bucket = each.value
  force_destroy = true
}