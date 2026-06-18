REGISTRY ?= aubenint
IMAGE_NAME ?= terraform_parse_service
TAG ?= v0.0.1
PORT ?= 8080
DOCKERFILE ?= Dockerfile
CONTAINER_NAME ?= $(IMAGE_NAME)
RUN_FLAGS ?= --rm
TEST_CONTAINER_NAME ?= $(IMAGE_NAME)-test
ACL ?= private

.PHONY: help build run test publish clean

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

test: build ## Build, start the app, test it, and download the generated Terraform file
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
