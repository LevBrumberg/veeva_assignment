region = "us-east-1"
name   = "ecommerce-dev"

vpc_cidr = "10.0.0.0/16"

azs = ["us-east-1a", "us-east-1b"]

public_subnet_cidrs = [
  "10.0.0.0/24",
  "10.0.1.0/24"
]

private_app_subnet_cidrs = [
  "10.0.10.0/24",
  "10.0.11.0/24"
]

private_db_subnet_cidrs = [
  "10.0.20.0/24",
  "10.0.21.0/24"
]
ami_id = "ami-0abcdef1234567890"