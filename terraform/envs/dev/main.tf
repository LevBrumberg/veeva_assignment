terraform {
  backend "s3" {
    bucket = "my-terraform-states"
    key    = "ecommerce/dev/terraform.tfstate"
    region = "us-east-1"

    encrypt = true
  }
}
provider "aws" {
  region = var.region
}
data "aws_secretsmanager_secret" "db_master_password" {
  name = "db_master_password"
}

data "aws_secretsmanager_secret_version" "db_master_password" {
  secret_id = data.aws_secretsmanager_secret.db_master_password.id
}

module "network" {
  source = "../../modules/network"

  name   = var.name
  vpc_cidr = var.vpc_cidr
  azs      = var.azs

  public_subnet_cidrs = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs = var.private_db_subnet_cidrs
}

module "compute" {
  source = "../../modules/compute"

  name = var.name

  vpc_id = module.network.vpc_id
  app_port = 8080
  ami_id   = var.ami_id
  private_subnet_ids = module.network.private_app_subnet_ids
  public_subnet_ids = module.network.public_subnet_ids
  db_password_secret_arn = data.aws_secretsmanager_secret.db_master_password.arn
}

module "database" {
  source = "../../modules/database"

  name = var.name

  vpc_id             = module.network.vpc_id
  db_subnet_ids      = module.network.private_db_subnet_ids
  app_security_group_id = module.compute.app_security_group_id
  password = data.aws_secretsmanager_secret_version.db_master_password.secret_string # reads secret str from secrets manager
}
