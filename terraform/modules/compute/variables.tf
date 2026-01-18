variable "name" {
  description = "Name prefix for compute resources."
  type        = string
}

variable "tags" {
  description = "Common tags applied to resources."
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC ID where ALB and instances will be deployed."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets for the internet-facing ALB."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnets for application EC2 instances (ASG)."
  type        = list(string)
}

variable "ami_id" {
  description = "AMI ID for application instances."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for application servers."
  type        = string
  default     = "t3.micro"
}

variable "app_port" {
  description = "Port the application listens on."
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "HTTP path used by ALB health checks."
  type        = string
  default     = "/health"
}

variable "desired_capacity" {
  description = "Desired number of instances in the ASG."
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum ASG size."
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum ASG size."
  type        = number
  default     = 4
}

variable "db_password_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the DB master password."
  type        = string
}
