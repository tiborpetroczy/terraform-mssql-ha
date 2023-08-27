# PRIMARY DOMAIN CONTROLLER
# Create public IP for primary domain controller
resource "azurerm_public_ip" "dc1" {
  name                = "pip-dc1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"

  lifecycle {
    ignore_changes = [tags]
  }
}

# Create network interface for primary domain controller
resource "azurerm_network_interface" "dc1" {
  name                = "nic-dc1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.dc.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.dc1.id
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

# Create association between network interface and security group
resource "azurerm_network_interface_security_group_association" "dc1_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.dc1.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}


# Create primary domain controller virtual machine
resource "azurerm_windows_virtual_machine" "dc1" {
  name                = "vm-dc1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.dc_vm_size
  admin_username      = var.admin_username
  admin_password      = random_password.pwd.result
  network_interface_ids = [
    azurerm_network_interface.dc1.id
  ]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  os_disk {
    name                 = "vm-dc1-osdisk"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  winrm_listener {
    protocol = "Http"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

# Create extension to Open SSH
resource "azurerm_virtual_machine_extension" "openssh" {
  name                       = "InstallOpenSSH"
  virtual_machine_id         = azurerm_windows_virtual_machine.dc1.id
  publisher                  = "Microsoft.Azure.OpenSSH"
  type                       = "WindowsOpenSSH"
  type_handler_version       = "3.0"
  auto_upgrade_minor_version = true
  depends_on = [
    azurerm_windows_virtual_machine.dc1
  ]
  lifecycle {
    ignore_changes = [tags]
  }
}

# Create extension to install DNS and AD Forest
resource "azurerm_virtual_machine_extension" "gpmc" {
  name                       = "InstallGPMC"
  virtual_machine_id         = azurerm_windows_virtual_machine.dc1.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
    "commandToExecute": "powershell.exe -Command \"${join(";", local.powershell_gpmc)}\""
    }
  SETTINGS

  depends_on = [
    azurerm_windows_virtual_machine.dc1,
    azurerm_virtual_machine_extension.openssh
  ]

  lifecycle {
    ignore_changes = [tags, settings]
  }
}

resource "time_sleep" "gpmc" {
  depends_on      = [azurerm_virtual_machine_extension.gpmc]
  create_duration = "60s"
}

# Create Azure AD technical users with remote-exec module to use PowerShell
resource "terraform_data" "ad_user" {
  triggers_replace = [
    azurerm_virtual_machine_extension.openssh.id,
    azurerm_virtual_machine_extension.gpmc.id,
    time_sleep.gpmc.id
  ]

  # With SSH connection
  provisioner "remote-exec" {
    connection {
      type            = "ssh"
      user            = var.admin_username
      password        = random_password.pwd.result
      host            = azurerm_public_ip.dc1.ip_address
      target_platform = "windows"
      timeout         = "1m"
    }

    inline = [
      "powershell.exe -Command \"${join(";", local.powershell_add_users)}\""
    ]
  }

  depends_on = [time_sleep.gpmc]
}
