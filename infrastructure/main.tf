provider "aws" {
  region  = var.aws_region
  profile = var.profile
}

resource "aws_security_group" "web_sg_grocery_mate" {
  name        = "web_sg_grocery_mate"
  description = "Allow HTTP, SSH, and Flask traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access from anywhere"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access from anywhere"
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "web_server_grocery_mate" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  key_name                    = var.key_pair_name
  security_groups             = [aws_security_group.web_sg_grocery_mate.name]
  associate_public_ip_address = true

  tags = {
    Name = var.instance_name
  }

}
