provider "aws" {
  region = "us-east-1"
}

# S3 bucket for storing state data
resource "aws_s3_bucket" "terraform_state" {
  bucket = "hquinn-tf-s3-bucket"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

terraform {
  backend "s3" {
    bucket = "hquinn-tf-s3-bucket"
    key    = "global/s3/terraform.tfstate"
    region = "us-east-1"
    encrypt = "true"
  }
}