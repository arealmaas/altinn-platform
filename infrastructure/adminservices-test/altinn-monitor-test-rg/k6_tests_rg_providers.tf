/*
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  backend "azurerm" {
    use_azuread_auth = true
  }
}

provider "azurerm" {
  subscription_id = "1ce8e9af-c2d6-44e7-9c5e-099a308056fe"
  features {}
  resource_providers_to_register = [
    "Microsoft.Monitor",
    "Microsoft.AlertsManagement",
    "Microsoft.Dashboard",
    "Microsoft.KubernetesConfiguration"
  ]
}
*/
provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.k6tests.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.k6tests.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.k6tests.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.k6tests.kube_config[0].cluster_ca_certificate)
  }
}
