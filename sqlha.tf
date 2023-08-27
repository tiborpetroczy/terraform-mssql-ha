
resource "azurerm_public_ip" "sqlha_pip" {
  count               = var.sqlha_count
  name                = "pip-sqhlha-${count.index + 1}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["${count.index + 1}"]
  lifecycle {
    ignore_changes = [tags]
  }
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
    ignore_changes = [tags, ip_configuration]
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
    publisher = var.sql_vm_image_publisher
    offer     = var.sql_vm_image_offer
    sku       = var.sql_vm_image_sku
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

  lifecycle {
    ignore_changes = [tags]
  }
}

# Create extension to Open SSH
resource "azurerm_virtual_machine_extension" "openssh_sqlha" {
  count                      = var.sqlha_count
  name                       = "InstallOpenSSH"
  virtual_machine_id         = azurerm_windows_virtual_machine.sqlha_vm[count.index].id
  publisher                  = "Microsoft.Azure.OpenSSH"
  type                       = "WindowsOpenSSH"
  type_handler_version       = "3.0"
  auto_upgrade_minor_version = true
  depends_on = [
    azurerm_windows_virtual_machine.sqlha_vm
  ]
  lifecycle {
    ignore_changes = [tags]
  }
}

# Create managed disk for data of SQL
resource "azurerm_managed_disk" "sqlha_data" {
  count                = var.sqlha_count
  name                 = "dsk-vm-sqlha-${count.index + 1}-data"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 50
  zone                 = count.index + 1
  lifecycle {
    ignore_changes = [tags]
  }
}

# Create managed disk attachment for SQL data on LUN-0
resource "azurerm_virtual_machine_data_disk_attachment" "sqlha_data" {
  count              = var.sqlha_count
  managed_disk_id    = azurerm_managed_disk.sqlha_data[count.index].id
  virtual_machine_id = azurerm_windows_virtual_machine.sqlha_vm[count.index].id
  lun                = "0"
  caching            = "ReadWrite"
}

# Create managed disk for log of SQL
resource "azurerm_managed_disk" "sqlha_log" {
  count                = var.sqlha_count
  name                 = "dsk-vm-sqlha-${count.index + 1}-log"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 30
  zone                 = count.index + 1
  lifecycle {
    ignore_changes = [tags]
  }
}

# Create managed disk attachment for SQL log on LUN-1
resource "azurerm_virtual_machine_data_disk_attachment" "sqlha_log" {
  count              = var.sqlha_count
  managed_disk_id    = azurerm_managed_disk.sqlha_log[count.index].id
  virtual_machine_id = azurerm_windows_virtual_machine.sqlha_vm[count.index].id
  lun                = "1"
  caching            = "ReadWrite"
}

# Create managed disk for temp of SQL
resource "azurerm_managed_disk" "sqlha_temp" {
  count                = var.sqlha_count
  name                 = "dks-vm-sqlha-${count.index + 1}-temp"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 20
  zone                 = count.index + 1
  lifecycle {
    ignore_changes = [tags]
  }
}

# Create managed disk attachment for SQL temp on LUN-2
resource "azurerm_virtual_machine_data_disk_attachment" "sqlha_temp" {
  count              = var.sqlha_count
  managed_disk_id    = azurerm_managed_disk.sqlha_temp[count.index].id
  virtual_machine_id = azurerm_windows_virtual_machine.sqlha_vm[count.index].id
  lun                = "2"
  caching            = "ReadWrite"
}

# Create extension for SQL servers to join domain with domain admin user
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
    azurerm_windows_virtual_machine.sqlha_vm,
    terraform_data.ad_user
  ]

  lifecycle {
    ignore_changes = [tags]
  }
}

# Create time delay after SQL domain join
resource "time_sleep" "sqljoin" {
  depends_on      = [azurerm_virtual_machine_extension.domain_join]
  create_duration = "60s"
}

# Add the domain 'install' account to local administrators group on SQL servers
resource "terraform_data" "local_admin" {
  count = var.sqlha_count
  triggers_replace = [
    azurerm_virtual_machine_extension.domain_join[count.index].id,
    time_sleep.sqljoin.id
  ]

  # SSH connection to target SQL server with domain admin account
  provisioner "remote-exec" {
    connection {
      type            = "ssh"
      user            = "${var.domain_netbios_name}\\${var.admin_username}"
      password        = random_password.pwd.result
      host            = azurerm_public_ip.sqlha_pip[count.index].ip_address
      target_platform = "windows"
      timeout         = "1m"
    }

    inline = [
      "powershell.exe -Command \"${join(";", local.powershell_local_admin)}\""
    ]
  }

  depends_on = [time_sleep.sqljoin]
}

