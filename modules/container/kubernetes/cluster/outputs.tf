output aks_cluster_id {
  description = "Unique identifier of the AKS cluster"
  value = azurerm_kubernetes_cluster.cluster.id
}

output aks_cluster_name {
  description = "fully qualified name of the AKS cluster"
  value = azurerm_kubernetes_cluster.cluster.name
}

output aks_cluster_resource_group_name {
  description = "Name of the resource group owning the AKS cluster"
  value = azurerm_kubernetes_cluster.cluster.resource_group_name
}

output aks_managed_identity_id {
  description = "Unique identifier of user managed identity running the AKS cluster"
  value = azurerm_user_assigned_identity.control_plane.id
}

output aks_managed_identity_principal_id {
  description = "Principal ID of the user managed identity running the AKS cluster"
  value = azurerm_user_assigned_identity.control_plane.principal_id
}

output aks_managed_identity_client_id {
  description = "Client ID of the user managed identity running the AKS cluster"
  value = azurerm_user_assigned_identity.control_plane.client_id
}

output aks_loadbalancer_external_id {
  description = "Unique identifier of the external loadbalancer managed by the AKS cluster"
  value = data.azurerm_lb.external.id
}

output aks_loadbalancer_internal_id {
  description = "Unique identifier of the internal loadbalancer managed by the AKS cluster"
  value = var.internal_loadbalancer_enabled ? data.azurerm_lb.internal[0].id : ""
}
