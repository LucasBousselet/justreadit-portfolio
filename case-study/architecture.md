# Designing a Cost-Conscious SaaS Backend on AWS

## Summary

A practical AWS architecture for a small B2B SaaS product that needs reliability, moderate scalability, controlled cost, and a straightforward deployment model.

## Scenario

JustReadIt is a fictional company that wants to create a web application to sell and buy self-published e-books. Authors can upload their e-books, and anyone around the world can browse the growing catalog and make purchases.
The company has 20 employees and is planning on operating in Canada first, with plans to expand to the USA or Europe in the future.
The web application is expected to serve between 10k and 50k single users each month:
- about 90% of users are customers, using the web app to purchase e-books;
- about 10% os users are writers, using the web app to upload their work and distribute it.

Business contraints:
- company wants predictable and controlled monthly cost for running the infrastructure;
- company has a small engineering team of 4 people, so they need an architecture that is easy to understand and maintain; 
- company can commit to using AWS services for long term (3 years);
- company wants a resilient system that avoids a single point of failure;
- leadership wants clear visibility into costs in order to make decisions;
- leadership wants the infrastructure to be able to scale up for future growth, without huge refactoring effort;
- writers must reside in Canada and have their e-books stored in Canada for IP reasons. Customers can be worldwide;

Technical requirements:
- backend should run at least 2 instances at all times;
- backend should scale automatically depending on current traffic;
- backend server should be containerised for easy reusability and consistency;
- database should not be publicly visible, and have a backup strategy in place;
- database should store relational information on customers, authors, e-books metadata, orders, invoices and so on. However, e-books themselves and other static assets need to be stored in a secure S3 bucket, and served efficiently;
- public entry point of the application should be CloudFront or a load balancer;
- backend servers should not be publicly visible
- new deployments should be automated and easily to rollback;
- development and staging environments should run beside the production one;
- engineering team and leadership need to be quickly notified when a failue happens, and should be able to collect and inspect logs and errors;
- AWS infrastructure must use best practice like least privileged access, secure credentials, encryption in transit and at rest;
- AWS infrastructure must be available in two availability zones at all times, and use proper load balancing and health checks, and scale in and out to meet demand. 

## Goals

- Keep monthly AWS costs predictable
- Avoid unnecessary operational complexity
- Support future growth
- Use managed services where possible
- Keep the architecture understandable for a small team

## Architecture Overview

![AWS SaaS architecture](diagrams/aws-saas-architecture.svg)

*Figure 1: High-level AWS architecture for a cost conscious SaaS backend.*

A typical user request will follow this path:

1. The user accesses the application through "justreadit.com", with DNS managed in Route 53. The domain point to the CloudFront distribution.
2. CloudFront acts as the public entry point and terminates the public TLS connection in order to inspect the request. From there one of two paths is used:
- Static frontend assets and cacheable content are served from CloudFront cache or retrieved from the origin S3 static asset bucket. S3 buckets are private, and will not be publicly acccessible.
- API requests, such as `/api/*`, are forwarded to the Application Load Balancer.
3. The ALB only accepts requests from CloudFront. It routes the request to healthy ECS Fargate tasks running in private subnets across multiple Availability Zones.
4. The backend service handles the request and, when needed, communicates with private internal services such as RDS PostgreSQL, S3 for private user content, Secrets Manager, and CloudWatch.
5. The response is returned to the user through the ALB and CloudFront. Successful requests return the expected response, while failures return an appropriate HTTP error code and are logged for monitoring and troubleshooting.

## Proposed AWS Services

### Route 53 
Route 53 manages DNS for "justreadit.com". An alias record points the application domain to the CloudFront distribution, which makes it the entry point for the web application.
AWS resolves the CloudFront distribution's domain name to the appropriate edge locations.