# Add the domain 'install' account to sysadmin roles on SQL servers
resource "terraform_data" "sql_sysadmin" {
  count = var.sqlha_count
  triggers_replace = [
    azurerm_virtual_machine_extension.domain_join[count.index].id,
    terraform_data.local_admin[count.index].id
  ]

  # SSH connection to target SQL server with local admin account
  provisioner "remote-exec" {
    connection {
      type            = "ssh"
      user            = var.admin_username
      password        = random_password.pwd.result
      host            = azurerm_public_ip.sqlha_pip[count.index].ip_address
      target_platform = "windows"
      timeout         = "1m"
    }

    inline = [
      "powershell.exe -Command \"${join(";", local.powershell_sql_sysadmin)}\""
    ]
  }
}

# In that case you don't use Domain Admins highest elevated for install account
# You should give special permission for install account on Builtin OU / Servers OU

# Indicates the capability to manage a group of virtual machines specific to Microsoft SQL.
resource "azurerm_mssql_virtual_machine_group" "vmg" {
  name                = var.sqlcluster_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sql_image_offer = var.sql_image_offer
  sql_image_sku   = var.sql_image_sku

  wsfc_domain_profile {
    fqdn                           = var.domain_name
    cluster_subnet_type            = "MultiSubnet"
    cluster_bootstrap_account_name = "install@${var.domain_name}"
    cluster_operator_account_name  = "install@${var.domain_name}"
    sql_service_account_name       = "sqlsvc@${var.domain_name}"
    organizational_unit_path       = local.servers_ou_path
    storage_account_primary_key    = azurerm_storage_account.stga.primary_access_key
    storage_account_url            = "${azurerm_storage_account.stga.primary_blob_endpoint}${azurerm_storage_container.quorum.name}"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_mssql_virtual_machine" "sqlha" {
  count = var.sqlha_count

  virtual_machine_id               = azurerm_windows_virtual_machine.sqlha_vm[count.index].id
  sql_license_type                 = "PAYG"
  sql_virtual_machine_group_id     = azurerm_mssql_virtual_machine_group.vmg.id
  sql_connectivity_port            = 1433
  sql_connectivity_type            = "PRIVATE"
  sql_connectivity_update_password = var.sql_sysadmin_password
  sql_connectivity_update_username = var.sql_sysadmin_login

  wsfc_domain_credential {
    cluster_bootstrap_account_password = var.sql_service_account_password # install account
    cluster_operator_account_password  = var.sql_service_account_password # install account
    sql_service_account_password       = var.sql_service_account_password # sqlsvc account
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

  depends_on = [
    azurerm_windows_virtual_machine.sqlha_vm,
    terraform_data.sql_sysadmin
  ]

  lifecycle {
    ignore_changes = [tags]
  }
}

# Create special permission for base OU for Cluster computer object
resource "terraform_data" "cluster_acl" {
  triggers_replace = [
    azurerm_mssql_virtual_machine.sqlha[*].id
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
      "powershell.exe -Command \"${join(";", local.powershell_acl_commands)}\""
    ]
  }

  depends_on = [
    azurerm_mssql_virtual_machine.sqlha
  ]
}

# Create Always-On availability listener for SQL cluster with multi-subnet configuration
resource "azurerm_mssql_virtual_machine_availability_group_listener" "aag" {
  name                         = "aag-listener" # Length of the name (1-15)
  availability_group_name      = "aag"
  port                         = 1433
  sql_virtual_machine_group_id = azurerm_mssql_virtual_machine_group.vmg.id

  multi_subnet_ip_configuration {
    private_ip_address     = cidrhost(azurerm_subnet.sqlha[0].address_prefixes[0], 6)
    sql_virtual_machine_id = azurerm_mssql_virtual_machine.sqlha[0].id
    subnet_id              = azurerm_subnet.sqlha[0].id
  }

  multi_subnet_ip_configuration {
    private_ip_address     = cidrhost(azurerm_subnet.sqlha[1].address_prefixes[0], 6)
    sql_virtual_machine_id = azurerm_mssql_virtual_machine.sqlha[1].id
    subnet_id              = azurerm_subnet.sqlha[1].id
  }

  replica {
    sql_virtual_machine_id = azurerm_mssql_virtual_machine.sqlha[0].id
    role                   = "Primary"
    commit                 = "Synchronous_Commit"
    failover_mode          = "Automatic"
    readable_secondary     = "No"
  }

  replica {
    sql_virtual_machine_id = azurerm_mssql_virtual_machine.sqlha[1].id
    role                   = "Secondary"
    commit                 = "Synchronous_Commit"
    failover_mode          = "Automatic"
    readable_secondary     = "No"
  }

  timeouts {
    create = "15m"
  }
}
