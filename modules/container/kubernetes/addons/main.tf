module aad_pod_identity {
  source = "../addon/aad-pod-identity"
  region_name = var.region_name
  region_code = var.region_code
  resource_group_name = var.resource_group_name
  resource_group_location = var.resource_group_location
  solution_name = var.solution_name
  solution_stage = var.solution_stage
  solution_fqn = var.solution_fqn
  common_tags = var.common_tags
  aks_cluster_id = var.aks_cluster_id
  addon_enabled = var.addon_aad_pod_identity_enabled
}
