variable "instance_name" {
  description = "Name of the EC2 instance"
  type = string
  default = "WebServerGroceryMate"
}

variable "instance_type" {
  description = "EC2 instance type"
  type = string
  default = "t2.micro"
}

variable "key_pair_name" {
  description = "Name of the existing AWS Key Pair"
  type = string
  default = "rpuri_key_pair"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type = string
  default = "eu-central-1"
}

variable "profile" {
  description = "AWS Profile"
  type = string
  default = "default"
}
