# JustReadIt AWS Terraform Implementation

This repository implements a simplified deployable version of the AWS architecture described in the JustReadIt case study (`aws-saas-case-study`).

The goal is to demonstrate a cost-conscious SaaS deployment using ECS Fargate, ALB, RDS PostgreSQL, S3, CloudWatch, IAM, and Terraform.

## What this deploys

- A containerized backend running on ECS Fargate, with supporting ECR registry
- An RDS PostgreSQL database communicating privately with the backend
- Two S3 and two CloudFront distributions for serving a simple web app and user-uploaded assets
- Two simple CI/CD GitHub Actions workflows to deploy the app to AWS automatically
- Supporting networking and security elements such as VPC, route tables, NAT Gateway, security groups and IAM roles 

## What is simplified

- CI/CD workflows only run on a manual trigger, and not on every commit to the dev/main branches
- API is only serving 2 demo endpoints to validate communication with browser, database, and S3
- Demo architecture is running on tiny instances
- Monitoring, alarms and cost alerts are not configured

# Milestones

- [x] Milestone 0: Create demo app and Dockerfile
- [x] Milestone 1: Learn Terraform basics + Deploy one ECR repository
- [x] Milestone 2: Deploy simplified API container to ECS Fargate, with basic ECS task definition, ECS service, and IAM execution role 
- [x] Milestone 3: Deploy VPC and ALB, security groups, target group, health check, and CloudWatch log group
- [x] Milestone 4: Deploy RDS PostgreSQL, DB security group, Secrets Manager for DB credentials
- [x] Milestone 5: Add S3 buckets and CloudFront distribution
- [x] Milestone 6: Add CI/CD via GitHub Actions
- [x] Milestone 7: Add NAT Gateway + VPC Endpoints
- [ ] Milestone 8: (optional) Add:
                        - production environment
                        - Route 53 hosted zone and DNS record + public TLS certification