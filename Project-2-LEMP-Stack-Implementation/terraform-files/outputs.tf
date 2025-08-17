output "instance_public_ip" {
  description = "Public IP of your server"
  value       = aws_instance.web_server.public_ip
}

output "ssh_command" {
  description = "Command to SSH into your server"
  value       = "ssh -i nsikak-key.pem ubuntu@${aws_instance.web_server.public_ip}"
}
