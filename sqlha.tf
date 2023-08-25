
resource "azurerm_public_ip" "sqlha_pip" {
  count               = var.sqlha_count
  name                = "pip-sqhlha-${count.index + 1}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["${count.index + 1}"]
}

resource "azurerm_network_interface" "sqlha_nic" {
  count               = var.sqlha_count
  name                = "nic-sqlha-${count.index + 1}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sqlha[count.index].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.sqlha_pip[count.index].id
    primary                       = true
  }

  ip_configuration {
    name                          = "windows-cluster-ip"
    subnet_id                     = azurerm_subnet.sqlha[count.index].id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(azurerm_subnet.sqlha[count.index].address_prefixes[0], 10)
  }

  ip_configuration {
    name                          = "availability-group-listener"
    subnet_id                     = azurerm_subnet.sqlha[count.index].id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(azurerm_subnet.sqlha[count.index].address_prefixes[0], 11)
  }

  # Must be set and need to restart the computer to reach the domain controller and DNS
  dns_servers = [azurerm_network_interface.dc1.ip_configuration[0].private_ip_address]
  lifecycle {
    ignore_changes = [ ip_configuration ]
  }
}

resource "azurerm_network_interface_security_group_association" "sqlha_nsg_assoc" {
  count                     = var.sqlha_count
  network_interface_id      = azurerm_network_interface.sqlha_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_windows_virtual_machine" "sqlha_vm" {
  count               = var.sqlha_count
  name                = "vm-sqlha-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.sql_vm_size
  admin_username      = var.admin_username
  admin_password      = random_password.pwd.result
  zone                = count.index + 1

  network_interface_ids = [
    azurerm_network_interface.sqlha_nic[count.index].id
  ]

  source_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "sql2022-ws2022"
    sku       = "sqldev-gen2"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    name                 = "vm-sqlha-${count.index + 1}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 127
  }
}

resource "azurerm_managed_disk" "sqlha_data" {
  count                = var.sqlha_count
  name                 = "dsk-vm-sqlha-${count.index + 1}-data"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 50
  zone                 = count.index + 1
}

resource "azurerm_virtual_machine_data_disk_attachment" "sqlha_data" {
  count              = var.sqlha_count
  managed_disk_id    = azurerm_managed_disk.sqlha_data[count.index].id
  virtual_machine_id = azurerm_windows_virtual_machine.sqlha_vm[count.index].id
  lun                = "0"
  caching            = "ReadWrite"
}

resource "azurerm_managed_disk" "sqlha_log" {
  count                = var.sqlha_count
  name                 = "dsk-vm-sqlha-${count.index + 1}-log"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 30
  zone                 = count.index + 1
}

# Create managed disk attachment for SQL data on LUN-1
resource "azurerm_virtual_machine_data_disk_attachment" "sqlha_log" {
  count              = var.sqlha_count
  managed_disk_id    = azurerm_managed_disk.sqlha_log[count.index].id
  virtual_machine_id = azurerm_windows_virtual_machine.sqlha_vm[count.index].id
  lun                = "1"
  caching            = "ReadWrite"
}

resource "azurerm_managed_disk" "sqlha_temp" {
  count                = var.sqlha_count
  name                 = "dks-vm-sqlha-${count.index + 1}-temp"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 20
  zone                 = count.index + 1
}

# Create managed disk attachment for SQL data on LUN-1
resource "azurerm_virtual_machine_data_disk_attachment" "sqlha_temp" {
  count              = var.sqlha_count
  managed_disk_id    = azurerm_managed_disk.sqlha_temp[count.index].id
  virtual_machine_id = azurerm_windows_virtual_machine.sqlha_vm[count.index].id
  lun                = "2"
  caching            = "ReadWrite"
}

# Create extension for primary SQL server to join domain with domain admin user
resource "azurerm_virtual_machine_extension" "domain_join" {
  count                = var.sqlha_count
  name                 = "SQL${count.index + 1}DomainJoin"
  virtual_machine_id   = azurerm_windows_virtual_machine.sqlha_vm[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"

  settings = <<SETTINGS
  {
    "Name": "${var.domain_name}",
    "OUPath": "${local.servers_ou_path}",
    "User": "${var.domain_netbios_name}\\${var.admin_username}",
    "Restart": "true",
    "Options": "3"
  }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "Password": "${random_password.pwd.result}"
  }
PROTECTED_SETTINGS

  depends_on = [
    azurerm_windows_virtual_machine.sqlha_vm
  ]
}