### CloudFront 
CDN service that caches static assets in servers spread out across the world, close to end users.
CloudFront serves the frontend application and cacheable public assets like fonts and images. Protected content like e-book files are not publicly cacheable, and are only access after backend authorization.
CloudFront terminates the public TLS connection and forwards API requests to the ALB over a separate TLS connection.
At every request, it evaluates if a fresh cached version exists and sends it back immediately if so. If not, it will get a fresh copy and cache it for the next user.
Being close to end users means latency is low, and highly popular content is served rapidly without requiring an additional call to backend services.

### S3 
The app uses 2 S3 buckets for storage:
- one for static assets, like the frontend HTML file, Javascript bundles, CSS, images, fonts. This can be widely cached. Public/static content is served through CloudFront, which has access to the bucket as origin;
- one for private user-uploaded content, like e-books or profile pictures. This is accessed via presigned URLs generated in the backend, and is enforcing stricter rules, like access control, content moderation, malware scanning. It it also making sure private user content (e-books especially) is hosted in Canada, which is a legal requirement.
It is durable and scales automatically.
Public access to the buckets is blocked, so direct access by end users is impossible. 
 
### Application Load Balancer
Internet facing origin for CloudFront, its security group will restrict direct access, so API traffic enters through CloudFront instead of bypassing it.
Dispatches incoming requests between the available backend containers. 
The ALB distributes API requests across healthy ECS tasks and stops routing traffic to tasks that fail health checks.
The ALB works together with a target group and ECS Service Auto Scaling in order to adjust the desired count of Fargate tasks based on CloudWatch metrics. The initial scaling policy uses CPU utilization as baseline, with option to add memory utilization or ALB request count per target once real traffic patterns are observed.
Operates in a minimum of 2 AZs, which is designed for supported good availability.

### ECS Fargate
Runs the backend application within a container. Fargate removes the need to provision, patch and manage EC2 instances. The team still owns the application container image, tasks runtime configuration, and application-level security.
The backend app is configured to be built as a Docker image, which is stored in AWS Elastic Container Registry ECR. It is then easy to pull the latest image from the repository, and run it within a container in ECS.
Depending on the scaling policy, several containers of the same backend application can be running in parallel.
ECS containers only accept requests coming from the ALB, and are in a private network which allows them to communicate with the DB securely.

### NAT Gateway / VPC Endpoints - Private subnet outbound access
ECS Fargate tasks run in private subnets, so they are not directly reachable from the internet. However, they still need outbound access to AWS services such as ECR, CloudWatch Logs, Secrets Manager, and S3, which are not part of the VPC. They may also need to call external services providers to handle emails or payments for example.
In this initial design, private outbound access is controlled via a NAT Gateway for general internet access, and via VPC endpoints for private AWS service traffic.
The exact mix should be validated during implementation, with tradeoffs discussed in the "Cost Assumptions" section.  

### RDS
RDS PostgreSQL stores relational application data such as users, authors, e-book metadata, orders, invoices and reviews. The production database is deployed in private subnets using a Multi-AZ DB instance deployment.
In this initial design, the standby database is used for high availability and failover only, it does not serve any traffic. Read/write traffic only go through the primary database endpoint. Automated backups and point-in-time recovery are also enabled because Multi-AZ deployments do not protect against accidental data loss, bad migrations, or application bugs that write incorrect data. 
Storage auto-scaling is configured so the database can grow without manual resizing.
Non-production databases (staging, dev, or test environments) may use singe AZ deployments, for lower costs.

### Secrets Manager
Stores DB credentials and other sensitive values such as API keys.
ECS tasks access these secrets through IAM roles (no hardcoded credentials in the code).
DB credentials are configured to be automatically rotated.

### CloudWatch
Monitors the AWS infrastructure via metrics and logs, collecting ECS container logs, ALB metrics, RDS metrics, and custom application metrics.
Alarms are triggered when metrics (CPU/memory utilization, health checks, latency) exceed the defined thresholds. 
Alerts notify the team in case of failure (emails, texts, or company messaging app notifications).

### Terraform
Terraform defines the AWS infrastructure as code.
It allows the team to review infrastructure changes through pull requests, track changes in version control, and reproduce any environment (dev, staging, prod) consistently.
It also helps facilitate the process of deploying the application automatically in CI/CD pipelines.

