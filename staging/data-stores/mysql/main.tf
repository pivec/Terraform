provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "example" {
  engine                = "mysql"
  allocated_storage     = 10
  instance_class        = "db.t2.micro"
  name                  = "example_database"
  username              = "admin"
  password              = "${var.db_password}"
}

terraform {
  backend "s3" {
    bucket = "hquinn-tf-s3-bucket"
    key    = "staging/data-stores/mysql/terraform.tfstate"
    region = "us-east-1"
    encrypt = "true"
  }
}