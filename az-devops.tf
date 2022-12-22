resource "azuredevops_project" "project" {
  name               = var.azdo_project_name
  visibility         = "private"
  version_control    = "Git"
  work_item_template = "Agile"
  description        = "Generated by Terraform"
  features = {
   "boards" = "enabled"
    "repositories" = "enabled"
    "pipelines" = "enabled"
    "testplans" = "enabled"
    "artifacts" = "enabled"
  }
}

resource "azuredevops_variable_group" "azdo_iac_var_group" {
  project_id   = azuredevops_project.project.id
  name         = "vargroup-bs-tf-iac-${var.project_name}"
  allow_access = true

  key_vault {
    name                = azurerm_key_vault.sp_creds_kv.name
    service_endpoint_id = azuredevops_serviceendpoint_azurerm.keyvault_access.id
  }

  depends_on = [
    azurerm_key_vault_secret.iac_sp_secret,
    azurerm_key_vault_secret.iac_sp_clientid,
    azurerm_key_vault_secret.iac_sp_tenant,
    azurerm_key_vault_secret.iac_sp_subid
  ]

  variable {
    name = "sp-bs-tf-iac-client-id"
  }

  variable {
    name = "sp-bs-tf-iac-client-secret"
  }

  variable {
    name = "sp-bs-tf-iac-tenant-id"
  }

  variable {
    name = "sp-bs-tf-iac-subscription-id"
  }
}
