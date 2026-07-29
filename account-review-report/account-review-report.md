# JustReadIt AWS Account Review Report

Company: JustReadIt
State: pre-launch
Region: ca-central-1
Workload: containerized SaaS application for an e-book marketplace

## Context

JustReadit is a fictinal SaaS e-book marketplace app deployed by Terraform on AWS. It includes a frontend, API backend, database, object storage and basic CI/CD.

## Scope / Limitations

This report reviewed the suggested case-study architecture against the Terraform infrastructure-as-code pre-production app.

Reviewed:
- Monthly cost drivers
- IAM and access controls
- Network security
- Logging and monitoring
- Backup and recovery plans
- Reliability risks  

Not reviewed:
- Application code business logic
- Penetration testing risks
- Live AWS billing
- Past production incidents 

Evidence sources:
- Terraform files
- [GitHub Actions workflow files](../.github/workflows/)
- [Case study](../case-study/architecture.md)

## Executive Summary

The current architecture is laying reasonable groundwork for a SaaS, but needs a few adjustments in order to go from a pre-launch to a production-ready product. 

The foundational technical decisions that went into the pre-launch app are sound, using ECS Fargate, RDS PostgreSQL, CloudFront and S3 supports an application that can be managed by a small team with a clear path to scale up and grow without large refactoring efforts. The biggest risks are using a single ECS task, RDS database that is still configured for pre-launch, but they can be quickly addressed.

Security-wise having ECS tasks and database in private subnets is a safe decision, but using HTTPS between CloudFront and origin should be a requirement for launch. Setting up CloudWatch alarms and AWS Budgets and longer log retention policies are also essential to help the team and the company as a whole maintain the product running in good condition, react efficiently to failures, and control costs.

## Scorecard

| Area | Score | Risk | Summary |
| :--- | :--- | :--- | :--- |
| Reliability | 2/5 | High | The correct architecture elements are in place (CloudFront, ALB, health checks), but are not production-ready yet. The API only runs one task and RDS DB is likely too tiny for real traffic |
| Security | 3/5 | Medium | Placing ECS tasks and RDS DB in private subnets is good, but TLS protocol should be set up between CloudFront and ALB origin for securing data in transit |
| Cost Management | 3/5 | Medium | Cost-conscious sizing is present, but budgets and more granular tags would help monitor and control costs |
| Observability | 3/5 | Medium | ECS logs exist but need a longer retention period. Alarms should be configured to quickly get notified of an incident |

Scoring legend
| Score | Meaning |
| :--- | :--- |
| 1 | Critical gaps; not production-ready |
| 2 | Some foundation exists, but important risks remain |
| 3 | Reasonable baseline with clear improvements needed |
| 4 | Strong posture with minor gaps |
| 5 | Mature, monitored, and well-documented |

## Prioritized Recommendations

| Priority | Recommendation |  Area | Effort |
| :--- | :--- | :--- | :--- |
| P1 | Run at least 2 ECS tasks | Reliability | Low |
| P1 | Harden RDS production settings | Reliability | Low/Medium |
| P2 | Add HTTPS between CloudFront and ALB | Security | Medium |
| P2 | Add key CloudWatch alarms | Observability | Medium |
| P3 | Configure AWS Budgets | Cost | Low |
| P3 | Enable ALB access logs and adjust log retention period | Observability | Low |

## Findings

### Reliability

