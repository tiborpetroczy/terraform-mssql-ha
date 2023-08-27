data "azurerm_client_config" "current" {}

data "http" "myip" {
  url = "https://icanhazip.com"
}

# Create SQL HA resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  lifecycle {
    ignore_changes = [tags]
  }
}

# Create general password for virtuam machines
resource "random_password" "pwd" {
  length      = 12
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  special     = false
}

# Create general password for SQL instance(s)
resource "random_password" "sqlpwd" {
  length  = 16
  lower   = true
  upper   = true
  numeric = true
  special = false
}

# Create general random string to uniqe name
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}
