### Decision Log

# General

- Terraform and API demo app are structured around the case study work I did on JustReadIt, a fictional e-book marketplace saas.
https://github.com/LucasBousselet/aws-saas-case-study

# Networking / Packaging

- API listens on port 7070, Docker container forwards 7070:7070
- Terraform builds the ECR private repository, and for now the Docker image is pushed manually. Terraform's purpose is to create infrastructure, not really push Docker images. This can be revisited in later steps when putting together GitHub workflows. Temporary solution: split ECR and app infra creation into 2 separate Terraform files (deploy ECR, upload image, deploy app, destroy all)
- Public SSL certificate will be added in the improvement pass (Milestone 7)