Finding: ECS service is running only 1 task at all times
Severity: High
Evidence: In [ecs.tf](../terraform-demo/infra/app/ecs.tf#L92), `aws_ecs_service.ecs_service` has `desired_count` set to 1
Impact: High, if the only task becomes unhealthy, the whole API is unreachable 
Recommendation: Maintain at least 2 tasks running at all times, in different AZs
Effort: Low, ECS service is already spanning 2 AZs and target registration is handled automatically. By changing `desired_count` to 2, ECS will make a best-effort placement across the configured subnets
Priority: High 

Finding: NAT Gateway is Single-AZ
Severity: Medium
Evidence: In [networking.tf](../terraform-demo/infra/app/networking.tf#L160), only one NAT Gateway (`aws_nat_gateway.public_nat_gateway`) is created, and assigned a public subnet
Impact: Medium, if an AZ-level incident occurs, the single NAT Gateway goes down and ECS tasks lose outbound access. The risk is a bit lower than the previous finding because NAT Gateways are AWS-managed and redundant within their AZs. They are solid but an AZ-level incident is a real risk.
There is a cost vs reliability tradeoff here:
- a Single-AZ NAT Gateway incurs an hourly cost (~30$/month) + data transfer charges, but it is a single point of failure that can cause private ECS tasks to lose outbound access to services such as Secrets Manager or CloudWatch
- multiple NAT Gateways in different AZs multiply the NAT-related costs with each additional one, but the application becomes resilient to an AZ-level incident.
- VPC endpoints have cheaper hourly and data transfer prices, but one VPC endpoint is required per service that needs to communicate with private subnets, and adds complexity.
Recommendation: Add another NAT Gateway in a second AZ, or use the Regional NAT Gateway availability mode
Effort: Low, split the shared private route table in two, one for each private subnet. Then create a second NAT Gateway and have both private route table use a different one. Alternatively you can create a NAT Gateway in Regional availibility mode and set it to span 2 AZs 
Priority: Medium 

Finding: RDS DB still sized for pre-launch
Severity: Medium/high
Evidence: In [storage.tf](../terraform-demo/infra/app/storage.tf#L1), the DB is configured to run on a `db.t4g.micro` instance which only has 1 GiB of memory, not enough for the expected traffic of the production application. It also uses a `gp2` volume, which AWS recommends migrating to `gp3` to decouple disk performance and storage capacity 
Impact: Medium/high, the database is likely to become a bottleneck under real traffic, and could experience slow downs or crashes if memory pressure is too high
Recommendation: Migrate to a bigger instance such as `db.t4g.medium` and monitor traffic in order to see if further adjustments are needed. Also migrate to a `gp3` volume type
Effort: Low/medium, changing storage class is easy but changing instance class will result in some downtime, which needs to be planned when the app is receiving little to no traffic. Failover strategies might be necessary depending on whether a few minutes of downtime is acceptable
Priority: High

Finding: RDS DB resiliency is too weak
Severity: Medium/high
Evidence: In [storage.tf](../terraform-demo/infra/app/storage.tf#L1), the DB has `deletion_protection` and `skip_final_snapshot` disabled, when it should be enabled for a production database. Besides, depending on growth, considering a plan to upgrade to a Multi-AZ deployment would be useful. The backup retention period of 7 days is too short for a production environment
Impact: Medium/high, lack of deletion protection or final snapshot means that the database could be mistakenly dropped or corrupted without recovery option.
Recommendation: Enable both `deletion_protection` and set `skip_final_snapshot` to `false`. Increase backup retention to one month. To keep costs low, the DB can use a Multi-AZ instance deployment as a failover mechanism. If growth calls for it, a Multi-AZ cluster deployment with writer/reader instances can be considered
Effort: Low, it requires only changes to Terraform configuration
Priority: Medium/high 

### Security

Finding: Un-encrypted traffic between CloudFront and ALB
Severity: Medium
Evidence: In [networking.tf](../terraform-demo/infra/app/networking.tf#L142), the ALB listener `alb_listener_front_end` is using HTTP (port 80) and is not configured with an ACM certificate. Traffic between CloudFront and ALB is plain text 
Impact: Medium, end-users will not notice a difference, but an attacker listening on the network jump between CloudFront and ALB will be able to see plain text HTTP traffic. Cookies, headers, API payloads are exposed. Authenticated users' private information and payments data must be processed securely
Recommendation: Attach an ACM certificate to the ALB, and encrypt traffic between CloudFront and ALB by making the origin use HTTPS
Effort: Medium, request an ACM certificate for the ALB origin domain or use an existing one. Then update Terraform configuration to attach the certificate to the ALB listener, and update CloudFront to connect to the ALB over HTTPS only. HTTP traffic can be redirected to HTTPS
Priority: Medium/high 

Finding: ALB security group allows inbound traffic from any CloudFront distribution
Severity: Low/medium 
Evidence: In [networking.tf](../terraform-demo/infra/app/networking.tf#L142), the ALB is public facing, but only allowing inbound traffic get past the security group if a matches the CloudFront prefix list (in `aws_vpc_security_group_ingress_rule.allow_alb_https_ipv4`). That includes any third party CloudFront distribution, which could open to malicious traffic. There is no additional security to prove that incoming traffic is originating from the company CloudFront.
Impact: Low/medium
Recommendation: Pass a custom header such as `X-Origin-Verify` set to a secret value, along with the request CloudFront is sending the ALB. The ALB listener rule will read the header and confirm that the request can be forward to its destination. If the header is missing or incorrect, the request is dropped. This remediation should come after HTTPS is implemented between CloudFront and the ALB, so that the traffic/headers are encrypted
Effort: Low
Priority: Low/medium 

### Cost Management

Finding: AWS Budgets are not configured
Severity: Low
Evidence: Terraform does not define budgets to alert the team when AWS-related costs are going over-budget (or are predicted to)
Impact: Low/medium
Recommendation: Create a simple monthly budget and associated alarms
Effort: Low/medium
Priority: Low

Finding: Resource tagging is too generic
Severity: Low
Evidence: All resources are only tagged with `Product=JustReadIt` which is a good start, but could be expanded
Impact: Low
Recommendation: Tag resources into logical groups (compute, network, storage) to make it easy to breakdown cost reports
Effort: Low/medium
Priority: Low

### Observability

Finding: ALB access logs are disabled
Severity: Low
Evidence: In [networking.tf](../terraform-demo/infra/app/networking.tf#L142), the ALB access logs are not configured. Access logs can be useful for debugging ("Did the request reach ALB at all?"), security ("Are requests hitting the ALB directly or going through CloudFront first?"), and business insights ("Which routes are most common?")
Impact: Low
Recommendation: Turn on if you are troubleshooting network issues involving the ALB, or wish to run analytics queries on the traffic.
Effort: Low
Priority: Low 

Finding: ECS logs in CloudWatch are retained for 7 days only
Severity: Low/medium
Evidence: In [ecs.tf](../terraform-demo/infra/app/ecs.tf#L128), for the CloudWatch log group  (`aws_cloudwatch_log_group.justreadit_log_group`), `retention_in_days` is set to `7`, which is short-lived for a production environment
Impact: Medium
Recommendation: Increase log retention to 1 to 3 months for the production environment. In the event of an incident, it is useful to have a complete history for troubleshooting efficiently.
Effort: Low
Priority: Medium

Finding: CloudWatch alarms are not configured
Severity: Medium
Evidence: Terraform does not define alarms to alert the team when an incident occurs with one of the cloud resources
Impact: Medium
Recommendation: Create alarms when metrics are crossing a threshold (ex: CPU usage on ECS task > 90%), and set up a SNS topic to dispatch critical events to a company message app / employee emails
Effort: Medium, need to consider what metrics are worth monitoring for the workloads, and how organize the team to respond effectively in case of problem
Priority: Medium

## What Is Already Done Well

- Sensitive workloads such as ECS tasks and RDS DB are placed in private subnets with no publicly accessible IP
- S3 buckets are blocking public access and use Origin Access Control to restrict how they can be modified
- GitHub Actions workflows use OIDC authentication with short-lived credentials