### CI/CD
GitHub Actions run workflows that build and test the application, push Docker images to ECR, and deploy to ECS.
Pull requests merged into dev or staging branches are deployed automatically.
Production deployments require an explicit manual approval step.

## Key Tradeoffs

### CloudFront - Availability and performance VS simplicity
CloudFront adds operational complexity that the team must understand, such as cache invalidation, harder debugging with one extra layer, and separate behaviour for static assets and API requests.
However it improves global delivery because edge locations are geographically near end users, which lower latency. It also reduces the load on S3 and the ALB, and acts as a clean entry point for TLS.

### RDS VS DynamoDB - Relational VS no-SQL DBs
DynamoDB is fast and easy to scale, and uses a key-value access pattern that does not enforce strict data schemas. It is suitable for high-scale workloads with predictable requests that can be indexed effeciently. 
However in this case, we expect our data to be strongly relational, and we prefer a tight and enforced schema definition. The nature of the data (users are linked to orders and invoices, writers are linked to e-books and so on) makes it appropriate to be handled in a relational database, as it is structured and will be easy to query using joins, transactions and foreign keys.

### RDS Single AZ + Backup VS RDS Multi-AZ DB instance deployment VS RDS Multi-AZ DB cluster deployment
RDS Single AZ deployment offers simplicity and low cost, and is suitable for non-production environments or prototyping.
One requirement for this architecture is to avoid a single point of failure, so we want to take the DB deployment one step further with Multi-AZ DB instance deployment. This means that the database is synchronously replicated to a standby instance, which will automatically take over if the primary writer becomes unavailable. It is slightly more complex than the Single AZ deployment, but significantly more resilient to failures. 
The standby instance is only use for high availability, it does not serve traffic. Read/write traffic goes through the primary endpoint, avoiding read-after-write consistency issues that acan appear when using separate read replicas.
The most resilient and performant design is the Multi-AZ DB cluster deployment, which includes one writer instance and 2 reader instances, all in different AZs. This is more complex as concurrency issues can occur and need to be dealt with. It is also more costly, so for this first design, Multi-AZ DB instance deployment is the better choice.

### ECS Fargate VS ECS self-managed EC2 - Cost VS Operational overhead
ECS can be configured to run with self-managed EC2 instances, which lowers the bill but comes with increasing operational overhead because the team has to manage the instances themselves. 
Design decision around the database (RDS PostgreSQL) requires operational attention from the team, so reducing overhead for compute operations using Fargate is a reasonable tradeoff.
If Fargate-specific costs are too high, the team can switch to ECS EC2 without much friction because the app is shipped as a Docker container already.

### CloudFront signed URLs VS S3 presigned URLs - Performance VS Data residency compliance and simplicity
For the initial design, the decision is to use S3 presigned URLs for protected e-books downloads. It is simpler to implement, and lets the backend confirm the user is authorized to view the file before each download, while keeping a strict "no public access" policy on the bucket.
E-books will not benefit from CloudFront caching at launch, so latency may increase for users far from the Canada West region. It is the target region for the initial launch so the tradeoff makes sense. A requirement is to store e-books in Canada for intellectual property reasons, so caching at edge locations may violate the requirement (depending on whether it is acceptable to store a cached version outside Canada). If the IP requirement allows it, and high download traffic is observed globally, CloudFront caching can be considered to improve performance.

## Sizing and Cost Assumptions

This section provides estimates about expected traffic and cost. Numbers are approximate and are meant to be order of magnitude rather than hard projections.

### Traffic assumptions

The architecture is designed for a SaaS product expected to reach 10,000 to 50,000 monthly active users within the first year.
Because monthly active users do not translate directly into infrastructure load, we are making the following assumptions:

- 10–25% of monthly users are active on a given day.
- Each daily active user has 1–2 sessions per day.
- Each session generates 25–50 API requests. (login / dashboard / fetch account details / list records)
- Peak traffic can reach 5–10x of average traffic, during a special event for example.
- Each API request generates 1–5 database reads on average.
- Only a minority of requests create or update data.