# Add the install account to local admin account on SQL server
# Give permission to install account on Builtin OU

resource "azurerm_mssql_virtual_machine_group" "vmg" {
  name                = var.sqlcluster_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sql_image_offer = "SQL2022-WS2022"
  sql_image_sku   = "Developer"

  wsfc_domain_profile {
    fqdn                           = var.domain_name
    cluster_subnet_type            = "MultiSubnet"
    cluster_bootstrap_account_name = "${var.admin_username}@${var.domain_name}"
    cluster_operator_account_name  = "${var.admin_username}@${var.domain_name}"
    sql_service_account_name       = "sqlsvc@${var.domain_name}"
    organizational_unit_path       = local.servers_ou_path
    storage_account_primary_key    = azurerm_storage_account.stga.primary_access_key
    storage_account_url            = "${azurerm_storage_account.stga.primary_blob_endpoint}${azurerm_storage_container.quorum.name}"
  }
}

resource "azurerm_mssql_virtual_machine" "sqlha" {
  count = var.sqlha_count

  virtual_machine_id               = azurerm_windows_virtual_machine.sqlha_vm[count.index].id
  sql_license_type                 = "PAYG"
  sql_virtual_machine_group_id     = azurerm_mssql_virtual_machine_group.vmg.id
  sql_connectivity_port            = 1433
  sql_connectivity_type            = "PRIVATE"
  sql_connectivity_update_password = var.sql_svc_password
  sql_connectivity_update_username = "sqllogin"

  wsfc_domain_credential {
    cluster_bootstrap_account_password = random_password.pwd.result
    cluster_operator_account_password  = random_password.pwd.result
    sql_service_account_password       = var.sql_svc_password
  }

  storage_configuration {
    disk_type             = "NEW"
    storage_workload_type = "GENERAL"
    data_settings {
      default_file_path = var.sqldatafilepath
      luns              = [azurerm_virtual_machine_data_disk_attachment.sqlha_data[count.index].lun]
    }

    log_settings {
      default_file_path = var.sqllogfilepath
      luns              = [azurerm_virtual_machine_data_disk_attachment.sqlha_log[count.index].lun]
    }

    temp_db_settings {
      default_file_path = var.sqltempfilepath
      luns              = [azurerm_virtual_machine_data_disk_attachment.sqlha_temp[count.index].lun]
    }
  }

  depends_on = [azurerm_windows_virtual_machine.sqlha_vm]
}

# resource "azurerm_mssql_virtual_machine_availability_group_listener" "aag" {
#   name                         = "aag-listener" # Length (1-15)
#   availability_group_name      = "aag"
#   port                         = 1433
#   sql_virtual_machine_group_id = azurerm_mssql_virtual_machine_group.vmg.id

#   multi_subnet_ip_configuration {
#     private_ip_address     = cidrhost(azurerm_subnet.sqlha[0].address_prefixes[0], 8)
#     sql_virtual_machine_id = azurerm_mssql_virtual_machine.sqlha[0].id
#     subnet_id              = azurerm_subnet.sqlha[0].id
#   }

#   multi_subnet_ip_configuration {
#     private_ip_address     = cidrhost(azurerm_subnet.sqlha[1].address_prefixes[0], 8)
#     sql_virtual_machine_id = azurerm_mssql_virtual_machine.sqlha[1].id
#     subnet_id              = azurerm_subnet.sqlha[1].id
#   }

#   replica {
#     sql_virtual_machine_id = azurerm_mssql_virtual_machine.sqlha[0].id
#     role                   = "Primary"
#     commit                 = "Synchronous_Commit"
#     failover_mode          = "Automatic"
#     readable_secondary     = "No"
#   }

#   replica {
#     sql_virtual_machine_id = azurerm_mssql_virtual_machine.sqlha[1].id
#     role                   = "Secondary"
#     commit                 = "Synchronous_Commit"
#     failover_mode          = "Automatic"
#     readable_secondary     = "No"
#   }
# }
