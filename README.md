# ralphkube
Playing w/ minikube

## Makefile usage

Run `make help` to list all available targets with descriptions.

### Targets
- **help**: Show available targets.
- **colima-start/stop/status**: Manage the Colima runtime.
- **docker-context-colima/current**: Switch/show Docker context (use `colima`).
- **minikube-start**: Start the Minikube cluster using the Docker driver (Colima).
- **minikube-stop**: Stop the Minikube cluster.
- **minikube-status**: Show Minikube status.
- **minikube-dashboard**: Print the dashboard URL.
- **kube-apply**: Apply Kubernetes manifests in `./manifests` to a namespace.
- **kube-delete**: Delete Kubernetes manifests in `./manifests` from a namespace.
- **docker-env**: Prints the command to switch your shell to Colima's Docker context.
- **docker-build**: Build a Docker image using the current Docker context (Colima).

### Variables
You can override these when invoking `make`:
- **NAMESPACE**: Kubernetes namespace for `kube-apply`/`kube-delete` (default: `default`).
- **IMAGE**: Image name for `docker-build` (default: `ralphkube/app`).
- **TAG**: Image tag for `docker-build` (default: `latest`).
- **DOCKERFILE**: Dockerfile path for `docker-build` (default: `Dockerfile`).
- **CONTEXT**: Build context for `docker-build` (default: `.`).

### Examples
```bash
# List targets
make help

# Start Colima, switch Docker context, then start Minikube and open dashboard
make colima-start
make docker-context-colima
make minikube-start
make minikube-dashboard

# Ensure your Docker CLI points to Colima
docker context show

# Build image using Colima Docker
make docker-build IMAGE=ralphkube/app TAG=dev

# Apply/delete manifests to a namespace
make kube-apply NAMESPACE=dev
make kube-delete NAMESPACE=dev
```

Notes:
- `kube-apply` and `kube-delete` expect Kubernetes YAMLs under the `./manifests` directory.
- `minikube-start` uses `--driver=docker` and will use whatever Docker context your CLI is set to; ensure it is `colima`.
- `docker-env` does not switch your shell automatically; it prints the command so you can choose to run it.
