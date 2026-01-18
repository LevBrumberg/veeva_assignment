# Internet-facing ALB in public subnets
# Target Group + Listener (HTTP)
# Launch Template from a baked AMI
# Auto Scaling Group in private subnets

# Security Groups

# ALB SG: accept HTTP from internet, forward to app instances on app_port.
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "ALB SG: inbound HTTP from internet, egress to app instances"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description     = "Forward to app instances"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  tags = merge(var.tags, { Name = "${var.name}-alb-sg" })
}

# App SG: only accept traffic from ALB on app_port.
# Outbound HTTPS allowed for AWS APIs.
resource "aws_security_group" "app" {
  name        = "${var.name}-app-sg"
  description = "App SG: inbound from ALB only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "App traffic from ALB only"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Outbound HTTPS (AWS APIs, logging, etc.)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-app-sg" })
}

# Application Load Balancer

resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  internal           = false

  security_groups = [aws_security_group.alb.id]
  subnets         = var.public_subnet_ids

  tags = merge(var.tags, { Name = "${var.name}-alb" })
}

# Target Group
resource "aws_lb_target_group" "api" {
  name     = "${var.name}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled  = true
    path     = var.health_check_path
    matcher  = "200-399"
    interval = 30
    timeout  = 5
  }

  tags = merge(var.tags, { Name = "${var.name}-tg" })
}

# Listener: receive HTTP on 80 and forward to the target group.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

# IAM Role for EC2 instances (App level)

resource "aws_iam_role" "app" {
  name = "${var.name}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

# Minimal permissions:
# read DB password secret
# write logs to CloudWatch Logs
resource "aws_iam_role_policy" "app_policy" {
  name = "${var.name}-app-policy"
  role = aws_iam_role.app.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "ReadDbPasswordSecret",
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = var.db_password_secret_arn
      },
      {
        Sid    = "WriteCloudWatchLogs",
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.name}-app-instance-profile"
  role = aws_iam_role.app.name
}


# Launch Template + ASG

# Launch Template: uses baked AMI; attaches App SG.
resource "aws_launch_template" "this" {
  name_prefix   = "${var.name}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  iam_instance_profile {
    name = aws_iam_instance_profile.app.name
  }

  vpc_security_group_ids = [aws_security_group.app.id]

  tags = merge(var.tags, { Name = "${var.name}-lt" })
}

# ASG: spreads instances across private subnets; attaches to target group.
resource "aws_autoscaling_group" "this" {
  name                = "${var.name}-asg"
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size
  vpc_zone_identifier = var.private_subnet_ids

  target_group_arns         = [aws_lb_target_group.api.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 120

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.name}-app"
    propagate_at_launch = true
  }
}
