#!/usr/bin/env just --justfile

_helm-repo:
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo update

_start-minikube:
	@if minikube status --profile webshop >/dev/null 2>&1; then \
		echo "Minikube is already running"; \
	else \
		echo "Starting Minikube..."; \
		minikube start --profile webshop --cpus=4 --memory=7917; \
	fi
#    minikube start --profile webshop --cpus=4 --memory=7917

_create-namespaces:
    @kubectl get namespace webshop-infra >/dev/null 2>&1 || kubectl create namespace webshop-infra
    @kubectl get namespace webshop-app >/dev/null 2>&1 || kubectl create namespace webshop-app
#    kubectl create namespace webshop-infra || true
#    kubectl create namespace webshop-app || true

_install-postgres:
    just _helm-repo
    @if helm status postgres -n webshop-infra >/dev/null 2>&1; then
        echo "PostgreSQL already installed";
    else
        helm install postgres bitnami/postgresql -f ./helm/postgres-values.yaml -n webshop-infra; \
        kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=postgres -n webshop-infra --timeout=120s; \
        echo "PostgreSQL installed successfully";
    fi
    @echo "Forwarding PostgreSQL port...";
    kubectl port-forward svc/postgres-postgresql 5432:5432 -n webshop-infra &

#    just _helm-repo
#    helm install postgres bitnami/postgresql -f ./helm/postgres-values.yaml -n webshop-infra
#    kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=postgres -n webshop-infra --timeout=120s
#    kubectl port-forward svc/postgres-postgresql 5432:5432 -n webshop-infra

#    helm upgrade --install postgres bitnami/postgresql -n webshop-infra \
#        --set auth.postgresPassword=postgrespass

#_install-kafka:
#    just _helm-repo
#    helm upgrade --install kafka bitnami/kafka -n webshop-infra \
#        --set listeners.client.protocol=PLAINTEXT \
#        --set allowPlaintextListener=true

setup:
    just _start-minikube
    just _create-namespaces
    just _install-postgres
    #just _install-kafka

stop:
    minikube stop --profile webshop

delete:
    minikube delete --profile webshop