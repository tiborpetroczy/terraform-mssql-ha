
# Create storage account to configure a cloud witness, you need an Azure Storage account.
resource "azurerm_storage_account" "stga" {
  name                     = "stgawitness${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  lifecycle {
    ignore_changes = [tags]
  }
}

# Create blob container under the storage account
resource "azurerm_storage_container" "quorum" {
  name                  = "quorum"
  storage_account_name  = azurerm_storage_account.stga.name
  container_access_type = "private"
}
