# JustReadIt AWS Portfolio Project

JustReadIt is a fictional e-book marketplace used to demonstrate AWS architecture, Terraform infrastructure, CI/CD, and cloud account review skills.

This project includes:

- A [cost-conscious AWS SaaS architecture case study](./case-study/architecture.md), describing the fictional scenario with business and technical constraints, as well as goals for the application. It provides an [architecture diagram](./case-study/diagrams/aws-saas-architecture.svg) alongside a more detailed explanation of the AWS services used, the tradeoffs they imply, and the traffic assumptions the case study falls under.
- A [deployable pre-production reference implementation using Terraform](./terraform-demo/infra/), which creates a pre-production version of the ideal architecture described in the case study.
- A [small .NET API](./terraform-demo/app/JustReadIt.Api/) and [frontend](./terraform-demo/frontend/) used to validate the infrastructure, acting as a simple web app and supporting backend that proves the essential communication paths are in place (frontend to API, API to DB, API to S3, etc).
- [GitHub Actions workflows](./.github/workflows/) for validation, image build, and deployment
- A [synthetic AWS account review report](./account-review-report/account-review-report.md) with cost, security, reliability, and observability findings, which reviews the pre-production version and provides tiered recommendations for upgrading to a production-ready workload.

## What This Proves

- I can design a realistic AWS architecture for a small SaaS team, gathering business and technical requirements and turning them into an actionable plan supported by costs estimates and sizing recommendations.
- I can translate architecture decisions into Terraform infrastructure, which can be deployed in a real environment and provide a clean way to evolve the architecture and control drift.
- I understand cost, security, reliability, and operational tradeoffs, can document them and defend reasonable decisions based on the desired outcome, either a pre-production version or production-ready architecture.
- I can communicate cloud risks and recommendations in client-facing language, using accurate language and the ability to turn a suggested architecture into a digestible diagram showing the important pieces of the design.

## Production Readiness Notes

This is intentionally scoped as a pre-production reference implementation. Known production gaps are documented in the account review report, including the single ECS task, HTTP traffic between CloudFront and the ALB origin, missing alarms/budgets, and short CloudWatch log retention.
