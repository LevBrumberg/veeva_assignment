variable "name" {
  description = "Name prefix for DB resources."
  type        = string
}

variable "tags" {
  description = "Common tags applied to resources."
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC ID where the database SG will be created."
  type        = string
}

variable "db_subnet_ids" {
  description = "Private subnet IDs for the DB subnets."
  type        = list(string)
}

variable "app_security_group_id" {
  description = "Security group ID of the application tier (allowed to connect to the DB)."
  type        = string
}

variable "engine" {
  description = "RDS engine (e.g., postgres)."
  type        = string
  default     = "postgres"
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage_gb" {
  description = "Allocated storage (GB)."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "ecommerce"
}

variable "username" {
  description = "Master username."
  type        = string
  default     = "appuser"
}

variable "password" {
  description = "Master password; in production integration with Secrets Manager."
  type        = string
  sensitive   = true
}

variable "port" {
  description = "Database port."
  type        = number
  default     = 5432
}