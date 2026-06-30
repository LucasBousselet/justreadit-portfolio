# JustReadIt AWS Terraform Implementation

This repository implements a simplified deployable version of the AWS architecture described in the JustReadIt case study (`aws-saas-case-study`).

The goal is to demonstrate a cost-conscious SaaS deployment using ECS Fargate, ALB, RDS PostgreSQL, S3, CloudWatch, IAM, and Terraform.

## What this deploys

- 

## What is simplified

- 

# Milestones

- [x] Milestone 0: Create demo app and Dockerfile
- [x] Milestone 1: Learn Terraform basics + Deploy one ECR repository
- [-] Milestone 2: Deploy simplified API container to ECS Fargate, with basic ECS task definition, ECS service, and IAM execution role 
- [ ] Milestone 3: Deploy VPC and ALB, security groups, target group, health check, and CloudWatch log group
- [ ] Milestone 4: Deploy RDS PostgreSQL, DB security group, Secrets Manager for DB credentials
- [ ] Milestone 5: Add S3 buckets and CloudFront distribution
- [ ] Milestone 6: Add CI/CD via GitHub Actions
- [ ] Milestone 7: (optional) Add production environment / Route 53 hosted zone and DNS record