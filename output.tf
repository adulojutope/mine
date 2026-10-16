output "bootstrap_public_ip" {
  value = aws_instance.bootstrap.public_ip
}

# output "app_private_ips" {
#   value = { for k, i in aws_instance.app : k => i.private_ip }
# }