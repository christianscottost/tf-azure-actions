# Terraform initialization

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.98.0"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "=2.22.0"
    }
  }
  /* backend "azurerm" {
    resource_group_name  = "resourcegroup"
    storage_account_name = "storageacctname"
    container_name       = "container"
    key                  = "terraform.tfstate"

  } */
}

# Configure the providers
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id = var.tenant_id
}

provider "azuread" {
  subscription_id = var.subscription_id
  tenant_id = var.tenant_id
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

# Resources

resource "azurerm_resource_group" "example" {
  name     = "LoadBalancerRG"
  location = "West Europe"
}

resource "azurerm_public_ip" "example" {
  name                = "PublicIPForLB"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "example" {
  name                = "TestLoadBalancer"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.example.id
  }
}