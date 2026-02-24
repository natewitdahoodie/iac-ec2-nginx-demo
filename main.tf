terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Grab the default VPC (keeps this project simple)
data "aws_vpc" "default" {
  default = true
}

# Grab a default subnet in us-east-1a (simple + fast)
data "aws_subnet" "default_a" {
  availability_zone = "us-east-1a"
  default_for_az    = true
}

# Security group: allow inbound HTTP only. (SSM means we don't need SSH open.)
resource "aws_security_group" "web_sg" {
  name        = "nate-web-sg"
  description = "Allow HTTP inbound"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Find a recent Ubuntu 22.04 AMI automatically
data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu_2204.id
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnet.default_a.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              set -eux
              apt-get update -y
              apt-get install -y nginx
              echo "Hello from Nate's Terraform EC2 web server 👋" > /var/www/html/index.html
              systemctl enable nginx
              systemctl restart nginx
              EOF

  tags = {
    Name = "nate-terraform-web"
  }
}

output "instance_id" {
  value = aws_instance.web.id
}

output "public_ip" {
  value = aws_instance.web.public_ip
}

output "url" {
  value = "http://${aws_instance.web.public_ip}"
}
