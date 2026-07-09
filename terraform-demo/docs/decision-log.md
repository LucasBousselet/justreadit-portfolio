### Decision Log

# General

- Terraform and API demo app are structured around the case study work I did on JustReadIt, a fictional e-book marketplace saas.
https://github.com/LucasBousselet/aws-saas-case-study

# Networking / Packaging

- API listens on port 7070, Docker container forwards 7070:7070
- Terraform builds the ECR private repository, and for now the Docker image is pushed manually. Terraform's purpose is to create infrastructure, not really push Docker images. This can be revisited in later steps when putting together GitHub workflows. Temporary solution: split ECR and app infra creation into 2 separate Terraform files (deploy ECR, upload image, deploy app, destroy all)
- Public SSL certificate will be added in the improvement pass (Milestone 7)

# RDS

- No Multi-AZ deployment for the demo project. It's added in the optinal improvement pass

# Private subnets outbound access

- ECS tasks are running inside private subnets, and are not publicly accessible. However they do still require outbound access to AWS resources such as ECR, S3, Secrets Manager, and CloudWatch.
- Outbound access is configured with:
    - 1 NAT Gateway for general internet access, for traffic initiated by the ECS tasks only.
    - 1 VPC Gateway endpoint for access to S3 from private subnets.
    - No VPC Interface endpoints are configured for the demo project, to keep cost low and complexity reasonable at first. These endpoints would have been created for each AWS resources that ECS private tasks needed access to (ECR, Secrets Manager, CloudWatch), and added to the private route table. They also generate hourly and data transfer costs

# CloudFront / S3

The S3 bucket storing website / cacheable assets has "public access" disabled. It has a bucket policy that only allows a specific CloudFront distribution to retrieve content.
The CloudFront distribution is using OAC to securely access the S3 bucket.
For the initial pass, the default caching behaviour in CloudFront for the website S3 origin, is to use the aws-managed "caching optimized" policy.
Later on more granular custom policies can be added if needed, such as a shorted TTL on index.html, and longer one on versioned JS script.
No CORS policy needed on either CloudFront distributions because:
- website assets are only served through CloudFront, which is a single origin and does not require CORS
- user-content such as banners and book covers are cross-origin (different CloudFront distribution / origin than the website) but are only displayed in the HTML file, so no CORS required either
- user-content private e-books are accessed through S3 presigned URLs and downloaded directly, so no need for CORS.