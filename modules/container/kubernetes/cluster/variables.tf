variable region_name {
  description = "The Azure region to deploy into."
  type = string
}

variable region_code {
  description = "The code of Azure region to deploy into (supposed to be a meaningful abbreviation of region_name."
  type = string
}

variable common_tags {
  description = "Map of common tags to be attached to all managed Azure resources"
  type = map(string)
}

variable solution_name {
  description = "Name of this Azure solution"
  type = string
}

variable solution_stage {
  description = "Stage of this Azure solution"
  type = string
}

variable solution_fqn {
  description = "Fully qualified name of this Azure solution"
  type = string
}

variable resource_group_name {
  description = "The name of the resource group supposed to own all allocated resources"
  type = string
}

variable resource_group_location {
  description = "The location of the resource group supposed to own all allocated resources"
  type = string
}

variable aks_version {
  description = "Kubernetes version the AKS service instance should be based on"
  type = string
}

variable loadbalancer_subnet_id {
  description = "Unique identifier of the internal loadbalancer subnet"
  type = string
}

variable node_groups_subnet_id {
  description = "Unique identifier of the AKS node groups subnet"
  type = string
}

variable system_pool_vm_sku {
  description = "VM instance size to be used for nodes in the system pool"
  type = string
  default = "Standard_D2s_v3"
}

variable system_pool_min_size {
  description = "minimum number of nodes in the system pool"
  type = number
  default = 2
}

variable system_pool_desired_size {
  description = "desired number of nodes in the system pool"
  type = number
  default = 2
}

variable system_pool_max_size {
  description = "maximum number of nodes in the system pool"
  type = number
  default = 6
}

variable system_pool_os_disk_size {
  description = "OS disk size of nodes in the system pool in GB"
  type = number
  default = 512
}

variable vnet_name {
  description = "Name of the VNet which hosts the AKS cluster."
  type = string
}

variable aks_dns_service_ip {
  description = "IP address used for Kubernetes DNS service on each worker node"
  type = string
}

variable aks_docker_bridge_cidr {
  description = "CIDR used as the Docker bridge IP address on worker nodes"
  type = string
}

variable aks_pod_cidr {
  description = "CIDR used for virtual pod IP addresses"
  type = string
}

variable aks_service_cidr {
  description = "CIDR used for ClusterIP Kubernetes services"
  type = string
}

variable aks_addon_dashboard_enabled {
  description = "Enables the Kubernetes dashboard add-on"
  type = bool
  default = false
}

variable aks_addon_oms_agent_enabled {
  description = "Enables the Kubernetes OMS agent add-on"
  type = bool
  default = false
}

variable aks_addon_azure_policy_enabled {
  description = "Enables the Kubernetes Azure Policy add-on"
  type = bool
  default = false
}

variable aks_network_plugin_type {
  description = "Defines the type of Kubernetes Network Plugin to use; possible values are: kubenet, azure"
  type = string
  default = "kubenet"
  validation {
    condition = var.aks_network_plugin_type == "kubenet" || var.aks_network_plugin_type == "azure"
    error_message = "The supported network plugin types are either kubenet or azure."
  }
}

variable aks_addon_aad_rbac_enabled {
  description = "Enables the Azure AD add-on for Kubernetes RBAC"
  type = bool
  default = false
}

variable aks_addon_aad_rbac_admin_group_ids {
  description = "List of Azure AD group object IDs whose members are allowed to administrate the AKS cluster"
  type = list(string)
  default = []
}

variable key_vault_id {
  description = "Unique identifier the common key vault instance used by this solution."
  type = string
}

variable log_analytics_workspace_id {
  description = "Unique identifier of the log analytics workspace; only required if azure_monitoring_enabled == true"
  type = string
  default = ""
}

variable container_registry_id {
  description = "Unique identifier of the Azure Container registry used to pull Docker images for AKS workload"
  type = string
}

variable node_group_upgrade_max_surge {
  description = "Percentage of nodes which can be added during an upgrade"
  type = string
  default = "33%"
}

variable aks_disk_encryption_enabled {
  description = "Enables encryption of OS disks and persistent volumes with customer-managed keys"
  type = bool
  default = false
}

variable azure_monitor_enabled {
  description = "Enables Azure Monitor with Container Insights on the AKS cluster"
  type = bool
  default = false
}

variable user_node_groups {
  description = "Information about additional user node groups to be added to the AKS cluster"
  type = list(object({
    name = string
    vm_sku = string
    max_size = number
    min_size = number
    desired_size = number
    max_surge = string
    kubernetes_version = string
    os_disk_size = number
    priority = string
    spotPrice = string
    labels = map(string)
    taints = list(string)
  }))
  default = []
}

variable internal_loadbalancer_enabled {
  description = "Controls if an internal loadbalancer should be managed by AKS as well"
  type = bool
  default = false
}

variable internal_loadbalancer_subnet_name {
  description = "Name of a subnet supposed to host the internal loadbalancer"
  type = string
  default = ""
}