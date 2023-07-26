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

# resource "aws_instance" "example" {
#   ami = "ami-05bfc1ab11bfbf484"
#   instance_type = "t2.micro"
#   vpc_security_group_ids = [aws_security_group.instance.id]

#   user_data = <<-EOF
#               #!/bin/bash
#               echo "Hello World" > index.html
#               nohup busybox httpd -f -p 8080 &
#               EOF
  
#   user_data_replace_on_change = true

#   tags = {
#     Name = "terraform-ec2-example"
#   }
# }

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
  min_size = 1
  max_size = 3
  vpc_zone_identifier = data.aws_subnets.default.ids
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

# output "public-ip" {
#   value = aws_instance.example.public_ip
#   description = "Public IP of the web server"
# }


