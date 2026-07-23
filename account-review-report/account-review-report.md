# JustReadIt AWS Account Review Report

Company: JustReadIt
State: pre-launch
Region: ca-central-1
Workload: containerized SaaS application for an e-book marketplace

## Context

JustReadit is a demo SaaS e-book marketplace app deployed by Terraform on AWS. It includes a frontend, API backend, database, object storage and basic CI/CD.

## Scope 

This reports reviewed the suggested case-study architecture against the Terraform infrastructure-as-code demo app.

Reviewed:
- Monthly cost driver
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

## Executive Summary

ToDo once finished

## Scorecard

| Severity | Evidence | Impact | Recommendation | Effort | Priority |
| :--- | :--- | :--- | :--- | :--- | :--- |
| ToDo | ToDo | ToDo | ToDo | ToDo | ToDo |

## Findings

### Reliability

Finding: ECS service is running only 1 task at all time
Severity: High
Evidence: In ecs.tf, `aws_ecs_service.ecs_service` has `desired_count`set to 1
Impact: High, if the only task becomes unhealthy, the whole API is unreachable 
Recommendation: Maintain at least 2 tasks running at all time, in different AZs
Effort: Low, ECS service is already spanning 2 AZs and target registration is handled automatically. By changing `desired_count` to 2, ECS will to its best-effort to spread the tasks across AZs
Priority: High 

Finding: NAT Gateway is Single-AZ
Severity: Medium/high
Evidence: In networking.tf, only one NAT Gateway (`aws_nat_gateway.public_nat_gateway`) is created, and assigned a private subnet
Impact: Medium/high, if an AZ-level incident occurs, the single NAT Gateway goes down and ECS tasks lose outbound access. The risk is a bit lower than the previous finding because NAT Gateways are AWS-managed and redundant within their AZs. They are solid but an AZ-level incident is a real risk
Recommendation: Add another NAT Gateway in a second AZ, or use a regional NAT Gateway spanning 2 AZs
Effort: Low, split the shared private route table in two, one for each private subnet. Then create a second NAT Gateway and have both private route table use a different one 
Priority: Medium/high 

Finding: RDS DB is undersized
Severity: High
Evidence: In storage.tf, the DB is configured to run on a `db.t4g.micro` instance which only has 1 GiB of memory, not enough for the expected traffic of the production application. It also uses a `gp2` volume, which AWS recommends migrating to `gp3` to decouple disk performance and storage capacity
Impact: Medium/high, the database will be overwhelmed when real traffic starts coming in, and will experience slow downs or crash if memory pressure is too high
Recommendation: Migrate to a bigger instance such as `db.t4g.medium` and monitor traffic in order to see if further adjustments are needed. Also migrate to a `gp3` volume type
Effort: Low/medium, changing storage class is easy but changing instance class will result in some downtime, which needs to be planned when the app is receiving little to no traffic. Failover strategies might be necessary depending on whether a few minutes of downtime is acceptable. 
Priority: High 
