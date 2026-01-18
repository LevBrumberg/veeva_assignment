# Cloud-Native E-Commerce Platform - AWS Architecture

## Overview
This repository contains an architecture and infrastructure design for a cloud-native e-commerce platform on AWS.
The focus is on availability, scalability, security and disaster recovery, rather than on application features.
Application components (frontend, API, background processing) are treated as logical placeholders to demonstrate infrastructure and design decisions.

## Architecture Overview
The full architecture diagrams (including Production, Disaster Recovery, and Monitoring/Logging flows) are provided as separate PDF.

### High-level request flow
1.	Users resolve DNS via Amazon Route 53 and connect to Amazon CloudFront, protected by AWS WAF and AWS Shield Standard.
2.	CloudFront serves static frontend assets (HTML/JS/CSS) from a private Amazon S3 bucket using Origin Access Control (OAC).
3.	API requests (e.g. /api/*) are forwarded by CloudFront to a public Application Load Balancer (ALB).
4.	The ALB routes traffic to a stateless REST API running on EC2 instances managed by an Auto Scaling Group, deployed across two Availability Zones.
5.	The API stores transactional data in Amazon RDS (Multi-AZ).
6.	Asynchronous tasks (e.g. notifications, analytics) are separated using Amazon SQS, processed by a background worker.

## Components and Service Selection
### Traffic entry
- Route 53 - DNS and traffic entry point.
- CloudFront - CDN for static content, TLS termination, caching, and origin failover.
- AWS WAF + Shield Standard - protection against common Layer-7 attacks and baseline DDoS protection.

### Web frontend
- Amazon S3 (private bucket) - durable static asset storage.
- CloudFront Origin Access Control (OAC) - prevents direct public access to S3.

### API ingress
- Application Load Balancer (ALB) - Layer-7 routing, health checks, and TLS termination for backend traffic.

### Compute (REST API backend)
- EC2 Auto Scaling Group - horizontally scalable, stateless API level deployed across private subnets in two AZs.
- Instances are launched from a standardized image (baked AMI or bootstrap-based), enabling fast and reliable scale-out.

### Database
- Amazon RDS (multi-AZ) - managed relational database with automatic failover, suitable for e-commerce applications.

### Authentication
- Amazon Cognito - managed user authentication using JWT tokens, avoiding credential storage in the application database.
- Token validation is enforced at the application layer.

### Real-time processing
- Amazon SQS - separates non-critical background work from synchronous API requests, improving resilience and latency.

### Outbound connectivity
- NAT Gateway (one per AZ) - allows private instances to access external services (patching, package repositories, external APIs) without inbound exposure.

## Resilience and Disaster Recovery

### High availability
- ALB and EC2 compute deployed in two Availability Zones.
- API compute capacity is maintained in each AZ.
- RDS uses multiple AZs with automatic failover and a single writer endpoint.

### Disaster recovery (pilot-light model)
A separate AWS region is used for DR:
- Networking and ALB are pre-provisioned.
- Compute capacity is scaled to zero by default and scaled out on demand.
- CloudFront origin failover is configured to route traffic to DR origins when needed.

## Data protection
- AWS Backup performs scheduled backups and copies recovery points to a cross-region backup vault in the DR region.
- In a DR event, RDS is restored from the latest recovery point.
- S3 Cross-Region Replication (CRR) replicates static frontend assets to the DR bucket.

## Scalability and Availability Strategy

### Compute scaling
- The REST API runs on a stateless EC2 Auto Scaling Group.
- Horizontal scaling allows the platform to absorb traffic increases without redeploying infrastructure.
- ALB health checks ensure only healthy instances receive traffic.

### Static content availability
- CloudFront edge caching reduces latency and protects origins during traffic spikes.
- Versioned static assets enable long cache lifetimes.
- CloudFront origin failover ensures frontend availability during regional failures.

## Monitoring and Logging Strategy

### Metrics and alerting
Amazon CloudWatch Metrics collects:
- ALB metrics (5xx error rate, latency, healthy host count)
- EC2/ASG metrics (CPU, memory, disk, instance health)
- RDS metrics (connections, storage, latency)
- SQS metrics (queue depth and message age)

CloudWatch Alarms evaluate sustained conditions and publish notifications to Amazon SNS (email).

Alerts are grouped into:
- Symptom-based (user impact)
- Cause-based (capacity or degradation indicators)

### Logging
- Application and system logs are shipped from EC2 via the CloudWatch Agent into CloudWatch Logs, organized by log groups.
- ALB access logs are shipped to Amazon S3 for later auditing and analysis.

## Future Enhancements
- Separate worker tier with independent scaling
- Log-based metric filters for application errors
- Long-term access-log analytics using Athena
- Integration with Alert channels via Lambda Service
- VPC endpoints to reduce NAT usage
- Separate DR account for data retention and protection against account level failures
- Containerized compute (ECS/Fargate) for reduced OS management