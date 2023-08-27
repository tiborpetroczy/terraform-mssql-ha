variable "tenant_id" {
  type        = string
  description = "(Required) The ID of target tenant where subscription runs."
}

variable "subscription_id" {
  type        = string
  description = "(Required) The ID of target subscription where all resources will be created."
}

variable "client_id" {
  type        = string
  description = "(Required) The ID of services principal that will run all processes in the subscription."
}

variable "client_secret" {
  type        = string
  sensitive   = true
  description = "(Required) The passowrd of service principal."
}

variable "location" {
  description = "Specifies the location for the resource group and all the resources"
  type        = string
}

variable "resource_group_name" {
  description = "Specifies the resource group name"
  type        = string
}

variable "dc_vm_size" {
  type        = string
  description = "size of the Domain Controller Virtual Machine(s) type."
}

variable "sql_vm_size" {
  type        = string
  description = "The size of the SQL Virtual Machine(s) type."
}

variable "sql_vm_image_publisher" {
  type        = string
  description = "(Required) Specifies the publisher of the image used to create the virtual machines. Changing this forces a new resource to be created."
}

variable "sql_vm_image_offer" {
  type        = string
  description = "(Required) Specifies the offer of the image used to create the virtual machines. Changing this forces a new resource to be created."
}

variable "sql_vm_image_sku" {
  type        = string
  description = "(Required) Specifies the SKU of the image used to create the virtual machines. Changing this forces a new resource to be created."
}

variable "admin_username" {
  type        = string
  description = "(Required) The username of the local administrator used for the Virtual Machine. Changing this forces a new resource to be created."
}

variable "sqlcluster_name" {
  type        = string
  description = "(Required) The default name of failover SQL Cluster."
}

variable "sqldatafilepath" {
  type        = string
  description = "(Required) The SQL Server default data path"
}

variable "sqllogfilepath" {
  type        = string
  description = "(Required) The SQL Server default log path"
}

variable "sqltempfilepath" {
  type        = string
  description = "(Required) The SQL Server default temp path"
}

variable "sql_sysadmin_login" {
  type        = string
  description = "(Required) The SQL Server sysadmin login to create."
}

variable "sql_sysadmin_password" {
  type        = string
  description = "(Required) The SQL Server sysadmin password to create."
}

variable "sql_service_account_password" {
  type        = string
  description = "(Required) The SQL Server service account password to create."
}

variable "sql_image_offer" {
  type        = string
  description = "(Required) The offer type of the marketplace image cluster to be used by the SQL Virtual Machine Group. Changing this forces a new resource to be created."
}

variable "sql_image_sku" {
  type        = string
  description = " (Required) The sku type of the marketplace image cluster to be used by the SQL Virtual Machine Group. Possible values are Developer and Enterprise."
}

variable "domain_name" {
  type        = string
  description = "(Required) The base domain name (e.g: sqlhalab.org)"
}

variable "domain_netbios_name" {
  type        = string
  description = "(Required) The default NetBIOS name based on domain_name variable (e.g: sqlhalab.org - SQLHALAB)"
}

variable "sqlha_count" {
  type        = number
  description = "The number of SQL HA virtual machine - Currently only supported 2!"
  default     = 2
}
