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

- __Existing Azure Subscription__: Before you can leverage Terraform with Azure, you need to have an active Azure subscription.

- __Service Principal__: It's essential to have a suitable Service Principal set up within Azure. This will allow Terraform to interact with Azure resources on your behalf.

Configuration:

- __Terraform Variables__: All necessary variables should be defined and set within the `terraform.tfvars` file. This file is where you'll provide all your specific configurations that Terraform scripts will use during execution.

Running Terraform:

- __Initialization__: If you're running Terraform for the first time in a new directory, use the command `terraform init`. This will set up the necessary providers and modules.

- __Planning Phase__: Before applying any changes, it's a good practice to see a summary of the changes that will be made. Use the command `terraform plan`.

- __Apply Changes__: To execute your Terraform scripts and apply changes to your Azure environment, use the command `terraform apply`.

Make sure to review the changes Terraform plans to make and approve them before they're applied.

