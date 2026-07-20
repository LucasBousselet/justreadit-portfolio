### CI/CD Deployment Notes

### App Packaging & Docker

- The API is running .NET 10.
- App running locally on port 7070 (HTTPS) and 5222 (HTTP), as defined in launchSettings.json. HTTP traffic redirected to HTTPS.
- Published ASP.NET Core running on Kestrel web server, listening on the port defined by env variable:

ASPNETCORE_URLS=http://+:<port_number>

JustReadIt API listens on 7070, as defined in the Dockerfile-Fargate file. Removing the environment variable from the Dockerfile and setting it in the ECS task definition is another solution to consider, if changing port without rebuilding the image becomes necessary.
Locally, Docker container forwards traffic on 7070:7070, so inbound traffic must reach port 7070. 
ECS Fargate uses `awsvpc` networking, in which we must specify the exposed `containerPort` in the task definition, which is 7070.

- API is built into a Docker image, and pushed to ECR. ECS service pulls the image directly and runs it as a new task.