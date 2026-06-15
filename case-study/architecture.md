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
- a staging environment should run beside the production one;
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

1. The user accesses the application through a custom domain managed in Route 53. The domain "justreadit.com" is pointing to the CloudFront distribution.
2. The request goes to CloudFront, which drops TLS, and one of two scenario can follow.
- If the request is for a static or cached asset, the response is served directly from cache or S3, and returned to the client.
- If the request is an API call (/api/*), it is forwarded to the ALB.
3. The ALB sees the request and routes it to one of the backend containers, depending on their health checks and the routing algorithm.
4. Backend container executes the desired endpoint logic, and can communicate with the DB or other internal services like S3 or Secrets Manager to complete the request.
5. The response is sent back to the client with HTTP 200 if all went well, or an error code and message if not.

## Proposed AWS Services

Route 53: 
Stores DNS records so that domain names can be translated to IP addresses.
It will store an A record connecting "justreadit.com" to the IP address of the CloudFront distribution that is the app entry point. 
AWS can take care of updating the record if the CloudFront IP ever changes.

CloudFront: 
CDN service that caches static assets in servers spread out across the world, close to end users.
It will be allowed to read for an origin S3 bucket in order to serve the static frontend web application, image files, and e-books.
At every request, it will evaluate if a fresh cached version exists and send it back immediately if so. If not, it will get a fresh copy and cache it for the next user.
Being close to end users means latency is low, and highly popular content will be served rapidly without needing to talk to backend services.
TLS is terminated at this point (HTTPS becomes HTTP), because the traffic is entering AWS backbone network and is secure and fast. 

S3: 
Storage for all types of files, like images, videos or text files.
It is durable and scales automatically.
It will be used to store the frontend website, images and e-books.
It is not publicly accessible, and is only allowed to talk to CloudFront and the backend services.
Users upload and download content via secured presigned URLs.
 
Application Load Balancer:
Dispatches incoming requests between the available backend containers. 
A simple algorithm to use for routing is sending the new request to the container with the least amount of request, or lowest CPU utilisation.
Works together with an auto-scaling group, in order to always keep the desired number of containers running.
It is performing regular health checks on every instance to make sure they are fit to receive traffic, and stop routing to unhealthy instance automatically.
Operates on a minimum of 2 AZs, which is designed for supported good availability.

ECS Fargate:
Runs the backend application within a container. Fargate mode means that AWS is provisionning, patching and managing the container themselves.
The backend app is configured to be built as a Docker image, which is stored in AWS Elastic Container Registry ECR.
It is then easy to pull the latest image from the repository, and run it within a container in ECS.
Depending on the scaling policy, several containers of the same backend application can be running in parallel.
ECS containers only accept requests coming from the ALB, and are in a private network which allows them to communicate with the DB securely.

RDS:
RDS PostgreSQL is the relational database, it is storing all the data needed by the application.
AWS manages routine maintenance tasks (patching / updates), but otherwise the company is responsible for scaling.
Storage scaling will be set to automatic.
Compute scaling will be simple at first, with only one writer instance. Automatic backups and transaction logging will be enabled to allow for a quick recovery time in case of failure.

Secrets Manager:
Secure vault that will be storing DB credentials and other API keys or secrets as needed.
Will rotate secrets periodically automatically, without requiring code changes in the application.

CloudWatch:
Monitors the entire AWS infrastructure via metrics and logs.
It will be configured to alert relevant employees in case of failure (emails, texts, or notification in company messaging app).

Terraform:
The infrastructure will be described entirely in a text file, using the Terraform tool and syntax.
It will be easy to track changes using version control, rollback changes, and deploy duplicate environments like staging.
It will also help while deploying the application automatically in CI/CD pipelines.

CI/CD:
The code will live in GitHub, and use GitHub Actions to automatically build and deploy a dev environment on each code change.

## Key Tradeoffs

CloudFront - Availability and performance VS simplicity
Adding CloudFront as entry point to the application adds some complexity, with one more moving part to worry about.
The benefits are multiple:
- lower latency because it is located geographically near end users, and maintain its own cache
- CloudFront is a global service managed by AWS. It is extremely difficult to overwhelm for malicious actors. Having it as entry point is a security and can make it easy to drop undesirable requests early on.

RDS VS DynamoDB - Relational VS no-SQL DBs
DynamoDB is extremely fast and easy to scale. It is using flexible schemas which make it easy to migrate data and iterate quickly.
However in this case, we expect our datapoints to have strong relationship between each other, and we prefer a tight and enforced schema definition. The nature of the data (users are linked to orders and invoices, writers are linked to e-books and so on) makes it appropriate to be handled in a relational database, as it is structured and won't completely change in the future.
Moreover, we wish to be able to perform analytics or complex queries on the data, which is less suitable with no-SQL databases.

ECS Fargate VS ECS self-managed EC2 - Cost VS Operational overhead
ECS can be configured to run with self-managed EC2 instances, which lowers the bill but comes with increasing operational overhead because the team has to manage the instances themselves. 
The team being small and the "self-managed" path was chosen for the DB, it makes sense to opt for the frictionless AWS-managed Fargate for the compute side.
If costs increase to much, it is not a huge effort to switch to ECS EC2 because the app is shipped as a Docker container already.

## Cost Assumptions

This section provides estimates about expected traffic and cost. Numbers are approximate and are meant to be order of magnitude rather than hard projections.

The architecture is designed for a SaaS product expected to reach 10,000 to 50,000 monthly active users within the first year.
Because monthly active users do not translate directly into infrastructure load, we are making the following assumptions:

- 10–25% of monthly users are active on a given day.
- Each daily active user has 1–2 sessions per day.
- Each session generates 25–50 API requests. (login / dashboard / fetch account details / list records)
- Peak traffic can reach 5–10x of average traffic, during a special event for example.
- Each API request generates 1–5 database reads on average.
- Only a minority of requests create or update data.

The following traffic estimates are calculated based on the upper limit of expected growth, 50k monthly active users:

- 50,000 monthly active users
- 12,500 daily active users (25% of 50k)
- 25,000 sessions per day (with 2 sessions per day)
- 1.25 million API requests per day (with 50 API requests per session)
- 37.5 million API requests per month (with 30 days per month)
- 15 average requests per second 
- 100–150 peak requests per second

The following storage estimates are based on these assumptions:
- store account data (1 per user) -> 1-5 KB
- store e-books metadata (2 per author/year) -> 5-10 KB * 2 = 20 KB 
- store reading lists (1 per user) -> 1-2 KB
- store reviews (10 per user/year) -> 2-4 KB * 10 = 40 KB
- store events (50 per user/year) -> 1-2 KB * 50 = 100 KB
- store audit logs (200 per user/year) -> 0.5-1 KB * 200 = 200 KB
- in total for one user per year, we end up eround ~400 KB

(calculation example for a "review" field: 500 characters + a user foreign key + a book foreign key + timestamps/status = 500 bytes + 16 + 16 + 16 = less than 1KB for a most basic review)

- 50,000 user profiles
- At ~400 KB per user -> 400 KB * 50000 = 20 GB of raw data per year
- Multiply by 2 to account for database indexes and overhead -> 2 * 20 GB = 40 GB per year of DB storage

For S3:

- 10% of 50k users are writers = 5000 writers
- Average e-book size is 2 MB, at 2 books per author per year -> 2 * 2 MB * 5000 = 20 GB
- For 5000 writers -> 4 MB * 5000 = 20 GB per year
- Total S3 storage per year -> 20 GB + 20 GB = 40 GB 

## Security Considerations

Security in AWS will be managed by:
- IAM permissions for who can access can make what API calls within AWS. The principle of least privilege must always apply, only providing a user or service with the minimal set of permissions to handle the job they need;
- Security groups and network access lists will be used to secure the network from unwelcome traffic;
- Private secrets must not be exposed in the app nor visible in the code, but will be stored in AWS Secrets Manager;
- Essential data will be backed up regularly, like S3 objects and database tables;

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
- if the DB needs to be even more resilient to failures, we can deploy it in multiple AZ;
- if the app needs to improve its availability globally, multi region active-active deployments, S3 global accelerator, a migration to Aurora Global database can be considered. No schema changes are needed since PostgreSQL is supported;

## Conclusion

The suggested architecture is appropriate for a small SaaS company that wants to launch a strong product while keeping cost low.
It is maintainable by a small team of engineers, and can easily be scaled up without code changes or important refactoring efforts.
It is using a mix of AWS-managed and self-managed services, but the team is not locked into one posture forever, and can decide to lean more towards either side with minimal efforts (migration to Aurora DB for less operational involment, or move to ECS EC2 for more control over the computing servers).
Reasonable and documented estimates have been used to size the initial architecture, which can be scaled up or down depending on actual growth.