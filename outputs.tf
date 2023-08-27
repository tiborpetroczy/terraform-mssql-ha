output "client_public_ip" {
  value       = chomp(data.http.myip.response_body)
  description = "The public IP address of local developer machine."
}

output "primary_dc_private_ip_address" {
  value       = azurerm_network_interface.dc1.ip_configuration[0].private_ip_address
  description = "The private IP address of primary Domain Controller."
}

output "storage_account_fqdn" {
  value       = azurerm_storage_account.stga.primary_blob_host
  description = "The hostname with port if applicable for blob storage in the primary location."
}

output "storage_account_endpoint" {
  value       = azurerm_storage_account.stga.primary_blob_endpoint
  description = "The endpoint URL for blob storage in the primary location."
}

# output "mssql_vm_ids" {
#   value       = azurerm_mssql_virtual_machine.sqlha[*].id
#   description = "The IDs of the SQL Virtual Machines."
# }

# output "aag_listner_id" {
#   value       = azurerm_mssql_virtual_machine_availability_group_listener.aag.id
#   description = "The ID of the Microsoft SQL Virtual Machine Availability Group Listener."
# }