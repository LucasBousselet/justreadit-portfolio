### Decision Log

# General

- Terraform and API demo app are structured around the case study work I did on JustReadIt, a fictional e-book marketplace saas.
https://github.com/LucasBousselet/aws-saas-case-study

# Networking / Packaging

- API listens on port 7070, Docker container forwards 7070:7070
- Terraform builds the ECR private repository, and for now the Docker image is pushed manually. Terraform's purpose is to create infrastructure, not really push Docker images. This can be revisited in later steps when putting together GitHub workflows