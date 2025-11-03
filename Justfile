#set shell := ["bash", "-cu"]

CONTEXT := 'nakupify-platform'
NAMESPACE := 'default'
ENV := 'minikube'
RELEASE := 'nakupify'

default:
    @just --choose

# Single command that does everything: checks requirements, starts minikube, deploys all services
start:
    just _requirements
    just _helmRepositories
    just _minikubeStart {{ CONTEXT }}
    just _deployAll {{ CONTEXT }} {{ NAMESPACE }} {{ ENV }}
    just _waitForServices {{ CONTEXT }} {{ NAMESPACE }}
    @echo "✨ All services ready!"
    just _connectTelepresence


stop:
     just _disconnectTelepresence
     just _minikubeStop {{CONTEXT}}

delete:
    just _disconnectTelepresence
    just _minikubeDelete {{CONTEXT}}

# ============================================================================
# PRIVATE: Requirements & Setup
# ============================================================================

_requirements:
    just _checkIfInstalled "docker"
    just _checkIfInstalled "kubectl"
    just _checkIfInstalled "minikube"
    just _checkIfInstalled "helm"
    just _checkIfInstalled "telepresence"

_minikubeStart context:
    minikube start --profile {{ context }} \
        --cpus 4 \
        --memory 7g \
        --network=bridged \
        --no-vtx-check || true
    minikube update-context -p {{ context }}
    @echo "✅ Minikube started"

_minikubeStop context:
    @echo "⛔ Stopping minikube..."
    minikube stop --profile {{ context }}

_minikubeDelete context:
    @echo "⚠️  Deleting minikube cluster..."
    minikube delete --profile {{ context }}

_helmRepositories:
    @echo " Adding Helm repositories..."
    helm repo add cnpg https://cloudnative-pg.github.io/charts || true
    helm repo add strimzi https://strimzi.io/charts/ || true
    helm repo update

_k8sContext context:
    kubectl config use-context {{ context }} > /dev/null 2>&1 || true

_checkIfInstalled command:
    @if ! command -v {{ command }} 2>&1 >/dev/null; then \
        echo "❌ {{ command }} could not be found. Please install it."; \
        exit 1; \
    fi

# ============================================================================
# PRIVATE: Deployment
# ============================================================================

_connectTelepresence:
    @echo "🔗 Connecting Telepresence..."
    telepresence helm install --namespace default || true
    telepresence connect --namespace default --mapped-namespaces all

_disconnectTelepresence:
    @echo "🔌 Disconnecting Telepresence..."
    telepresence quit || true

_deployAll context namespace env: (_k8sContext context)
    @echo " Setting up Kubernetes..."
    kubectl create namespace {{ namespace }} || true

    @echo " Updating Helm chart dependencies..."
    helm dependency update helm/ 2>/dev/null || true

    helm upgrade --install {{ RELEASE }} ./helm/infra-components \
        -f ./helm/infra-components/values.yaml \
        -n {{ namespace }} \
        --create-namespace \
        --wait \
        --timeout 10m

    sleep 5

    kubectl apply -f ./helm/manifests/postgres-cluster-secret.yaml

    just _applyManifests

_applyManifests:
    kubectl apply -f ./helm/manifests/postgres-cluster.yaml
    kubectl apply -f ./helm/manifests/kafka-cluster.yaml
    kubectl apply -f ./helm/manifests/kafka-nodepool.yaml

_waitForServices context namespace: (_k8sContext context)
    @echo "⏳ Waiting for all services to be ready..."

    @echo "  ⌛ Postgres..."
    kubectl wait --for=condition=ready pod \
        -l app.kubernetes.io/name=postgresql \
        -n {{ namespace }} \
        --timeout=300s 2>/dev/null || true

    @echo "  ⌛ Kafka..."
    kubectl wait --for=condition=ready pod \
        -l app.kubernetes.io/name=kafka \
        -n {{ namespace }} \
        --timeout=300s 2>/dev/null || true

_waitForPostgres NAMESPACE:
    @echo "⏳ Waiting for Postgres to be ready..."
    @kubectl wait --for=condition=ready pod \
        -l app.kubernetes.io/name=postgresql \
        -n {{ NAMESPACE }} \
        --timeout=300s 2>/dev/null || \
    (echo "❌ Postgres failed to start" && exit 1)
    @echo "✅ Postgres is ready"
