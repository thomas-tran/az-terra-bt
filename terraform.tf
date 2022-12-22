terraform {

  backend "azurerm" {
    key = "bootstrap.tfstate"
  }

  required_providers {

    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }

    azuredevops = {
      source = "microsoft/azuredevops"
      version = ">=0.2.0"
    }

    azuread = {
      source  = "azuread"
      version = ">=2.20.0"
    }
  }
}