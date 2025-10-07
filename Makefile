# Makefile for ralphkube

SHELL := /bin/bash

# Defaults (override via `make TARGET VAR=value`)
NAMESPACE ?= default
IMAGE ?= flask-app
TAG ?= latest
DOCKERFILE ?= images/Dockerfile
CONTEXT ?= .
DOCKER_CONTEXT ?= colima
MANIFESTS_DIR ?= k8s

.PHONY: help minikube-start minikube-stop minikube-status minikube-dashboard minikube-metrics-enable minikube-metrics-disable minikube-metrics-status kube-apply kube-delete docker-build docker-env colima-start colima-stop colima-status docker-context-colima docker-context-current app-build app-load app-deploy app-undeploy app-status app-logs app-port-forward app-service-url deploy-all deploy-dev cleanup-all cleanup-dev status port-forward-status

.DEFAULT_GOAL := help

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nAvailable targets:\n\n"} /^[a-zA-Z0-9_-]+:.*##/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n%s\n", substr($$0,5) } ' $(MAKEFILE_LIST)

##@ Colima
colima-start: ## Start Colima runtime
	colima start

colima-stop: ## Stop Colima runtime
	colima stop

colima-status: ## Show Colima status
	colima status || true

docker-context-colima: ## Switch Docker context to $(DOCKER_CONTEXT)
	docker context use $(DOCKER_CONTEXT)

docker-context-current: ## Show current Docker context
	docker context show

##@ Minikube
minikube-start: ## Start minikube with Docker driver (uses Colima Docker context)
	minikube start --driver=docker --container-runtime=containerd --addons=metrics-server

minikube-stop: ## Stop minikube cluster
	minikube stop

minikube-status: ## Show minikube status
	minikube status

minikube-dashboard: ## Open minikube dashboard
	minikube dashboard --url

minikube-metrics-enable: ## Enable metrics-server addon
	minikube addons enable metrics-server
	@echo "Waiting for metrics-server rollout..."
	kubectl -n kube-system rollout status deploy/metrics-server --timeout=120s || true

minikube-metrics-disable: ## Disable metrics-server addon
	minikube addons disable metrics-server

minikube-metrics-status: ## Check metrics availability (nodes and all pods)
	- kubectl top nodes
	- kubectl top pods -A

kube-apply: ## Apply Kubernetes manifests under $(MANIFESTS_DIR) to $(NAMESPACE)
	kubectl apply -f $(MANIFESTS_DIR)/ --namespace=$(NAMESPACE)

kube-delete: ## Delete Kubernetes manifests under $(MANIFESTS_DIR) from $(NAMESPACE)
	kubectl delete -f $(MANIFESTS_DIR)/ --namespace=$(NAMESPACE) || true

##@ Docker
docker-env: ## Print command to switch to Colima Docker context
	@echo "To switch your Docker context to Colima, run:"
	@echo 'docker context use $(DOCKER_CONTEXT)'

docker-build: ## Build image using current Docker context (Colima): IMAGE, TAG, DOCKERFILE, CONTEXT
	@echo "Building $(IMAGE):$(TAG) using $(DOCKERFILE) in $(CONTEXT)"
	docker build -t $(IMAGE):$(TAG) -f $(DOCKERFILE) $(CONTEXT)

##@ Application Deployment
app-build: ## Build the application Docker image
	@echo "Building $(IMAGE):$(TAG) for deployment"
	$(MAKE) docker-build IMAGE=$(IMAGE) TAG=$(TAG)

app-load: ## Load the application image into minikube
	@echo "Loading $(IMAGE):$(TAG) into minikube"
	minikube image load $(IMAGE):$(TAG)

app-deploy: ## Deploy the application to minikube (build, load, apply manifests)
	@echo "Deploying $(IMAGE):$(TAG) to minikube"
	$(MAKE) app-build
	$(MAKE) app-load
	$(MAKE) kube-apply
	@echo "Waiting for deployment to be ready..."
	kubectl rollout status deployment/flask-app --timeout=120s || true

app-undeploy: ## Remove the application from minikube
	@echo "Undeploying application from minikube"
	$(MAKE) kube-delete

app-status: ## Show application deployment status
	@echo "=== Deployment Status ==="
	kubectl get deployments 2>/dev/null || echo "No deployments found or minikube not running"
	@echo ""
	@echo "=== Pod Status ==="
	kubectl get pods -l app=flask-app 2>/dev/null || echo "No pods found or minikube not running"
	@echo ""
	@echo "=== Service Status ==="
	kubectl get services -l app=flask-app 2>/dev/null || echo "No services found or minikube not running"

app-logs: ## Show application logs (follow mode)
	kubectl logs -f deployment/flask-app

