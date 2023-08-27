tenant_id       = ""
subscription_id = ""
client_id       = ""
client_secret   = ""

location            = "westeurope"
resource_group_name = "rg-sqlha-lab"
domain_name         = "sqlhalab.org"
domain_netbios_name = "SQLHALAB"

dc_vm_size  = "Standard_F2s_v2"
sql_vm_size = "Standard_F2s_v2"

admin_username = "azureadmin"

sqlha_count = 2

sql_vm_image_publisher = "MicrosoftSQLServer"
sql_vm_image_offer     = "sql2022-ws2022"
sql_vm_image_sku       = "sqldev-gen2"

sqlcluster_name              = "sqlhacluster"
sqldatafilepath              = "K:\\Data"
sqllogfilepath               = "L:\\Logs"
sqltempfilepath              = "T:\\Temp"
sql_sysadmin_login           = "sqllogin"
sql_sysadmin_password        = "Password2023"
sql_service_account_password = "Password2023"
sql_image_offer              = "SQL2022-WS2022"
sql_image_sku                = "Developer"

