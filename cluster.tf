terraform {
  required_version = ">= 1.3"

  required_providers {
    # azurerm = {
    #   source  = "hashicorp/azurerm"
    #   version = "~> 3.0.2"
    # }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.11"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.7.1"
    }
  }
}

variable "app_name" {
  description = "Name of application, which will be used to create Kubernetes namespace"
  type = string
  nullable = false
  # validation {
  #   condition     = regex("^.+$")
  #   error_message = "The app_name variable must not be empty."
  # }
}

####################################
# Helm provider with OCI registries
####################################

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }

  # registries = [
  #   {
  #     url      = "oci://localhost:5000"
  #     username = "username"
  #     password = "password"
  #   },
  #   {
  #     url      = "oci://private.registry"
  #     username = "username"
  #     password = "password"
  #   }
  # ]
}


######################################
# Minikube
######################################

provider "kubernetes" {
  alias          = "minikube"
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

######################################
# Azure / AKS
######################################

# provider "azurerm" {
#   features {}
# }

# variable "aks_name" {
#   type = string
# }

# variable "aks_resource_group" {
#   type = string
# }

# data "azurerm_kubernetes_cluster" "aks" {
#   name                = var.aks_name
#   resource_group_name = var.aks_resource_group
# }


######################################
# Envoy Gateway API CRDs
######################################

### THINK WHERE TO INSTALL ENVOY. HERE OR WITH ARGOCD?

######################################
# OLM installation
######################################

# Try to use Helm chart at: https://github.com/operator-framework/operator-controller/tree/main/helm/olmv1
resource "null_resource" "install_olm" {
  provisioner "local-exec" {
    command = "chmod u+x ${path.module}/cluster-scripts/install-olm.sh && ${path.module}/cluster-scripts/install-olm.sh v0.38.0"
  }  
  lifecycle {
    prevent_destroy = false

  }
  
}

resource "kubernetes_namespace_v1" "nakupify" {
  provider = kubernetes.minikube
  metadata {
    name = var.app_name
  }
}

resource "helm_release" "nakupify_platform_operators" {
  name             = "nakupify-platform-operators"
  chart            = "${path.module}/nakupify-operators"
  namespace        = var.app_name
  create_namespace = false
  depends_on       = [ null_resource.install_olm, kubernetes_namespace_v1.nakupify ]
  wait = true
  cleanup_on_fail = true
  #upgrade_install = true
}

resource "helm_release" "nakupify_platform" {
  # provider = kubernetes.minikube
  name             = "nakupify-platform"
  chart            = "${path.module}/nakupify-platform"
  namespace        = var.app_name
  create_namespace = false
  depends_on       = [ helm_release.nakupify_platform_operators ]
  wait = true
  upgrade_install = true
  cleanup_on_fail = true
}

# resource "kubernetes_manifest" "nakupify_operator_group" {
#   provider = kubernetes.minikube
#   depends_on = [ null_resource.install_olm, kubernetes_namespace_v1.nakupify ]
#   manifest = yamldecode(<<EOF
# apiVersion: operators.coreos.com/v1
# kind: OperatorGroup
# metadata:
#   name: operatorgroup
#   namespace: ${var.app_name}
#   labels:
#     app.kubernetes.io/name: ${var.app_name}
#     app.kubernetes.io/instance: ${var.app_name}
#     app.kubernetes.io/part-of: ${var.app_name}
#     app.kubernetes.io/managed-by: terraform
# spec:
#   targetNamespaces:
#   - ${var.app_name}
# EOF
#   )
# }

# resource "kubernetes_manifest" "nakupify_keycloak_subscription" {
#   provider = kubernetes.minikube
#   depends_on = [ kubernetes_manifest.nakupify_operator_group ]
#   manifest = yamldecode(<<EOF
# apiVersion: operators.coreos.com/v1alpha1
# kind: Subscription
# metadata:
#   name: keycloak-operator
#   namespace: ${var.app_name}
#   labels:
#     app.kubernetes.io/name: ${var.app_name}
#     app.kubernetes.io/instance: ${var.app_name}
#     app.kubernetes.io/part-of: ${var.app_name}
#     app.kubernetes.io/managed-by: terraform
# spec:
#   channel: fast
#   name: keycloak-operator
#   source: operatorhubio-catalog
#   sourceNamespace: olm
# EOF
#   )
# }

# resource "kubernetes_manifest" "nakupify_postgresql_subscription" {
#   provider = kubernetes.minikube
#   depends_on = [ kubernetes_manifest.nakupify_operator_group ]
#   manifest = yamldecode(<<EOF
# apiVersion: operators.coreos.com/v1alpha1
# kind: Subscription
# metadata:
#   name: postgresql-operator
#   namespace: ${var.app_name}
#   labels:
#     app.kubernetes.io/name: ${var.app_name}
#     app.kubernetes.io/instance: ${var.app_name}
#     app.kubernetes.io/part-of: ${var.app_name}
#     app.kubernetes.io/managed-by: terraform
# spec:
#   channel: v5
#   name: postgresql
#   source: operatorhubio-catalog
#   sourceNamespace: olm
# EOF
#   )
# }

#######################################
# ArgoCD installation
#######################################

# resource "helm_release" "argocd" {
#   name = "argocd"
#   repository = "https://argoproj.github.io/argo-helm"
#   chart = "argo-cd"
#   cleanup_on_fail = true
#   version = "9.2.4"
#   namespace = "argocd"
#   create_namespace = true
# }

resource "helm_release" "argocd" {
  name = "argocd"
  repository = "file://${path.module}/argo-cd"
  chart = "argo-cd"
  cleanup_on_fail = true
  version = "0.1.0"
  namespace = "argocd"
  create_namespace = true
}