# NOTES

## API Service - Terraform Parse Service

For this application I chose Python 3 with Flask for the API, Gunicorn for running it in the container, Pydantic for request validation, and Jinja2 for rendering Terraform.

The service exposes `POST /generate-bucket-config`. It receives the required payload, validates the nested structure and dashed keys like `aws-region` and `bucket-name`, then passes the values into a Terraform template. The response is returned as a downloadable `.tf` file, so a user can call the endpoint with `curl -OJ` and directly receive something like `tripla-bucket.tf`.

The generated Terraform includes the AWS provider, `aws_s3_bucket`, and `aws_s3_bucket_acl`. For private buckets, I also added safer defaults such as ownership controls, public access blocking, server-side encryption, and versioning.

As an improvment here, I could add python unit testing that could run in a CI (Github Action or gitlab...) to validate the code and integration testing could use the makefile command in a CI environment. I intentionally let the unit test having a warning to prove the test can catch warnings as well as passing the 2 current unit tests.

## Terraform

The Terraform folder is structured with separate environment roots and shared modules:

```text
terraform/
|-- environments/
|   |-- preprod/
|   `-- prod/
`-- modules/
    |-- eks/
    `-- s3/
```

This keeps preprod and prod isolated - which was not the case with the provided code - while still reusing common module code. Both environments use the AWS provider `~> 6.0` and Terraform CLI `>= 1.13.0`. Preprod uses the latest supported EKS version for early validation, while prod uses latest version minus one for stability.

The main improvements were fixing the environment/module wiring, making prod and preprod values explicit, securing the S3 module with public access blocking, preventing accidental prod bucket deletion with `force_destroy = var.environment != "prod"`, and exposing useful EKS outputs.

What could still be improved: remote state and locking (see [README.md](./README.md#terraform-deliverables)), CI-based `terraform plan`, stronger variable validation, replacing placeholder VPC/subnet IDs with a real network module, and making private/public endpoint access configurable per environment. We can also improve by adding a kubernetes provider to do some bootstrap config on the cluster if needed (like install ArgoCD) and get a context once the cluster has been created.

## Helm

The Helm chart deploys the frontend, backend, and Terraform parser service. I split templates by component to make the chart easier to read:

```text
helm/templates/
|-- backend/
|-- frontend/
`-- terraform_parse_service/
```

The main fixes were moving values out of hardcoded templates and into `values.yaml`: images, tags (**avoid using latest**), service types, ports, replica counts, resources, and backend HPA settings. The parser service has its own deployment and service, and the backend HPA only renders when enabled and when the metrics API is available.

At larger scale, I would likely split these unrelated applications into separate Helm charts so they can be versioned, released, and owned independently.

Validation was done with `helm template tripla-interview ./helm`, and the Makefile provides Kind-based checks through `platform-setup`, `test-frontend`, `test-backend`, and `test-terraform-parse-service`.

## System Behavior

The parser service is stateless and lightweight. Each request validates JSON, renders a small template, and returns a file. That means it should scale well horizontally by **increasing Kubernetes replicas**.

Under load, the likely bottlenecks would be Gunicorn worker/thread count, pod CPU, and request concurrency. In failure scenarios, invalid payloads return validation errors, failed pods can restart, and `/healthz` is available for health checks.

Longer term, I would add readiness/liveness probes in Helm, structured logs, metrics, autoscaling for the parser service using something like **KEDA to scale based on custom metrics**, rate limiting, stronger payload validation, and CI tests that verify the generated Terraform remains valid.

## Approach and Tools

I approached the task in layers. First I built the API to satisfy the core prompt: receive a payload, validate it, generate Terraform, and return a `.tf` file. Then I containerized it with a multi-stage Dockerfile and added Makefile targets for repeatable local testing.

After that, I reviewed and improved the Terraform layout so it looked like a realistic preprod/prod setup with reusable modules. Finally, I reviewed the Helm chart, made the templates more values-driven, added the parser deployment, and wired Makefile commands for local Kind validation.

The main tools used were Python, Flask, Pydantic, Jinja2, Docker, Make, Helm, Kubernetes/Kind, Terraform, and curl. I used static checks such as Python compilation, `terraform fmt -check -recursive terraform`, and `helm template` to validate changes without needing real AWS infrastructure.

### Use of AI

I used AI in this exercise as an English linter for README and NOTES. I also use it to verify Flask structure and functions layout.
