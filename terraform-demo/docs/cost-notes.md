### Cost Notes

# ECR Private Repository

| Cost Driver | Pricing |
| :--- | :--- |
| Storage | $0.1 GB/month |
| Transfer in (uploads) | Free |
| Transfer out to AWS resources such as Fargate (downloads) | Free |
| Transfer out to the internet (downloads) | $0.09 GB/month |

Basic API Docker image is ~100 MB
15 2-hour learning sessions per month = 15 * 0.1 GB * (2 / ~730 hours) * $0.10 = about $0.0004 per month 

# Networking

| Cost Driver | Pricing |
| :--- | :--- |
| VPC / Subnet / Internet Gateway | Free |
| Security Group / Route Table | Free |
| Public IPv4 Addresses | $0.005/hour per IPv4 |
| Outbound (internet) Data transfer | $0.09/GB < 10TB |

With only 1 ECS task having a network interface / IP
15 2-hour learning sessions per month = 15 * 2 hours * 1 public IPv4 * $0.005/hour = about $0.15 per month 

# ECS

| Cost Driver | Pricing |
| :--- | :--- |
| Compute | $0.04048 per vCPU-hour |
| Memory | $0.004445 per GB-hour |
| Storage | Free < 20 GB |

With 1 task at 0.25 vCPU and 512 MiB of RAM
15 2-hour learning sessions per month = 15 * 2 hours * ((0.25 * $0.04048) + (0.5 * $0.004445)) = about $0.37 per month

# ALB

| Cost Driver | Pricing |
| :--- | :--- |
| Base Charge | $0.0225 per hour |
| LCU Charge | $0.008 per LCU-hour |

The 4 Load Balancer Capacity Unit (LCUs):
- 25 new connections per second
- 3000 active connections
- 1 GB of processed data per hour
- 1000 rule evaluations per second
Billing charges for the highest of the four LCU dimensions in a given hour.

With no significant traffic, the only charge is the base charge.
15 2-hour learning sessions per month = 15 * 2 hours * 0.0225 = about $0.675 per month

# CloudWatch

Demo app is well within the monthly free tier:
- 10 custom metrics
- 10 alarms
- 1 million API requests
- 5 GB of log ingestion

# RDS Postgres

| Cost Driver | Pricing |
| :--- | :--- |
| Compute (t4g.micro) | $0.018 per hour |
| Storage (gp2) | $0.127 per GB/month |
| Backups | Free < DB storage size 20 GB |
| Data transfer inbound | Free |
| Data transfer outbound | Free if < 100 GB |

With no significant traffic, the only charge is the compute and storage.
15 2-hour learning sessions per month = 15 * 2 hours * $0.018 per hour + (30 hours / 730 hours) * 20 GB * 0.127 GB/month = about $0.64 per month

# S3 Standard

| Cost Driver | Pricing |
| :--- | :--- |
| Storage | $0.023 per GB/month < 50 TB |
| Data transfer inbound | Free |
| Data transfer outbound | $0.09 per GB/month < 10 TB |
| Request fees (GET) | $0.0004 per 1,000 requests |
| Request fees (POST/PUT/LIST) | $0.005 per 1,000 requests |

Request fees are negligeable for a demo. Cost of storing 1 GB per session is:
15 2-hour learning sessions per month = (30 hours / 730 hours) * 1 GB * 0.023 GB/month = about $0.001 per month

# CloudFront

| Cost Driver | Pricing |
| :--- | :--- |
| Data transfer outbound | $0.085 per GB < 10 TB |
| Data transfer inbound | Free |
| Data transfer from AWS service S3/ALB | Free |
| Request fees (HTTP) | $0.0075 per 10,000 requests |
| Request fees (HTTPS) | $0.01 per 10,000 requests |
| Default CloudFront TLS certificate | Free |

Request fees are negligeable for a demo. 
If we are serving 500 MB per session: about 7.5 GB served
7.5 GB * $0.085 per GB = about $0.6375 per month

