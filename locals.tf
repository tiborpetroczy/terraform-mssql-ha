locals {
  # Generate locals for domain join parameters
  split_domain    = split(".", var.domain_name)
  dn_path         = join(",", [for dc in local.split_domain : "DC=${dc}"])
  servers_ou_path = "OU=Servers,${join(",", [for dc in local.split_domain : "DC=${dc}"])}"

  # Generate commands to install DNS and AD Forest
  powershell_gpmc = [
    "Set-NetFirewallProfile -Enabled False",
    "Install-WindowsFeature AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools",
    "Install-WindowsFeature DNS -IncludeAllSubFeature -IncludeManagementTools",
    "Import-Module ADDSDeployment, DnsServer",
    "Install-ADDSForest -DomainName ${var.domain_name} -NoRebootOnCompletion:$false -Force:$true -SafeModeAdministratorPassword (ConvertTo-SecureString ${random_password.pwd.result} -AsPlainText -Force)"
  ]
  #powershell_gpmc_joined = join(";", local.powershell_gpmc)

  # Generate commands to create new Organization Unit and technical users for SQL installation
  powershell_add_users = [
    "Start-Transcript -Path C:\\Temp\\transcript_aduser.txt",
    "Import-Module ActiveDirectory",
    "New-ADOrganizationalUnit -Name 'Servers' -Path '${local.dn_path}' -Description 'Servers OU for new objects'",
    "$secPass = ConvertTo-SecureString '${var.sql_service_account_password}' -AsPlainText -Force",
    "New-ADUser -Name install -GivenName install -Surname install -UserPrincipalName 'install@${var.domain_name}' -SamAccountName install -AccountPassword $secPass -Enabled $true",
    "New-ADUser -Name sqlsvc -GivenName sqlsvc -Surname sqlsvc -UserPrincipalName 'sqlsvc@${var.domain_name}' -SamAccountName sqlsvc -AccountPassword $secPass -Enabled $true",
    "Add-ADGroupMember -Identity 'Domain Admins' -Members install",
    "Stop-Transcript"
  ]

  # Generate commands to add install domain account to local administrators group on SQL servers and to sysadmin roles on SQL
  powershell_local_admin = [
    "Start-Transcript -Path C:\\Temp\\transcript_local_admin.txt",
    "Get-LocalGroup",
    "Add-LocalGroupMember -Group 'Administrators' -Member '${var.domain_netbios_name}\\install'",
    "Stop-Transcript"
  ]

  # Generate commands to add install domain account to sysadmin roles on SQL servers
  powershell_sql_sysadmin = [
    "Start-Transcript -Path C:\\Temp\\transcript_sql_sysadmin.txt",
    "Invoke-Sqlcmd -ServerInstance 'localhost' -Database 'master' -Query 'CREATE LOGIN [SQLHALAB\\install] FROM WINDOWS WITH DEFAULT_DATABASE=[master]; EXEC master..sp_addsrvrolemember @loginame = ''SQLHALAB\\install'', @rolename = ''sysadmin'';' -QueryTimeout '10'",
    "Stop-Transcript"
  ]

  # Generate commands to add special ACL permission to cluster computer object
  powershell_acl_commands = [
    "Start-Transcript -Path C:\\Temp\\transcript_acl.txt",
    "$Computer = Get-ADComputer ${var.sqlcluster_name}",
    "$ComputerSID = [System.Security.Principal.SecurityIdentifier] $Computer.SID",
    "$ACL = Get-Acl -Path 'AD:${local.servers_ou_path}'",
    "$Identity = [System.Security.Principal.IdentityReference] $ComputerSID",
    "$ADRight = [System.DirectoryServices.ActiveDirectoryRights] 'GenericAll'",
    "$Type = [System.Security.AccessControl.AccessControlType] 'Allow'",
    "$InheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] 'All'",
    "$Rule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($Identity, $ADRight, $Type,  $InheritanceType)",
    "$ACL.AddAccessRule($Rule)",
    "Set-Acl -Path 'AD:${local.servers_ou_path}' -AclObject $ACL",
    "Stop-Transcript"
  ]
}
