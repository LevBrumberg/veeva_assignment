variable "name" {
  type        = string
  description = "Name prefix for resources"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDRs (one per AZ)"
}

variable "private_app_subnet_cidrs" {
  type        = list(string)
  description = "Private subnet CIDRs (one per AZ)"
}

variable "private_db_subnet_cidrs" {
  type        = list(string)
  description = "Private subnet CIDRs (one per AZ)"
}