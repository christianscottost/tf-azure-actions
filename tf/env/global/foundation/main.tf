# Terraform initialization

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.98.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "=2.22.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "rg-sandbox-eus"
    storage_account_name = "stsandboxeus"
    container_name       = "sandbox"
    key                  = "terraform.tfstate"
    use_oidc = true
    tenant_id            = "567e2175-bf4e-4bcc-b114-335fa0061f2f"
    subscription_id      = "62c223af-3ea4-4cf8-bb4a-c8449fe872e1"
  }
}

# Configure the providers
provider "azurerm" {
  features {}
  use_oidc = true
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

provider "azuread" {
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

# Environment state storage
resource "azurerm_resource_group" "init" {
  location = var.primary_location.name
  name     = "rg-${var.environment}-${var.primary_location.prefix}"
}


#Storage Configuration
resource "azurerm_storage_account" "init" {
  account_replication_type  = "LRS"
  account_tier              = "Standard"
  enable_https_traffic_only = true
  location                  = azurerm_resource_group.init.location
  name                      = "st${var.environment}${var.primary_location.prefix}"
  resource_group_name       = azurerm_resource_group.init.name
  blob_properties {
    delete_retention_policy {
      days = 30
    }
    container_delete_retention_policy {
      days = 30
    }
    versioning_enabled = true
  }
}

resource "azurerm_storage_container" "init" {
  name                  = var.environment
  storage_account_name  = azurerm_storage_account.init.name
  container_access_type = "private"
}

# Resources

resource "azurerm_public_ip" "example" {
  name                = "pip-${var.environment}-${var.primary_location.prefix}"
  location            = azurerm_resource_group.init.location
  resource_group_name = azurerm_resource_group.init.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "example" {
  name                = "lb-${var.environment}-${var.primary_location.prefix}"
  location            = azurerm_resource_group.init.location
  resource_group_name = azurerm_resource_group.init.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.example.id
  }
}