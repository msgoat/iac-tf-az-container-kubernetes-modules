data azurerm_kubernetes_cluster cluster {
  name = var.aks_name
  resource_group_name = var.resource_group_name
}

locals {
  aks_host                   = data.azurerm_kubernetes_cluster.cluster.kube_config.0.host
  aks_username               = data.azurerm_kubernetes_cluster.cluster.kube_config.0.username
  aks_password               = data.azurerm_kubernetes_cluster.cluster.kube_config.0.password
  aks_client_certificate     = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)
  aks_client_key             = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)
  aks_cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)
}
