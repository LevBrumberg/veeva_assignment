output "db_endpoint" {
  description = "RDS endpoint hostname."
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "Database port."
  value       = aws_db_instance.this.port
}

output "db_identifier" {
  description = "RDS instance identifier."
  value       = aws_db_instance.this.id
}
