# DB subnets
# DB security group allowing inbound only from app SG
# RDS instance with Multi-AZ enabled

# Security Group (DB)

resource "aws_security_group" "db" {
  name        = "${var.name}-db-sg"
  description = "DB SG: allow DB port from app tier only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "DB access from application tier"
    from_port       = var.port
    to_port         = var.port
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
  }

  tags = merge(var.tags, { Name = "${var.name}-db-sg" })
}

# DB Subnet Group

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnets"
  subnet_ids = var.db_subnet_ids

  description = "DB subnet group for ${var.name}"
  tags        = merge(var.tags, { Name = "${var.name}-db-subnets" })
}

# RDS Instance

resource "aws_db_instance" "this" {
  identifier = "${var.name}-db"

  engine         = var.engine
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage_gb

  db_name  = var.db_name
  username = var.username
  password = var.password
  port     = var.port

  multi_az               = true
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.db.id]
  db_subnet_group_name   = aws_db_subnet_group.this.name

  tags = merge(var.tags, { Name = "${var.name}-db" })
}
