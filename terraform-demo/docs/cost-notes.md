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
