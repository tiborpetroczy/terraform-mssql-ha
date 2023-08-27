# Create Vnet for Domain Controller
resource "azurerm_virtual_network" "dc" {
  name                = "vnet-dc"
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.38.0.0/16"]
  location            = azurerm_resource_group.rg.location
  lifecycle {
    ignore_changes = [tags]
  }
}

# Create subnet for Domain Controller(s)
resource "azurerm_subnet" "dc" {
  name                 = "DC-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.dc.name
  address_prefixes     = ["10.38.0.0/24"]
}

# Set the DC DNS IP address for VNET of SQL HA Cluster
resource "azurerm_virtual_network" "sqlha" {
  name                = "vnet-sqlha"
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.40.0.0/16"]
  location            = azurerm_resource_group.rg.location
  dns_servers         = [azurerm_network_interface.dc1.ip_configuration[0].private_ip_address]
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_subnet" "sqlha" {
  count                = var.sqlha_count
  name                 = "snet-sqlha-${count.index + 1}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.sqlha.name
  address_prefixes     = ["10.40.${count.index + 1}.0/24"]
}

# Create vnet peering between vnet1 (DC) and vnet2 (SQLs)
resource "azurerm_virtual_network_peering" "dc_sqlha" {
  name                      = "dc-sqlha-peering"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.dc.name
  remote_virtual_network_id = azurerm_virtual_network.sqlha.id
}

resource "azurerm_virtual_network_peering" "sqlha_dc" {
  name                      = "sqlha-dc-peering"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.sqlha.name
  remote_virtual_network_id = azurerm_virtual_network.dc.id
}