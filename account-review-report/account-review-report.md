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
Effort: Low/medium, changing storage class is easy but changing instance class will result in some downtime, which needs to be planned when the app is receiving little to no traffic. Failover strategies might be necessary depending on whether a few minutes of downtime is acceptable
Priority: High 

### Security

Finding: Un-encrypted traffic between CloudFront and ALB
Severity: Medium/high
Evidence: In networking.tf, the ALB listener `alb_listener_front_end` is using HTTP (port 80) and is not configured with an SSL certificate. Traffic between CloudFront and ALB is plain text 
Impact: Medium, end-users will not notice a difference, but an attacker listening on the network jump between CloudFront and ALB will be able to see plain text HTTP traffic. Cookies, headers, API payloads are exposed. Authenticated users' private information and payments data must be processed securely
Recommendation: Attach an SSL certificate to the ALB, and encrypt traffic between CloudFront and ALB by making the origin use HTTPS
Effort: Medium, need to purchase an SSL certificate and import it to AWS. Then Terraform configuration must be updated to make the CloudFront origin for ALB use HTTPS, and configure the listeners to use the certificate and accept only HTTPS, plus redirecting HTTP traffic to HTTPS
Priority: Medium/high 

Finding: ALB security group allows inbound traffic from any CloudFront distribution
Severity: Low/medium 
Evidence: ALB is public facing, but only allowing inbound traffic get past the security group if a matches the CloudFront prefix list (in `aws_vpc_security_group_ingress_rule.allow_alb_https_ipv4`). That includes any third party CloudFront distribution, which could open to malicious traffic. There is no additional security to prove that incoming traffic is originating from the company CloudFront.
Impact: Low/medium
Recommendation: Pass a custom header such as `X-Origin-Verify` set to a secret value, along with the request CloudFront is sending the ALB. The ALB will read the header and confirm that the request can be forward to its destination. If the header is missing or incorrect, the request is dropped. This remediation should come after HTTPS is implemented between CloudFront and the ALB, so that the traffic/headers are encrypted
Effort: Low
Priority: Low/medium 

### Operational

Finding: ALB access logs are disabled
Severity: Low
Evidence: in `aws_lb.alb`, `access_logs` is not configured. Access logs can be useful for debugging ("Did the request reach ALB at all?"), securiy ("Are requests hitting the ALB directly or going through CloudFront first?"), and business insights ("Which routes are most common?")
Impact: Low
Recommendation: Turn on if you are troubleshooting network issues involving the ALB, or wish to run analytics queries on the traffic.
Effort: Low
Priority: Low 

Finding: ECS logs in CloudWatch are retained for 7 days only
Severity: Low/medium
Evidence: in `aws_cloudwatch_log_group.justreadit_log_group`, `retention_in_days` is set to `7`, which is short-lived for a production environment
Impact: Medium
Recommendation: Increase log retention to 6 months to a 1 year for the production environment. In the event of an incident, it is useful to have a complete history for troubleshooting efficiently.
Effort: Low
Priority: Medium

