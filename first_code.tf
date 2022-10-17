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
    count = 2

    ami = "ami-0b73f70247c2526d6"
    instance_type = "t2.nano"

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

resource "aws_elb" "prod_web" {
    name = "prod-web"
    subnets = [ aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id ]
    security_groups = [ aws_security_group.prod_web.id ]

    listener {
      instance_port = 80
      instance_protocol = "http"
      lb_port = 80
      lb_protocol = "http"
    }

    tags = {
        "Terraform": "true"
    }
}

resource "aws_launch_template" "prod_web" {
  name_prefix   = "prod_web"
  image_id      = "ami-0b73f70247c2526d6"
  instance_type = "t2.nano"

  tags = {
     "Terraform": "true"
  }
}

resource "aws_autoscaling_group" "prod_web" {
  desired_capacity   = 2
  max_size           = 3
  min_size           = 1
  vpc_zone_identifier = [ aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id ]

  launch_template {
    id      = aws_launch_template.prod_web.id
    version = "$Latest"
  }

    tag {
        key = "Terraform"
        value = "true"
        propagate_at_launch = true
    }
}

resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_autoscaling_group.prod_web.id
  elb                    = aws_elb.prod_web.id
}