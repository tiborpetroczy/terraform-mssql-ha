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

variable "sql_svc_password" {
  type        = string
  description = "(Required) The default password for default SQL service accounts (local and domain)."
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
