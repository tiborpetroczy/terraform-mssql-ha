terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.71"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.5"
    }
  }
}

provider "azurerm" {
  features {}
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
}
