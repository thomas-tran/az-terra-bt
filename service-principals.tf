## Create an AAD application, it's needed to create a SP
resource "azuread_application" "azdo_keyvault_app" {
  display_name = "app-bs-tf-azdo-vargroup-kv-connection-${var.project_name}"
}

## Create an AAD Service Principal
resource "azuread_service_principal" "azdo_keyvault_sp" {
  application_id = azuread_application.azdo_keyvault_app.application_id
}

## Creates a password for the AAD app
resource "azuread_application_password" "azdo_keyvault_sp_password" {
  application_object_id = azuread_application.azdo_keyvault_app.id
  display_name          = "TF generated password" 
  end_date              = "2040-01-01T00:00:00Z"
}

## Assign a KV Admin role to the SP. The role is assigned at resource group scope
resource "azurerm_role_assignment" "azdo_keyvault_role" {
  scope                            = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_resource_group.tf_state_rg.name}"
  role_definition_name             = "Key Vault Administrator"
  principal_id                     = azuread_service_principal.azdo_keyvault_sp.id
  skip_service_principal_aad_check = true
}

## Create a Azure DevOps Service Endpoint to access to KV
resource "azuredevops_serviceendpoint_azurerm" "keyvault_access" {
  project_id            = azuredevops_project.project.id
  service_endpoint_name = "service-endpoint-bs-tf-azdo-vargroup-kv-connection-${var.project_name}"
  credentials {
    serviceprincipalid  = azuread_application.azdo_keyvault_app.application_id
    serviceprincipalkey = azuread_application_password.azdo_keyvault_sp_password.value
  }
  azurerm_spn_tenantid      = data.azurerm_client_config.current.tenant_id
  azurerm_subscription_id   = data.azurerm_client_config.current.subscription_id
  azurerm_subscription_name = "Management Subscription"
}



## Create an AAD application, it's needed to create a SP
resource "azuread_application" "iac_app" {
  display_name = "app-bs-tf-deploy-iac-azdo-pipelines-${var.project_name}"
}

## Create an AAD Service Principal
resource "azuread_service_principal" "iac_sp" {
  application_id = azuread_application.iac_app.application_id
}

## Creates a random password for the AAD app
resource "azuread_application_password" "iac_sp_password" {
  application_object_id = azuread_application.iac_app.id
  display_name          = "TF generated password"   
  end_date              = "2040-01-01T00:00:00Z"
}

# Create a custom role for this SP
resource "azurerm_role_definition" "iac_custom_role" {
  name        = "role-iac-deploy-${var.project_name}"
  scope       = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  description = "This is a custom role created via Terraform. It has the same permissions as Contributor but can create role assigmnemts. It also have permissions to read, write and delete data on  Azure Key Vault and App Configuration."
  permissions {
    actions     = ["*"]
    not_actions = [
      "Microsoft.Authorization/elevateAccess/Action",
      "Microsoft.Blueprint/blueprintAssignments/write",
      "Microsoft.Blueprint/blueprintAssignments/delete",
      "Microsoft.Compute/galleries/share/action"
    ]
    data_actions = [ 
      "Microsoft.KeyVault/vaults/*",
      "Microsoft.AppConfiguration/configurationStores/*/read",
      "Microsoft.AppConfiguration/configurationStores/*/write",
      "Microsoft.AppConfiguration/configurationStores/*/delete"
    ]
    not_data_actions = []
  }
  assignable_scopes = [
    "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  ]
}

## Assign the custom role to the SP. The role is assigned at subscription scope.
resource "azurerm_role_assignment" "iac_role_assignment" {
  scope                            = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  role_definition_name             = "role-iac-deploy-${var.project_name}"
  principal_id                     = azuread_service_principal.iac_sp.id
  skip_service_principal_aad_check = true
  depends_on = [
    azurerm_role_definition.iac_custom_role
  ]
}

## Store SP client secret in the KV
resource "azurerm_key_vault_secret" "iac_sp_secret" {
  name         = "sp-bs-tf-iac-client-secret"
  value        = azuread_application_password.iac_sp_password.value
  key_vault_id = azurerm_key_vault.sp_creds_kv.id
  tags = var.default_tags
}

## Store SP client secret in the KV
resource "azurerm_key_vault_secret" "iac_sp_clientid" {
  name         = "sp-bs-tf-iac-client-id"
  value        = azuread_service_principal.iac_sp.application_id
  key_vault_id = azurerm_key_vault.sp_creds_kv.id
  tags = var.default_tags
}

## Store SP client secret in the KV
resource "azurerm_key_vault_secret" "iac_sp_tenant" {
  name         = "sp-bs-tf-iac-tenant-id"
  value        = data.azurerm_client_config.current.tenant_id
  key_vault_id = azurerm_key_vault.sp_creds_kv.id
  tags = var.default_tags
}

## Store SP client secret in the KV
resource "azurerm_key_vault_secret" "iac_sp_subid" {
  name         = "sp-bs-tf-iac-subscription-id"
  value        = data.azurerm_client_config.current.subscription_id
  key_vault_id = azurerm_key_vault.sp_creds_kv.id
  tags = var.default_tags
}