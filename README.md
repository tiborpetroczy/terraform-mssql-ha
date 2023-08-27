<!-- BEGIN_TF_DOCS -->
<!-- Define here the title and introduction of the module -->

# SQL Always-On Availability Group with Terrform

This documentation specifically delves into how Terraform can be harnessed to seamlessly provision an SQL Always-On Availability Group (AG) in an Azure environment. SQL Always-On AG is a high-availability feature that offers a combination of replication, failover, and read-access functionalities for SQL databases. Establishing such a sophisticated setup manually can be fraught with challenges and inconsistencies.

The most important components will be created by Terraform:

- Virtual networks and subnets
- Storage account
- Virtual machine for domain controller role
- Virtual machines for SQL HA roles
- Azure based SQL virtual machine extension
- Always-On availability resource

## Using Terraform with Azure

Prerequisites:

- \_\_Existing Azure Subscription\_\_: Before you can leverage Terraform with Azure, you need to have an active Azure subscription.

- \_\_Service Principal\_\_: It's essential to have a suitable Service Principal set up within Azure. This will allow Terraform to interact with Azure resources on your behalf.

Configuration:

- \_\_Terraform Variables\_\_: All necessary variables should be defined and set within the `terraform.tfvars` file. This file is where you'll provide all your specific configurations that Terraform scripts will use during execution.

Running Terraform:

- \_\_Initialization\_\_: If you're running Terraform for the first time in a new directory, use the command `terraform init`. This will set up the necessary providers and modules.

- \_\_Planning Phase\_\_: Before applying any changes, it's a good practice to see a summary of the changes that will be made. Use the command `terraform plan`.

- \_\_Apply Changes\_\_: To execute your Terraform scripts and apply changes to your Azure environment, use the command `terraform apply`.

Make sure to review the changes Terraform plans to make and approve them before they're applied.

## Parameters

### Required Inputs

The following input variables are required:

#### <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username)

Description: (Required) The username of the local administrator used for the Virtual Machine. Changing this forces a new resource to be created.

Type: `string`

#### <a name="input_client_id"></a> [client\_id](#input\_client\_id)

Description: (Required) The ID of services principal that will run all processes in the subscription.

Type: `string`

#### <a name="input_client_secret"></a> [client\_secret](#input\_client\_secret)

Description: (Required) The passowrd of service principal.

Type: `string`

#### <a name="input_dc_vm_size"></a> [dc\_vm\_size](#input\_dc\_vm\_size)

Description: size of the Domain Controller Virtual Machine(s) type.

Type: `string`

#### <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name)

Description: (Required) The base domain name (e.g: sqlhalab.org)

Type: `string`

#### <a name="input_domain_netbios_name"></a> [domain\_netbios\_name](#input\_domain\_netbios\_name)

Description: (Required) The default NetBIOS name based on domain\_name variable (e.g: sqlhalab.org - SQLHALAB)

Type: `string`

#### <a name="input_location"></a> [location](#input\_location)

Description: Specifies the location for the resource group and all the resources

Type: `string`

#### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: Specifies the resource group name

Type: `string`

#### <a name="input_sql_image_offer"></a> [sql\_image\_offer](#input\_sql\_image\_offer)

Description: (Required) The offer type of the marketplace image cluster to be used by the SQL Virtual Machine Group. Changing this forces a new resource to be created.

Type: `string`

#### <a name="input_sql_image_sku"></a> [sql\_image\_sku](#input\_sql\_image\_sku)

Description:  (Required) The sku type of the marketplace image cluster to be used by the SQL Virtual Machine Group. Possible values are Developer and Enterprise.

Type: `string`

#### <a name="input_sql_service_account_password"></a> [sql\_service\_account\_password](#input\_sql\_service\_account\_password)

Description: (Required) The SQL Server service account password to create.

Type: `string`

#### <a name="input_sql_sysadmin_login"></a> [sql\_sysadmin\_login](#input\_sql\_sysadmin\_login)

Description: (Required) The SQL Server sysadmin login to create.

Type: `string`

#### <a name="input_sql_sysadmin_password"></a> [sql\_sysadmin\_password](#input\_sql\_sysadmin\_password)

Description: (Required) The SQL Server sysadmin password to create.

Type: `string`

#### <a name="input_sql_vm_image_offer"></a> [sql\_vm\_image\_offer](#input\_sql\_vm\_image\_offer)

Description: (Required) Specifies the offer of the image used to create the virtual machines. Changing this forces a new resource to be created.

Type: `string`

#### <a name="input_sql_vm_image_publisher"></a> [sql\_vm\_image\_publisher](#input\_sql\_vm\_image\_publisher)

Description: (Required) Specifies the publisher of the image used to create the virtual machines. Changing this forces a new resource to be created.

Type: `string`

#### <a name="input_sql_vm_image_sku"></a> [sql\_vm\_image\_sku](#input\_sql\_vm\_image\_sku)

Description: (Required) Specifies the SKU of the image used to create the virtual machines. Changing this forces a new resource to be created.

Type: `string`

#### <a name="input_sql_vm_size"></a> [sql\_vm\_size](#input\_sql\_vm\_size)

Description: The size of the SQL Virtual Machine(s) type.

Type: `string`

#### <a name="input_sqlcluster_name"></a> [sqlcluster\_name](#input\_sqlcluster\_name)

Description: (Required) The default name of failover SQL Cluster.

Type: `string`

#### <a name="input_sqldatafilepath"></a> [sqldatafilepath](#input\_sqldatafilepath)

Description: (Required) The SQL Server default data path

Type: `string`

#### <a name="input_sqllogfilepath"></a> [sqllogfilepath](#input\_sqllogfilepath)

Description: (Required) The SQL Server default log path

Type: `string`

#### <a name="input_sqltempfilepath"></a> [sqltempfilepath](#input\_sqltempfilepath)

Description: (Required) The SQL Server default temp path

Type: `string`

#### <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id)

Description: (Required) The ID of target subscription where all resources will be created.

Type: `string`

#### <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id)

Description: (Required) The ID of target tenant where subscription runs.

Type: `string`

### Optional Inputs

The following input variables are optional (have default values):

#### <a name="input_sqlha_count"></a> [sqlha\_count](#input\_sqlha\_count)

Description: The number of SQL HA virtual machine - Currently only supported 2!

Type: `number`

Default: `2`

### Outputs

The following outputs are exported:

#### <a name="output_client_public_ip"></a> [client\_public\_ip](#output\_client\_public\_ip)

Description: The public IP address of local developer machine.

#### <a name="output_primary_dc_private_ip_address"></a> [primary\_dc\_private\_ip\_address](#output\_primary\_dc\_private\_ip\_address)

Description: The private IP address of primary Domain Controller.

#### <a name="output_storage_account_endpoint"></a> [storage\_account\_endpoint](#output\_storage\_account\_endpoint)

Description: The endpoint URL for blob storage in the primary location.

#### <a name="output_storage_account_fqdn"></a> [storage\_account\_fqdn](#output\_storage\_account\_fqdn)

Description: The hostname with port if applicable for blob storage in the primary location.
<!-- END_TF_DOCS -->