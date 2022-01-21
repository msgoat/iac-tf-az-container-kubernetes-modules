# create a cluster-specific customer managed key for disk encryption
resource azurerm_key_vault_key cmk_disk_encryption {
  count = var.aks_disk_encryption_enabled ? 1 : 0
  name = "key-${var.region_code}-${local.cluster_name}-aks"
  key_vault_id = var.key_vault_id
  key_type = "RSA"
  key_size = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  tags = merge({"Name" = "key-${var.region_code}-${local.cluster_name}-aks"}, local.module_common_tags)
}

# create an instance of a disk encryption set
resource azurerm_disk_encryption_set cmk_disk_encryption {
  count = var.aks_disk_encryption_enabled ? 1 : 0
  name = "des-${var.region_code}-${local.cluster_name}-aks"
  resource_group_name = var.resource_group_name
  location = var.region_name
  key_vault_key_id = azurerm_key_vault_key.cmk_disk_encryption[0].id

  identity {
    type = "SystemAssigned"
  }

  tags = merge({"Name" = "des-${var.region_code}-${local.cluster_name}-aks"}, local.module_common_tags)
}

# grant the disk encryption set access to key vault
resource azurerm_key_vault_access_policy cmk_disk_encryption {
  count = var.aks_disk_encryption_enabled ? 1 : 0
  key_vault_id = var.key_vault_id
  tenant_id = azurerm_disk_encryption_set.cmk_disk_encryption[0].identity[0].tenant_id
  object_id = azurerm_disk_encryption_set.cmk_disk_encryption[0].identity[0].principal_id

  key_permissions = [
    "get",
    "wrapkey",
    "unwrapkey"
  ]
}

# create a kubernetes storage class for encrypted default disks
resource kubernetes_storage_class default_encrypted {
  count = var.aks_disk_encryption_enabled ? 1 : 0
  metadata {
    name = "default-encrypted"
  }
  storage_provisioner = "kubernetes.io/azure-disk"
  parameters = {
    cachingmode = "ReadOnly"
    kind = "Managed"
    storageaccounttype = "StandardSSD_LRS"
    diskEncryptionSetID = azurerm_disk_encryption_set.cmk_disk_encryption[0].id
  }
  allow_volume_expansion = true
  reclaim_policy = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"
}

# create a kubernetes storage class for encrypted managed premium disks
resource kubernetes_storage_class managed_premium_encrypted {
  count = var.aks_disk_encryption_enabled ? 1 : 0
  metadata {
    name = "managed-premium-encrypted"
  }
  storage_provisioner = "kubernetes.io/azure-disk"
  parameters = {
    cachingmode = "ReadOnly"
    kind = "Managed"
    storageaccounttype = "Premium_LRS"
    diskEncryptionSetID = azurerm_disk_encryption_set.cmk_disk_encryption[0].id
  }
  allow_volume_expansion = true
  reclaim_policy = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"
}
