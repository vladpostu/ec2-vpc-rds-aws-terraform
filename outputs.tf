output "web_server_public_ip" {
  description = "IP of the server: "
  value       = aws_instance.web-server.public_ip
}

output "db_endpoint" {
  description = "DB RDS: "
  value       = aws_db_instance.default.endpoint
}

output "db_password" {
  description = "Random Password generated"
  value       = random_password.db_password.result
  sensitive   = true
}
