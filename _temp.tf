# resource "azurerm_lb" "lb" {
#   name                = "sql-lb"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   sku                 = "Standard"
#   sku_tier            = "Regional"

#   frontend_ip_configuration {
#     name                          = "ipconfig"
#     private_ip_address_allocation = "Dynamic"
#     subnet_id                     = azurerm_subnet.sqlha_lb.id
#   }
# }

