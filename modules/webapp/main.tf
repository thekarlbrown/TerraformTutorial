resource "aws_elb" "this" {
    name = "${var.web_app}-web"
    subnets = var.subnets
    security_groups = var.security_groups

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

resource "aws_route53_zone" "this" {
  name = "elizabethslover.com"
}

resource "aws_route53_record" "this" {
   zone_id = aws_route53_zone.this.zone_id
   name    = "elizabethslover.com"
   type    = "A"
   alias {
     name                   = aws_elb.this.dns_name
     zone_id                = aws_elb.this.zone_id
     evaluate_target_health = true
   }

   lifecycle { create_before_destroy = true }
 }

resource "aws_launch_template" "this" {
  name_prefix   = "${var.web_app}-web"
  image_id      = var.image_id
  instance_type = var.instance_type

  tags = {
     "Terraform": "true"
  }
}

resource "aws_autoscaling_group" "this" {
  desired_capacity   = var.desired_capacity
  max_size           = var.max_size
  min_size           = var.min_size
  vpc_zone_identifier = var.subnets
  load_balancers = [ aws_elb.this.id ]

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  tag {
    key = "Terraform"
    value = "true"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_attachment" "this" {
  autoscaling_group_name = aws_autoscaling_group.this.id
  elb                    = aws_elb.this.id
}