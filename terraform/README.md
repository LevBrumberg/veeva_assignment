# Terraform Infrastructure Overview

This directory contains Terraform code used to provision the core cloud infrastructure for the e-commerce application described in the main architecture design.

The infrastructure is structured using Terraform modules.

## State Management

Terraform state is stored remotely in an S3 backend.

The backend configuration is defined in envs/dev/main.tf and assumes that the S3 bucket already exists. State encryption is enabled. State locking is intentionally omitted for simplicity.

State should be treated as sensitive, as it may contain resource identifiers and database credentials.


## Modules

### Network Module

The network module is responsible for provisioning networking resources:

- VPC
- Internet Gateway
- Public subnets
- Private application subnets
- Private database subnets
- Route tables and associations

The design separates traffic by tier to enforce clear security boundaries:
- Public subnets are used for load balancers only
- Application runs in private subnets
- Databases run in isolated private subnets with no internet access

The module outputs VPC and subnet vars for downstream modules.

### Compute Module

The compute module provisions the application ingress and compute layer:

- Application Load Balancer
- Target group and listener
- Auto Scaling Group
- Launch template
- Security groups for ALB and application instances

Application instances are stateless and based on a pre-baked AMI. The Auto Scaling Group is deployed in multiple subnets across availability zones.

TLS re-encryption between the ALB and instances is documented in the architecture design but not implemented in code.

The module outputs the ALB DNS name and application security group id for DB module.

### Database Module

The database module provisions a relational database layer:

- RDS instance (Multi-AZ)
- DB subnet group
- Database security group

The database runs in private database subnets and is only accessible from the application security group. Database credentials are not hardcoded and are retrieved from AWS Secrets Manager at apply time.

## Secrets Management

The database master password is retrieved from AWS Secrets Manager using Terraform data sources.

The secret is expected to exist prior to running Terraform and is referenced by name. This avoids hardcoding credentials.

### IAM and Instance Access Control

Application instances run with an IAM role attached via an EC2 instance profile.

Permissions are granted according to the principle of least privilege. The application role is allowed to:
- Read the database master password from AWS Secrets Manager
- Publish logs to CloudWatch Logs.

These specific permissions are used as a placeholder to show the design principal.
Network access is controlled separately using security groups, while IAM is used exclusively for authorization to AWS APIs.

## Environment

The envs/dev directory contains the environment-specific configuration.

It defines:
- Provider configuration (region and credentials)
- Remote backend configuration
- Environment-specific variables and CIDR ranges

Only a single environment is defined for this assignment. Additional environments (prod, dr) would reuse the same modules with different inputs and state keys.

## Scope and Intentional Omissions

This Terraform code is designed to demonstrate infrastructure structure, dependency flow, and security boundaries.

The following are intentionally omitted or simplified:
- AMI build pipelines
- CI/CD integration
- State locking
- WAF configuration
- Advanced database configuration
- NAT Gateway provisioning

These can be added without changing the module structure.
