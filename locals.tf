locals {
  # Generate command to install DNS and AD Forest
  cmd00           = "Set-NetFirewallProfile -Enabled False"
  cmd01           = "Install-WindowsFeature AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools"
  cmd02           = "Install-WindowsFeature DNS -IncludeAllSubFeature -IncludeManagementTools"
  cmd03           = "Import-Module ADDSDeployment, DnsServer"
  cmd04           = "Install-ADDSForest -DomainName ${var.domain_name} -NoRebootOnCompletion:$false -Force:$true -SafeModeAdministratorPassword (ConvertTo-SecureString ${random_password.pwd.result} -AsPlainText -Force)"
  powershell_gpmc = "${local.cmd00}; ${local.cmd01}; ${local.cmd02}; ${local.cmd03}; ${local.cmd04};"

  start_tran_aduser   = "Start-Transcript -Path C:\\Temp\\transcript_aduser.txt"
  cmd05               = "Import-Module ActiveDirectory"
  cmd06               = "New-ADOrganizationalUnit -Name 'Servers' -Path '${local.dn_path}' -Description 'Servers OU for new objects'"
  cmd07               = "$secPass = ConvertTo-SecureString '${var.sql_svc_password}' -AsPlainText -Force"
  cmd08               = "New-ADUser -Name install -GivenName install -Surname install -UserPrincipalName 'install@${var.domain_name}' -SamAccountName install -AccountPassword $secPass -Enabled $true"
  cmd09               = "New-ADUser -Name sqlsvc -GivenName sqlsvc -Surname sqlsvc -UserPrincipalName 'sqlsvc@${var.domain_name}' -SamAccountName sqlsvc -AccountPassword $secPass -Enabled $true"
  stop_tran_aduser    = "Stop-Transcript"
  powershell_add_user = "${local.start_tran_aduser}; ${local.cmd05}; ${local.cmd06}; ${local.cmd07}; ${local.cmd08}; ${local.cmd09}; ${local.stop_tran_aduser}"

  # Generate locals for domain join
  split_domain    = split(".", var.domain_name)
  dn_path         = join(",", [for dc in local.split_domain : "DC=${dc}"])
  servers_ou_path = "OU=Servers,${join(",", [for dc in local.split_domain : "DC=${dc}"])}"
}
