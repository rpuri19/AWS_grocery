# output.tf
output "instance_public_ip" {
  description = "Public ip for web server"
  value = aws_instance.web_server_grocery_mate.public_ip
}