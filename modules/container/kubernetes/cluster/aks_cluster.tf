locals {
  cluster_name = var.solution_fqn
  aks_addon_oms_agent_enabled = var.azure_monitor_enabled
}

# create a AKS cluster instance
resource azurerm_kubernetes_cluster cluster {
  name = "aks-${var.region_code}-${local.cluster_name}"
  resource_group_name = var.resource_group_name
  location = var.resource_group_location
  dns_prefix = local.cluster_name
  # IMPORTANT: we need to pin the kubernetes version, otherwise Azure will determine it!
  kubernetes_version = var.aks_version
  tags = merge({"Name" = "aks-${var.region_code}-${local.cluster_name}"}, local.module_common_tags)

  # defines the system node group or system pool
  default_node_pool {
    name = "system"
    vm_size = var.system_pool_vm_sku
    availability_zones = ["1", "2", "3"]
    enable_auto_scaling = true
    min_count = var.system_pool_min_size
    node_count = var.system_pool_desired_size
    max_count = var.system_pool_max_size
    enable_node_public_ip = false
    orchestrator_version = var.aks_version
    os_disk_size_gb = var.system_pool_os_disk_size
    type = "VirtualMachineScaleSets"
    vnet_subnet_id = var.node_groups_subnet_id
    only_critical_addons_enabled = true

    tags = merge({ Name = "np-${var.region_code}-${local.cluster_name}-system"}, local.module_common_tags)
    upgrade_settings {
      max_surge = var.node_group_upgrade_max_surge
    }
  }

  addon_profile {
    aci_connector_linux {
      enabled = false
    }
    azure_policy {
      enabled = var.aks_addon_azure_policy_enabled
    }
    http_application_routing {
      enabled = false
    }
    kube_dashboard {
      enabled = var.aks_addon_dashboard_enabled
    }
    oms_agent {
      enabled = local.aks_addon_oms_agent_enabled
      log_analytics_workspace_id = local.aks_addon_oms_agent_enabled ? var.log_analytics_workspace_id : null
    }
  }

  identity {
    # we bring our own identity which has all required role assignments
    type = "UserAssigned"
    user_assigned_identity_id = azurerm_user_assigned_identity.control_plane.id
  }

  network_profile {
    network_plugin = var.aks_network_plugin_type
    outbound_type = "loadBalancer"
    load_balancer_sku = "Standard"
    # all internally used IP addresses and IP address ranges must be set as variables!!!
    dns_service_ip = var.aks_dns_service_ip
    docker_bridge_cidr = var.aks_docker_bridge_cidr
    pod_cidr = var.aks_network_plugin_type == "kubenet" ? var.aks_pod_cidr : null
    service_cidr = var.aks_service_cidr
  }

  role_based_access_control {
    enabled = true
    /* TODO: enable when we have proper groups in Azure AD for administrators
    azure_active_directory {
      managed = var.aks_addon_aad_rbac_enabled && length(var.aks_addon_aad_rbac_admin_group_ids) > 0
      admin_group_object_ids = var.aks_addon_aad_rbac_admin_group_ids
    }
    */
  }

  lifecycle {
    ignore_changes = [
      kubernetes_version, # kubernetes may be upgraded by azure cli or portal
      default_node_pool[0].orchestrator_version, # kubernetes may be upgraded by azure cli or portal
      default_node_pool[0].node_count, # node count may be changed by cluster autoscaler
      network_profile[0].load_balancer_profile[0].idle_timeout_in_minutes
    ]
  }
  # wait until the role assignment has been assigned to the AKS cluster identity
  depends_on = [null_resource.wait_for_role_assignments_to_control_plane]

  # use disk encryption set if disk encryption is enabled
  disk_encryption_set_id = var.aks_disk_encryption_enabled ? azurerm_disk_encryption_set.cmk_disk_encryption[0].id : null
}
