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

resource "aws_security_group" "prod_web" {
    name = "prod_web"
    description = "Allow standard HTTP(S) ports inbound and everything outbound"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    tags = {
        "Terraform": "true"
    }
}

resource "aws_instance" "prod_web" {
    ami = "ami-0b73f70247c2526d6"
    instance_type = "t2.nano"

    vpc_security_group_ids = [
        aws_security_group.prod_web.id
    ]
    
    tags = {
        "Terraform": "true"
    }
}