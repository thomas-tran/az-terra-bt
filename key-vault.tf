# Creates KeyVault to hold the service principal credentials
resource "azurerm_key_vault" "sp_creds_kv" {
  name                        = "kv-bs-tf-${var.project_name}"
  location                    = azurerm_resource_group.tf_state_rg.location
  resource_group_name         = azurerm_resource_group.tf_state_rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 15
  enable_rbac_authorization   = true
  purge_protection_enabled    = false
  tags                        = merge( 
    var.default_tags,
    {
      "description" = "KeyVault that holds the SP credentials for deploying infrastructure"
    })
}

## Lock the key vault. 
resource "azurerm_management_lock" "lock_sp_kv" {
  name       = "lock-bs-tf-kv-${var.project_name}"
  scope      = azurerm_key_vault.sp_creds_kv.id
  lock_level = "CanNotDelete"
  notes      = "Locked since it will be used by the Azure DevOps"
}

## Add myself as a KV Admin role. This assignment is required to later add the IaC SP credentials into the KV
resource "azurerm_role_assignment" "me_keyvault_role" {
  scope                            = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_resource_group.tf_state_rg.name}"
  role_definition_name             = "Key Vault Administrator"
  principal_id                     = data.azurerm_client_config.current.object_id
}
