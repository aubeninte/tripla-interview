# Tripla Interview Deliverables

## Prerequisites

Before running any command, please ensure the below is installed on your machine:
* Docker
* [Kind](https://kind.sigs.k8s.io/)
* [Helm](https://helm.sh/)
* [kubectl](https://kubernetes.io/docs/reference/kubectl/)
* curl

## Repo Structure

## Terraform Parse Service

The terraform parse service is written in python3 and use Flask/gunicorn to expose its API. A requirements.txt file is given for any local test and development.

A simple local test will be as follow:

```bash
cd ./terraform_parse_service
python3 -m pip install -r requirements.txt
python3 main.py

# In another terminal
curl -OJ -X POST http://localhost:8080/generate-bucket-config -H "Content-Type: application/json" -d '{"payload":{"properties":{"aws-region":"eu-west-1","acl":"private","bucket-name": "tripla-bucket"}}}'

# A tripla-bucket.tf should be downloaded from where you're running the curl
```

## Helm & Platform setup

This part will talk you through how to setup the whole platform to deploy the terraform parse service as well as a frontend (nginx) and a backend in a local kind cluster.

Run the following to get the helper:
```bash
make help
```

### Configuration & Variables

You can overwrite any of the following configuration of the Makefile (_e.g_ make build TAG=v0.0.2):

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `REGISTRY` | `aubenint` | Target container registry namespace / username |
| `IMAGE_NAME` | `terraform_parse_service` | Name of the parser application container image |
| `TAG` | `v0.0.1` | Target version tag used for builds and deployments |
| `PORT` | `8080` | Local port used for pure standalone Docker execution |
| `DOCKERFILE` | `Dockerfile` | Path to the project Dockerfile configuration |
| `CONTAINER_NAME` | `$(IMAGE_NAME)` | Runtime container name assigned during standalone local execution |
| `RUN_FLAGS` | `--rm` | Default runtime flags applied to the standalone container session |
| `TEST_CONTAINER_NAME`| `$(IMAGE_NAME)-test` | Temporary container name utilized during local validation loops |
| `ACL` | `private` | Default S3 bucket Access Control List parameter used during testing |
| `CLUSTER_NAME` | `tripla-cluster` | Naming identifier for the local Kind cluster infrastructure |
| `RELEASE_NAME` | `tripla-interview` | Release name assigned to the Helm template deployment |
| `CHART_PATH` | `./helm` | Relative path pointing to the local Helm chart manifests |
| `FRONTEND_LOCAL_PORT`| `8080` | Local host port bound to the frontend service port-forward tunnel |
| `BACKEND_LOCAL_PORT` | `8082` | Local host port bound to the backend service port-forward tunnel |
| `PARSER_LOCAL_PORT` | `8081` | Local host port bound to the terraform parser service port-forward tunnel |

### Local Build

These commands let you test the parser service locally without spinning up a Kubernetes cluster:

```bash
# Build the Docker container image locally
make build

# Launch the container in the foreground on http://localhost:8080
make run

# Build, start the application in the background, run integration tests via curl, and clean up
make test

# Push the locally built tag to the configured container registry
make publish

# Clean up the built image from the local Docker daemon cache
make clean
```

### Kubernetes build

These commands automate cluster provisioning, local image injection, manifest templates deployment, and end-to-end integration connectivity verification. You'll need kind.

```bash
# Delete existing clusters, Build the cluster and deploy the manifests/applications
make platform-setup
```

Below are the testing commands:

```bash
# Validate everything sequentially across all three applications (Frontend, Backend, Parser)
make test-all

# Port-forward and validate the Nginx frontend app (default port: 8080)
make test-frontend

# Port-forward and validate the HTTP echo backend app (default port: 8082)
make test-backend

# Port-forward and fetch a terraform file from the parser app (default port: 8081)
# It will give you a file as shown in the ./example_outputs folder
make test-terraform-parse-service
```

## Terraform Deliverables