These API requests estimates represent traffic reaching the backend services. Static and cached content are served primarily by CloudFront and S3, which reduces the number of requests that reach the ALB and ECS.
The following traffic estimates are calculated based on the upper limit of expected growth, 50k monthly active users:

- 50,000 monthly active users
- 12,500 daily active users (25% of 50k)
- 25,000 sessions per day (with 2 sessions per day)
- 1.25 million API requests per day (with 50 API requests per session)
- 37.5 million API requests per month (with 30 days per month)
- 15 average requests per second 
- 100–150 peak requests per second

### Database storage assumptions

Database storage is estimated using record categories rather than exact table sizes. They are intended for capacity planning only.

| Record category | Assumption | Planning size | Raw estimate |
|---|---:|---:|---:|
| User/account records | 50,000 users × 5 records/user | 2 KB | ~500 MB |
| Book metadata | 10,000 books/year (2 books per author/year) | 10 KB | ~100 MB |
| Orders/invoices | 45,000 customers × 5 orders/year | 5 KB | ~1.1 GB |
| Reviews/comments | 45,000 customers × 5 reviews/year | 3 KB | ~0.7 GB |
| Application events | 50,000 users × 100 events/year | 1 KB | ~5 GB |
| Audit/security logs | 50,000 users × 100 events/year | 1 KB | ~5 GB |

This gives roughly 12.5 GB of raw relational data after one year. We multiply this raw total by 2 to 3 to account for indexes, database overhead, and error margin for an estimated RDS storage range of 25-40 GB on the first year.

The production database is initially allocated 100 GB of storage with autoscaling enabled, to keep the initial configuration simple and leave room for growth. Instance size is a db.t4g.medium or equivalent, Multi-AZ, and automated backups + PITR. This starting point is reasonable but CPU, memory, connection count and latency should be monitored after launch to determine if vertical scaling is necessary.

### S3 storage assumptions

For S3 private user content:

- 10% of 50,000 users are writers = 5,000 writers
- Each writer uploads 2 e-books per year
- Average e-book file size is 2 MB

This gives a total of 5,000 x 2 x 2 MB = ~20 GB of e-book files per year

### Main AWS cost drivers

The initial design combines AWS services that incur a fixed cost, and some whose cost is traffic-based.
Main drivers of fixed costs are:
- RDS production database and its Multi-AZ standby, which are always on;
- ECS Fargate baseline tasks, which has at least 2 prod tasks running in parallel as baseline;
- ALB, NAT Gateway, VPC endpoints and CloudWatch alarms, which are always on;
- Secrets Manager, which adds cost per-secret. 

Other costs that grow with usage:
- S3 storage which will get bigger over time, plus data transfer costs;
- CloudFront data transfer costs;
- RDS storage and backups;
- NAT Gateway data transfer costs;
- CloudWatch logs ingestion + storage;
- extra ECS tasks during traffic peaks;

### AWS Pricing Calculator

Always-on-resources cost is calculated using a baseline of 730h per month.
Using AWS Pricing Calculator, we end up at around 200-300 dollars per month. This figure is a rough estimate and final sizing requires load testing and production metrics. 

### Cost-control decisions

- Use ECS Fargate with a baseline of 2 tasks in production. Starting size for the ECS instance is a modest 0.5 vCPU and 1 GB of memory.
- Use RDS Multi-AZ for production and Single-AZ for staging.
- Use smaller ECS Fargate and RDS capacity for staging 
- Set CloudWatch log retention to 30 days.
- Use S3 lifecycle policies for old logs, exports, and temporary files.
- Use AWS Budgets and billing alarms for monitoring monthly cost. Tag resources by environment and service.
- Review Compute Savings Plans or Reserved Instances only after initial launch, and when traffic stabilizes.

## Security Considerations

