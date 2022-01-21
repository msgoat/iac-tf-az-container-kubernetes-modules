locals {
  user_node_group_names = [for ng in var.user_node_groups : ng.name]
  user_node_groups_by_name = zipmap(local.user_node_group_names, var.user_node_groups)
}

# create a user node group or user pool
resource azurerm_kubernetes_cluster_node_pool user_node_group {
  for_each = local.user_node_groups_by_name
  name = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.cluster.id
  mode = "User"
  vm_size = each.value.vm_sku
  availability_zones = ["1", "2", "3"]
  enable_auto_scaling = true
  max_count = each.value.max_size
  min_count = each.value.min_size
  node_count = each.value.desired_size
  orchestrator_version = each.value.kubernetes_version
  os_disk_size_gb = each.value.os_disk_size
  os_type = "Linux"
  priority = each.value.priority == "Spot" ? each.value.priority : "Regular"
  spot_max_price = each.value.priority == "Spot" ? each.value.spotPrice : null
  eviction_policy = each.value.priority == "Spot" ? "Delete" : null
  vnet_subnet_id = var.node_groups_subnet_id
  node_labels = each.value.labels
  node_taints = each.value.taints
  tags = merge({ Name = "np-${var.region_code}-${local.cluster_name}-${each.key}"}, local.module_common_tags)

  upgrade_settings {
    max_surge = each.value.max_surge
  }
  lifecycle {
    ignore_changes = [
      node_count, # node count may be changed by cluster autoscaler
      orchestrator_version # kubernetes version may be changed by azure cli or portal
    ]
  }
}
