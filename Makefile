REGISTRY ?= aubenint
IMAGE_NAME ?= terraform_parse_service
TAG ?= v0.0.1
PORT ?= 8080
DOCKERFILE ?= Dockerfile
CONTAINER_NAME ?= $(IMAGE_NAME)
RUN_FLAGS ?= --rm
TEST_CONTAINER_NAME ?= $(IMAGE_NAME)-test
ACL ?= private

# Variables for Kubernetes / Helm
CLUSTER_NAME ?= tripla-cluster
RELEASE_NAME ?= tripla-interview
CHART_PATH ?= ./helm
FRONTEND_LOCAL_PORT ?= 8080
BACKEND_LOCAL_PORT ?= 8082
PARSER_LOCAL_PORT ?= 8081

.PHONY: help build run test publish clean platform-setup test-all test-frontend test-backend test-terraform-parse-service

help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

build: ## Build the Docker image
	docker build -t $(REGISTRY)/$(IMAGE_NAME):$(TAG) -f $(DOCKERFILE) .

run: ## Run the container locally
	@echo "Starting service inside container on http://localhost:$(PORT)"
	docker run $(RUN_FLAGS) -p $(PORT):8080 --name $(CONTAINER_NAME) $(REGISTRY)/$(IMAGE_NAME):$(TAG)

test: build ## Build, start the app locally, test it, and download the generated Terraform file
	@set -e; \
	$(MAKE) run RUN_FLAGS="--rm -d" CONTAINER_NAME=$(TEST_CONTAINER_NAME); \
	trap 'docker stop $(TEST_CONTAINER_NAME) >/dev/null 2>&1 || true' EXIT; \
	sleep 2; \
	curl -OJ -X POST http://localhost:$(PORT)/generate-bucket-config \
		-H "Content-Type: application/json" \
		-d '{"payload":{"properties":{"aws-region":"eu-west-1","acl":"$(ACL)","bucket-name": "tripla-bucket"}}}'

publish: build ## Push the existing local Docker image tag to Docker Hub
	@echo "Pushing image $(REGISTRY)/$(IMAGE_NAME):$(TAG) to Docker Hub..."
	docker push $(REGISTRY)/$(IMAGE_NAME):$(TAG)

clean: ## Remove local docker image
	docker rmi $(REGISTRY)/$(IMAGE_NAME):$(TAG) || true

platform-setup: build ## Delete existing cluster if it exists, create a fresh Kind cluster, load local image, and deploy Helm chart manifests
	@echo "Checking for existing Kind cluster '$(CLUSTER_NAME)'..."
	@if kind get clusters | grep -q "^$(CLUSTER_NAME)$$" ; then \
		echo "Found existing cluster '$(CLUSTER_NAME)'. Deleting it for a clean setup..." ; \
		kind delete cluster --name $(CLUSTER_NAME) ; \
	fi
	@echo "Creating fresh Kind cluster '$(CLUSTER_NAME)'..."
	kind create cluster --name $(CLUSTER_NAME)
	@echo "Loading local image into Kind..."
	kind load docker-image $(REGISTRY)/$(IMAGE_NAME):$(TAG) --name $(CLUSTER_NAME)
	@echo "Applying Helm templates to the cluster..."
	helm template $(RELEASE_NAME) $(CHART_PATH) | kubectl apply -f -
	@echo "Waiting for deployments to stabilize..."
	kubectl wait --for=condition=available --timeout=60s deployment/$(RELEASE_NAME)-frontend
	kubectl wait --for=condition=available --timeout=60s deployment/$(RELEASE_NAME)-backend
	kubectl wait --for=condition=available --timeout=60s deployment/$(RELEASE_NAME)-terraform-parse

test-all: test-frontend test-backend test-terraform-parse-service ## Run all Kubernetes infrastructure integration tests sequentially

# Macro for handling safe port-forwarding pipelines
# Usage: $(call run-k8s-test, service_suffix, target_port, local_port, curl_command)
define run-k8s-test
	@echo "Starting port-forward tunnel for $(1)..."
	kubectl port-forward svc/$(RELEASE_NAME)-$(1) $(3):$(2) > /dev/null 2>&1 & \
	PF_PID=$$!; \
	trap 'kill $$PF_PID >/dev/null 2>&1 || true' EXIT; \
	sleep 1.5; \
	$(4)
endef

test-frontend: ## Port-forward frontend service, run curl validation, and clean up
	$(call run-k8s-test,frontend,80,$(FRONTEND_LOCAL_PORT),curl -sI http://localhost:$(FRONTEND_LOCAL_PORT) | head -n 1)

test-backend: ## Port-forward backend service, run curl validation, and clean up
	$(call run-k8s-test,backend,8080,$(BACKEND_LOCAL_PORT),curl -i http://localhost:$(BACKEND_LOCAL_PORT)/)

test-terraform-parse-service: PARSER_CURL = curl -OJ -X POST http://localhost:$(PARSER_LOCAL_PORT)/generate-bucket-config -H "Content-Type: application/json" -d '{"payload":{"properties":{"aws-region":"eu-west-1","acl":"$(ACL)","bucket-name": "tripla-bucket"}}}'
test-terraform-parse-service: ## Port-forward parse service, execute payload curl, and clean up
	$(call run-k8s-test,terraform-parse,8080,$(PARSER_LOCAL_PORT),$(PARSER_CURL))
	