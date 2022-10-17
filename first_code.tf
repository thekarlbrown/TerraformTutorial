provider "aws" {
    profile = "default"
    region  = "us-east-1"
    shared_credentials_files = ["~/Projects/TerraformTutorial/credentials"]
}

resource "aws_s3_bucket" "prod_tf_course" {
    bucket = "karls-tf-tutorial-bucket"
}

resource "aws_s3_bucket_acl" "prod_tf_course" {
    bucket = "karls-tf-tutorial-bucket"
    acl = "private"
}

resource "aws_default_vpc" "default" {
    tags = {
        Name = "Default VPC"
    }
}