###
# Import existing resources created by the bootstrap script into terraform 
##

# Creates resource group
resource "azurerm_resource_group" "tf_state_rg" {
  name     = var.tf_state_resource_group_name
  location = var.azure_region
  tags = var.default_tags
}

# Creates storage account to holder terraform state
resource "azurerm_storage_account" "tf_state_storage" {
  name                     = var.tf_state_storage_account_name
  resource_group_name      = azurerm_resource_group.tf_state_rg.name
  location                 = azurerm_resource_group.tf_state_rg.location
  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = "LRS"
  
  tags = merge( 
    var.default_tags,
    {
      "description" = "Storage Account that holds the Terraform state files."
    })
}

# Locks the storage account e.g. unable to delete since it is holding terraform state files
resource "azurerm_management_lock" "lock_tf_storage_account" {
  name       = "lock-bs-tf-stacct-${var.project_name}"
  scope      = azurerm_storage_account.tf_state_storage.id
  lock_level = "CanNotDelete"
  notes      = "Locked since it used by Terraform"
}