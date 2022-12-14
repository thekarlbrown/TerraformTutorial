variable whitelist {
    type = list(string)
}
variable image_id {
    type = string
}
variable instance_type {
    type = string
}
variable desired_capacity {
    type = number
}
variable max_size {
    type = number
}
variable min_size {
    type = number
}

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

resource "aws_default_subnet" "default_az1" {
    availability_zone = "us-east-1a"
    tags = {
        "Terraform": "true"
    }
 }

resource "aws_default_subnet" "default_az2" {
    availability_zone = "us-east-1b"
    tags = {
        "Terraform": "true"
    }
 }

resource "aws_security_group" "prod_web" {
    name = "prod_web"
    description = "Allow standard HTTP(S) ports inbound and everything outbound"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = var.whitelist
    }

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = var.whitelist
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = var.whitelist
    }

    tags = {
        "Terraform": "true"
    }
}

resource "aws_instance" "prod_web" {
    count = 1

    ami = var.image_id
    instance_type = var.instance_type

    vpc_security_group_ids = [
        aws_security_group.prod_web.id
    ]
    
    tags = {
        "Terraform": "true"
    }
}

resource "aws_eip_association" "prod_web" {
    instance_id = aws_instance.prod_web.0.id
    allocation_id = aws_eip.prod_web.id
}

resource "aws_eip" "prod_web" {
    instance = aws_instance.prod_web.0.id

    tags = {
        "Terraform": "true"
    }
}

module "web_app" {
  source = "./modules/webapp"
  image_id = var.image_id
  instance_type = var.instance_type
  desired_capacity = var.desired_capacity
  max_size = var.max_size
  min_size = var.min_size
  subnets = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  security_groups = [aws_security_group.prod_web.id]
  web_app = "prod"
}