app-port-forward: ## Port forward the application service to localhost:8080
	@echo "Port forwarding flask-app-service to localhost:8080"
	@echo "Access the app at: http://localhost:8080"
	@echo "Press Ctrl+C to stop port forwarding"
	kubectl port-forward service/flask-app-service 8080:5050

app-service-url: ## Get the minikube service URL for external access
	@echo "Getting minikube service URL..."
	minikube service flask-app-service --url

deploy-all: ## Complete deployment: start colima, start minikube, deploy app, port-forward, show status
	@echo "Starting complete deployment process..."
	@echo "Starting Colima runtime..."
	$(MAKE) colima-start
	@echo ""
	@echo "Starting minikube..."
	$(MAKE) minikube-start
	@echo ""
	@echo "Deploying application..."
	$(MAKE) app-deploy
	@echo ""
	@echo "=== Deployment Complete ==="
	$(MAKE) app-status
	@echo ""
	@echo "Setting up port forwarding..."
	@echo "Access the application at: http://localhost:8080"
	@echo "Press Ctrl+C to stop port forwarding and exit"
	@echo ""
	$(MAKE) app-port-forward

deploy-dev: ## Development deployment: deploy with port forwarding
	@echo "Starting development deployment..."
	@echo "This will deploy the app and start port forwarding"
	@echo ""
	$(MAKE) deploy-all || (echo "Deployment failed, cleaning up..." && $(MAKE) cleanup-all && exit 1)
	@echo ""
	@echo "=== Development Mode ==="
	@echo "Press Ctrl+C to stop port forwarding"
	@echo "Run 'make cleanup-dev' to clean up all resources when done"
	@echo ""
	$(MAKE) app-port-forward

cleanup-all: ## Complete cleanup: stop port-forward, undeploy app, stop minikube, stop colima
	@echo "Starting complete cleanup process..."
	@echo "Stopping any active port forwarding..."
	@pkill -f "kubectl port-forward" 2>/dev/null || echo "No port forwarding processes found"
	@echo ""
	@echo "Undeploying application..."
	$(MAKE) app-undeploy
	@echo ""
	@echo "Stopping minikube..."
	$(MAKE) minikube-stop
	@echo ""
	@echo "Stopping Colima runtime..."
	$(MAKE) colima-stop
	@echo ""
	@echo "=== Cleanup Complete ==="
	@echo "All resources have been cleaned up: port forwarding stopped, deployment removed, minikube and Colima stopped."

cleanup-dev: ## Development cleanup: same as cleanup-all (alias for convenience)
	@echo "Running development cleanup..."
	$(MAKE) cleanup-all



status: ## Show full development environment status (Colima, Docker, Minikube, Kubernetes, App)
	@echo "=== Docker Context ==="
	docker context show || true
	@echo ""
	@echo "=== Colima Status ==="
	colima status || true
	@echo ""
	@echo "=== Minikube Status ==="
	minikube status || true
	@echo ""
	@echo "=== Kubernetes Context ==="
	kubectl config current-context 2>/dev/null || echo "kubectl not configured or cluster not running"
	@echo ""
	@echo "=== Cluster Nodes ==="
	kubectl get nodes 2>/dev/null || echo "No nodes found or cluster not running"
	@echo ""
	@echo "=== Namespaces ==="
	kubectl get ns 2>/dev/null || echo "Cannot list namespaces"
	@echo ""
	@echo "=== Metrics (if available) ==="
	- kubectl top nodes
	- kubectl top pods -A
	@echo ""
	@echo "=== Port Forward Status ==="
	- $(MAKE) port-forward-status
	@echo ""
	@echo "=== Application ==="
	$(MAKE) app-status

port-forward-status: ## Check status of kubectl port-forward for flask-app-service on localhost:8080
	@echo "Checking for kubectl port-forward process..."
	@pgrep -fl "kubectl port-forward.*flask-app-service.*8080:5050" >/dev/null 2>&1 \
		&& pgrep -fl "kubectl port-forward.*flask-app-service.*8080:5050" \
		|| echo "No matching kubectl port-forward process running"
	@echo ""
	@echo "Checking if port 8080 is listening locally..."
	@if command -v lsof >/dev/null 2>&1; then \
		if lsof -nP -iTCP:8080 -sTCP:LISTEN >/dev/null 2>&1; then \
			lsof -nP -iTCP:8080 -sTCP:LISTEN; \
		else \
			echo "ERROR: Port 8080 is not listening locally"; \
			exit 1; \
		fi; \
	elif command -v nc >/dev/null 2>&1; then \
		if nc -z localhost 8080 >/dev/null 2>&1; then \
			echo "Port 8080 is listening (checked via nc)"; \
		else \
			echo "ERROR: Port 8080 is not listening locally"; \
			exit 1; \
		fi; \
	else \
		echo "ERROR: Neither lsof nor nc available to check port 8080"; \
		exit 1; \
	fi

