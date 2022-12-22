#!/bin/bash

echo -e "\n\e[34m╔══════════════════════════════════════╗"
echo -e "║\e[33m   Terraform Backend Bootstrap! 🥾\e[34m    ║"
echo -e "║\e[32m        One time setup script \e[34m        ║"
echo -e "╚══════════════════════════════════════╝"

echo -e "\n\e[34m»»» ✅ \e[96mChecking pre-reqs\e[0m..."

# Read arguments
isprovisioning=false
while getopts c:p: flag
do
    case "${flag}" in
        c) configfile=${OPTARG};;
        p) isprovisioning=${OPTARG};;
    esac
done

# Load env variables from .env file
if [ -z "$configfile" ]; then
  echo -e "\e[31m»»» 💥 No environment file is provided, please input environment file and try again!"
  exit
else
  echo -e "\n\e[34m»»» 🧩 \e[96mLoading environmental variables\e[0m..."
  export $(egrep -v '^#' $configfile | xargs)
fi

az > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo -e "\e[31m»»» ⚠️ Azure CLI is not installed! 😥 Please go to http://aka.ms/cli to set it up"
  exit
fi

terraform version > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo -e "\e[31m»»» ⚠️ Terraform is not installed! 😥 Please go to https://www.terraform.io/downloads.html to set it up"
  exit
fi

SUB_NAME=$(az account show --query name -o tsv)
if [ -z "$SUB_NAME" ]; then
  echo -e "\n\e[31m»»» ⚠️ You are not logged in to Azure! Logging to Azure"
  az login
fi

SUB_NAME=$(az account show --query name -o tsv)
SUB_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

echo -e "\e[34m»»» 🔨 \e[96mAzure details from logged on user \e[0m"
echo -e "\e[34m»»»   • \e[96mSubscription: \e[33m$SUB_NAME\e[0m"
echo -e "\e[34m»»»   • \e[96mSubscription ID: \e[33m$SUB_ID\e[0m"
echo -e "\e[34m»»»   • \e[96mTenant:       \e[33m$TENANT_ID\e[0m\n"

read -p " - Are these details correct, do you want to continue (y/n)? " answer
case ${answer:0:1} in
    y|Y )
    ;;
    * )
        echo -e "\e[31mBootstrap canceled\e[0m\n"
        exit
    ;;
esac

if [ $isprovisioning == "true" ]; then 

  # Baseline Azure resources
  echo -e "\n\e[96mCreating resource group and storage account\e[0m..."
  az group create --resource-group $TF_VAR_tf_state_resource_group_name --location $TF_VAR_azure_region -o table
  az storage account create --resource-group $TF_VAR_tf_state_resource_group_name \
  --name $TF_VAR_tf_state_storage_account_name --location $TF_VAR_azure_region \
  --kind StorageV2 --sku Standard_LRS -o table

  # Blob container
  SA_KEY=$(az storage account keys list --account-name $TF_VAR_tf_state_storage_account_name --query "[0].value" -o tsv)
  az storage container create --account-name $TF_VAR_tf_state_storage_account_name --name $TF_VAR_tf_state_storage_account_container_name --account-key $SA_KEY -o table

  # Set up Terraform
  echo -e "\n\e[96mTerraform init\e[0m..."
  terraform init -input=false -backend=true -reconfigure \
    -backend-config="resource_group_name=$TF_VAR_tf_state_resource_group_name" \
    -backend-config="storage_account_name=$TF_VAR_tf_state_storage_account_name" \
    -backend-config="container_name=$TF_VAR_tf_state_storage_account_container_name" 

  echo -e "\n\e[96mTerraform validate\e[0m..." 
  terraform validate

  # Import the storage account & res group into state
  echo -e "\n\e[96mImporting resources to state\e[0m..."
  terraform import "azurerm_resource_group.tf_state_rg" "/subscriptions/$SUB_ID/resourceGroups/$TF_VAR_tf_state_resource_group_name"
  terraform import "azurerm_storage_account.tf_state_storage" "/subscriptions/$SUB_ID/resourceGroups/$TF_VAR_tf_state_resource_group_name/providers/Microsoft.Storage/storageAccounts/$TF_VAR_tf_state_storage_account_name"
else 
  echo -e "\n\e[96mTerraform init\e[0m..."
  terraform init -input=false -backend=true -reconfigure \
    -backend-config="resource_group_name=$TF_VAR_tf_state_resource_group_name" \
    -backend-config="storage_account_name=$TF_VAR_tf_state_storage_account_name" \
    -backend-config="container_name=$TF_VAR_tf_state_storage_account_container_name" 

  
  echo -e "\n\e[96mTerraform validate\e[0m..." 
  terraform validate
fi

echo -e "\n\e[34m»»» 📜 \e[96mTerraform plan\e[0m...\n"
terraform plan

read -p " - Do you want to apply terraform (y/n)? " answer
case ${answer:0:1} in
    y|Y )
    ;;
    * )
        echo -e "\n\e[96mTerraform apply canceled\e[0m..." 
        exit
    ;;
esac

echo -e "\n\e[34m»»» 📜 \e[96mTerraform apply\e[0m...\n"
terraform apply

echo -e "\n\e[34m»»» 📜 \e[96mLogout azure\e[0m...\n"
az logout