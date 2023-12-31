# Create NSG for VMs with open RDP
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-for-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Create RDP rule to VMs from current local machine public IP
  security_rule {
    name                       = "RDP"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = chomp(data.http.myip.response_body)
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "All"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = chomp(data.http.myip.response_body)
    destination_address_prefix = "*"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}
