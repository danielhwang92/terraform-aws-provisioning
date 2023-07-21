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

resource "aws_instance" "example" {
  ami = "ami-05bfc1ab11bfbf484"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
  
  user_data_replace_on_change = true

  tags = {
    Name = "terraform-ec2-example"
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-security-group-example"
  
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
}


