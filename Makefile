# Makefile for ralphkube

SHELL := /bin/bash

# Defaults (override via `make TARGET VAR=value`)
NAMESPACE ?= default
IMAGE ?= ralphkube/app
TAG ?= latest
DOCKERFILE ?= Dockerfile
CONTEXT ?= .
DOCKER_CONTEXT ?= colima

.PHONY: help minikube-start minikube-stop minikube-status minikube-dashboard minikube-metrics-enable minikube-metrics-disable minikube-metrics-status kube-apply kube-delete docker-build docker-env colima-start colima-stop colima-status docker-context-colima docker-context-current

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

kube-apply: ## Apply Kubernetes manifests under ./manifests to $(NAMESPACE)
	kubectl apply -f manifests/ --namespace=$(NAMESPACE)

kube-delete: ## Delete Kubernetes manifests under ./manifests from $(NAMESPACE)
	kubectl delete -f manifests/ --namespace=$(NAMESPACE) || true

##@ Docker
docker-env: ## Print command to switch to Colima Docker context
	@echo "To switch your Docker context to Colima, run:"
	@echo 'docker context use $(DOCKER_CONTEXT)'

docker-build: ## Build image using current Docker context (Colima): IMAGE, TAG, DOCKERFILE, CONTEXT
	@echo "Building $(IMAGE):$(TAG) using $(DOCKERFILE) in $(CONTEXT)"
	docker build -t $(IMAGE):$(TAG) -f $(DOCKERFILE) $(CONTEXT)