### Identity and access control
The principle of least privilege must always apply, only providing a user or service with the minimal set of permissions to handle the job they need. 
ECS tasks use IAM roles rather than long-lived AWS access keys. These roles can only read data from the specific S3 bucket (or down to the path if relevant) that stores user content it needs, retrieve only required secrets from AWS Secrets Manager, and write logs to CloudWatch. Company employees access AWS via users and groups and production access is limited to a small group of users. MFA is enabled across the account.

### Network security
CloudFront is the application public entry point, funneling all incoming traffic. The ALB spans across public subnets, but is intended to receive API traffic from CloudFront only.
ECS tasks and the RDS database run in private subnets, and are not publicly accessible. RDS only accepts requests coming from the ECS security group.
S3 buckets block all direct public access.

### Data protection
Data is encrypted in transit using HTTPS between users and CloudFront, and also between CloudFront and the ALB.
Data at rest is encrypted for RDS, S3 and Secrets Manager using AWS-managed KMS keys.

### File upload and download security
User-uploaded files are a major attack vector, and must be secured appropriately.
All uploads and downloads will be done through a presigned URL generated by the backend, valid for a limited time only, so that user interactions with S3 are controlled.
File type is validated, and size limits enforced. 
Malware scanning can be discussed as an initial requirement or a future improvement.

### Monitoring and auditability

The application handles purchases and invoices, so auditability matters.
AWS CloudTrail tracks API calls made within AWS.
The application produces audit logs for sensitive business actions like purchases.

## Reliability Considerations

Availability of the system will be assured by:
- a frontend stored in S3, which has a 99.9999% availability;
- a backend served by 2 instances minimum at all times, if one fails it will be detected immediately via regular health checks, and replaced automatically by the autoscaling group;
- backend will be queried through a load balancer, which will spread out traffic evenly across available instances, in order not to overwhelm any one instance;
- alarms will trigger when instances become unresponsive, experience high CPU load, or when application code caused a crash;
- database data will be backed up every hour, and transaction logs will allow for a quick recovery time and a dataloss of less than 1 minute.

## Deployment Workflow

Terraform will be used to define the architecture using code, which makes it easy to version, track changes and rollback in case of issue.
Moreover, it will be easy to duplicate prod-like environments for dev and test purposes.
CI/CD pipelines in GitHub Actions will deploy a new version of the application every time a commit is pushed to the staging environment.
The pipelines will automatically run unit tests, build the application and generate a Docker image, push the image to ECR, and deploy it in ECS.

## Risks and Future Improvements

Below are improvements that can be done if the app is growing rapidly, or needs improved availability and resiliency:
- if traffic spikes are triggering ECS container outages, we can increase the computing power of each ECS instance easily (vertical scaling), or add more instance in the auto scaling group (horizontal scaling);
- if the DB is receiving too many connections at once, the backend connection pool can be configured accordingly;
- if the DB is receiving too many read requests, ElastiCache for Redis can be added to immediately serve popular content without involving the DB at all;
- if the DB is receiving too many read/write requests, we can add read replicas to serve read traffic, and offload the main writer instance;
- if the DB needs to be even more resilient to failures and handle more traffic, we can deploy change the design to a Multi-AZ DB cluster deployment, which involves one writer instance and 2 reader instance, each in different AZs. In this case the application will need to consider data freshness when routing requests to the database;
- if the app needs to improve its availability globally, multi region active-active deployments, S3 global accelerator, a migration to Aurora Global database can be considered. No schema changes are needed since PostgreSQL is supported;

## Conclusion

The suggested architecture is appropriate for a small SaaS company that wants to launch a strong product while keeping cost low.
It is maintainable by a small team of engineers, and can easily be scaled up without code changes or important refactoring efforts.
It is using a mix of AWS-managed and self-managed services, but the team is not locked into one posture forever, and can decide to lean more towards either side with minimal efforts (migration to Aurora DB for less operational involment, or move to ECS EC2 for more control over the computing servers).
Reasonable and documented estimates have been used to size the initial architecture, which can be scaled up or down depending on actual growth.