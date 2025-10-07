# ralphkube
A Flask application deployment project using Minikube and Colima for local Kubernetes development.

## Project Structure
```
ralphkube/
├── images/           # Application source code and Docker configuration
│   ├── app.py       # Flask application
│   ├── Dockerfile   # Container image definition
│   └── requirements.txt
├── k8s/             # Kubernetes manifests
│   ├── deployment.yaml
│   └── service.yaml
├── Makefile         # Build and deployment automation
└── README.md        # This file
```

## Application
The project includes a simple Flask application with:
- **Health endpoint**: `/health` - Returns "up" status
- **Hello endpoint**: `/hello` - Returns JSON greeting
- **Port configuration**: Configurable via `PORT` environment variable (default: 5050)

## Makefile Usage

Run `make help` to list all available targets with descriptions.

### Target Categories

#### Colima Management
- **colima-start**: Start Colima runtime
- **colima-stop**: Stop Colima runtime  
- **colima-status**: Show Colima status
- **docker-context-colima**: Switch Docker context to Colima
- **docker-context-current**: Show current Docker context

#### Minikube Management
- **minikube-start**: Start minikube with Docker driver (uses Colima Docker context)
- **minikube-stop**: Stop minikube cluster
- **minikube-status**: Show minikube status
- **minikube-dashboard**: Open minikube dashboard
- **minikube-metrics-enable**: Enable metrics-server addon
- **minikube-metrics-disable**: Disable metrics-server addon
- **minikube-metrics-status**: Check metrics availability (nodes and all pods)

#### Kubernetes Operations
- **kube-apply**: Apply Kubernetes manifests under `k8s/` to specified namespace
- **kube-delete**: Delete Kubernetes manifests under `k8s/` from specified namespace

#### Docker Operations
- **docker-env**: Print command to switch to Colima Docker context
- **docker-build**: Build image using current Docker context (Colima)

#### Application Deployment
- **app-build**: Build the application Docker image
- **app-load**: Load the application image into minikube
- **app-deploy**: Deploy the application to minikube (build, load, apply manifests)
- **app-undeploy**: Remove the application from minikube
- **app-status**: Show application deployment status
- **app-logs**: Show application logs (follow mode)
- **app-port-forward**: Port forward the application service to localhost:8080
- **app-service-url**: Get the minikube service URL for external access

#### Complete Workflows
- **deploy-all**: Complete deployment: start colima, start minikube, deploy app, port-forward, show status
- **deploy-dev**: Development deployment: deploy with port forwarding
- **cleanup-all**: Complete cleanup: stop port-forward, undeploy app, stop minikube, stop colima
- **cleanup-dev**: Development cleanup: same as cleanup-all (alias for convenience)

### Variables
You can override these when invoking `make`:
- **NAMESPACE**: Kubernetes namespace for `kube-apply`/`kube-delete` (default: `default`)
- **IMAGE**: Image name for `docker-build` (default: `flask-app`)
- **TAG**: Image tag for `docker-build` (default: `latest`)
- **DOCKERFILE**: Dockerfile path for `docker-build` (default: `images/Dockerfile`)
- **CONTEXT**: Build context for `docker-build` (default: `.`)
- **DOCKER_CONTEXT**: Docker context to use (default: `colima`)
- **MANIFESTS_DIR**: Directory containing Kubernetes manifests (default: `k8s`)

### Quick Start Examples

#### Complete Development Setup
```bash
# One-command complete deployment with port forwarding
make deploy-dev

# Access the application at: http://localhost:8080
# Press Ctrl+C to stop port forwarding
# Run 'make cleanup-dev' when done
```

#### Manual Step-by-Step Deployment
```bash
# Start infrastructure
make colima-start
make docker-context-colima
make minikube-start

# Deploy application
make app-deploy

# Access application
make app-port-forward  # Port forward to localhost:8080
# OR
make app-service-url   # Get external minikube service URL
```

#### Development Workflow
```bash
# Check status
make app-status

# View logs
make app-logs

# Rebuild and redeploy after code changes
make app-deploy

# Clean up everything
make cleanup-all
```

#### Individual Operations
```bash
# List all available targets
make help

# Build image with custom tag
make docker-build IMAGE=my-app TAG=v1.0

# Deploy to custom namespace
make kube-apply NAMESPACE=staging

# Check metrics
make minikube-metrics-status
```

### Environment Status and Port-Forward Checks

The `Makefile` provides comprehensive status checks for your local dev environment and port forwarding.

#### Status (Aggregated)
```bash
make status
```
This prints:
- Docker context and Colima status
- Minikube status
- Kubernetes context, nodes, namespaces, and metrics (if metrics-server is enabled)
- Port-forward status for `flask-app-service` on `localhost:8080`
- Application deployment status (deployments, pods, services)

Notes:
- If port 8080 is not listening locally, you'll see: `ERROR: Port 8080 is not listening locally`.
- The `status` target logs the error but continues running the remaining checks.

#### Port-Forward Status (Standalone)
```bash
make port-forward-status
```
This checks:
- Whether a `kubectl port-forward service/flask-app-service 8080:5050` process is running
- Whether `localhost:8080` is listening (using `lsof`, falling back to `nc` if available)

Exit behavior:
- Returns non-zero exit code if 8080 is not listening (or neither `lsof` nor `nc` is available).
- Use the aggregated `make status` if you prefer the rest of the checks to continue even when this fails.

### Notes
- `kube-apply` and `kube-delete` expect Kubernetes YAMLs under the `k8s/` directory
- `minikube-start` uses `--driver=docker` and will use whatever Docker context your CLI is set to; ensure it is `colima`
- `docker-env` does not switch your shell automatically; it prints the command so you can choose to run it
- The application runs on port 5050 inside the container and is exposed via NodePort 30050
- Port forwarding maps the service to localhost:8080 for easy local access
