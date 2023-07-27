terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-east-1"
}

resource "aws_launch_configuration" "config" {
  image_id = "ami-05bfc1ab11bfbf484"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "bar" {
  name = "terraform-autoscaling_group"
  launch_configuration = aws_launch_configuration.config.name
  min_size = 2
  max_size = 3
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  tag {
    key = "Name"
    value = "terraform-asg-example" 
    propagate_at_launch = true
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-security-group-example"
  
  ingress {
    from_port = var.server-port
    to_port = var.server-port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "terraform-inbound-rule"
  }
}

variable "server-port" {
  description = "HTTP request port"
  type = number
  default = 8080
}

resource "aws_lb" "lb-example" {
  name = "terraform-lb-example"
  load_balancer_type = "application"
  subnets = data.aws_subnets.default.ids
  security_groups = [aws_security_group.alb-sg.id]
}

resource "aws_lb_listener" "http-listener" {
  load_balancer_arn = aws_lb.lb-example.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: Page not found"
      status_code  = "404"
    }
  }
}

resource "aws_security_group" "alb-sg" {
  name = "terraform-alb-sg"
  
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "asg" {
  name = "terraform-target-group"
  port = var.server-port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http-listener.arn
  priority = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }
  
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

output "alb-dns" {
  value = aws_lb.lb-example.dns_name
  description = "Domain name of load balancer"
}


