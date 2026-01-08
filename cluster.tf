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
  type        = string
  nullable    = false
  # validation {
  #   condition     = regex("^.+$")
  #   error_message = "The app_name variable must not be empty."
  # }
}

####################################
# Helm provider with OCI registries
####################################

variable "ghcr_token" {
  description = "GitHub Container Registry token for authentication"
  type        = string
  sensitive   = true
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }

  registries = [
    {
      url      = "oci://ghcr.io/rso-2024-group-12/"
      username = "rso-2024-group-12"
      password = var.ghcr_token
    },
  ]
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

#######################################
# ArgoCD installation
#######################################

variable "argo_config_values_path" {
  type        = string
  description = "Path to init values file for ArgoCD"
  default     = "./argo-cd-values.yaml"
}

variable "github_app_key_path" {
  type = string
}

variable "argocd_namespace" {
  type = string
  default = "argocd"
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  cleanup_on_fail  = true
  version          = "9.2.4"
  namespace        = var.argocd_namespace
  create_namespace = true
  # upgrade_install  = true
  wait             = true
  wait_for_jobs    = true
  values           = [
    file(var.argo_config_values_path)
  ]
  set_sensitive = [{
    name  = "configs.credentialTemplates.github-repos.githubAppPrivateKey"
    type  = "string"
    value = file(var.github_app_key_path)
    }, {
    name  = "configs.repositories.ghcr-helm.password"
    type  = "string"
    value = var.ghcr_token
    }
  ]
}

# data "helm_template" "argo_cd_initial_app_deploy" {
#   name = "argo-cd-configs"
#   chart = "./argo-cd-configs"
#   namespace = var.argocd_namespace
#   devel = true # to ignore all versions and just install from filepath
# }

# resource "kubernetes_manifest" "apply_initial_configs" {
#   depends_on = [ data.helm_template.argo_cd_initial_app_deploy ]
#   manifest = 
# }

# resource "helm_release" "argocd-config" {
#   name             = "argocd-config"
#   chart            = "argo-cd-configs"
#   repository       = "oci://ghcr.io/rso-2024-group-12/"
#   version          = "0.1.1"
#   namespace        = "argocd"
#   create_namespace = false
#   atomic           = true
#   set = [{
#     name  = "githubAppInfo.privateKey"
#     type  = "string"
#     value = file(var.github_app_key_path)
#   }]
#   depends_on = [helm_release.argocd]
# }
