terraform {
  backend "azurerm" {}
 }

# Create resource group
resource "azurerm_resource_group" "terraformrg" {
  name                  = "${var.ResGroup}"
  location              = "${var.Location}"

  tags {
    description = "${var.Description}"
    environment = "${var.Environment}"
  }
}

resource "azurerm_automation_account" "terraformautoaccount" {
  depends_on          =  ["azurerm_resource_group.terraformrg"]
  name                = "${var.AutomationAccount}"
  location            = "${var.Location}"
  resource_group_name = "${var.ResGroup}"

  sku {
    name = "Basic"
  }

  tags {
    description = "${var.Description}"
    environment = "${var.Environment}"
  }
}

resource "null_resource" "createrunasaccount" {
  depends_on          =  ["azurerm_automation_account.terraformautoaccount"]
  provisioner "local-exec" {
    command             = ".\\files\\runasaccount.ps1 -ResourceGroup ${var.ResGroup} -AutomationAccountName ${var.AutomationAccount} -SubscriptionId ${var.SubscriptionId} -ApplicationDisplayName ${var.AppName} -SelfSignedCertPlainPassword ${var.CertPassword} -CreateClassicRunAsAccount $false"
    interpreter         = ["PowerShell"]
  }
} 

data "local_file" "terraformstartfile" {
  filename = "./files/DDCustomTaggedStartUp.ps1"
  }

resource "azurerm_automation_runbook" "exaterraformstartscript" {
  depends_on          =  ["azurerm_automation_account.terraformautoaccount"]
  name                = "AutomatedVMStart"
  location            = "${var.Location}"
  resource_group_name = "${var.ResGroup}"
  account_name        = "${azurerm_automation_account.terraformautoaccount.name}"
  log_verbose         = "false"
  log_progress        = "true"
  description         = "Azure Start VM Runbook"
  runbook_type        = "PowerShell"

  publish_content_link {
    uri = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-automation-runbook-getvms/Runbooks/Get-AzureVMTutorial.ps1"
  }
  content = "${data.local_file.terraformstartfile.content}"

  tags {
    description = "${var.Description}"
    environment = "${var.Environment}"
  }
}

data "local_file" "terraformstopfile" {
  filename = "./files/DDCustomTaggedShutdown.ps1"
  }

resource "azurerm_automation_runbook" "exaterraformstopscript" {
  depends_on          =  ["azurerm_automation_account.terraformautoaccount"]
  name                = "AutomatedVMStop"
  location            = "${var.Location}"
  resource_group_name = "${var.ResGroup}"
  account_name        = "${azurerm_automation_account.terraformautoaccount.name}"
  log_verbose         = "false"
  log_progress        = "true"
  description         = "Azure Stop VM Runbook"
  runbook_type        = "PowerShell"

  publish_content_link {
    uri = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-automation-runbook-getvms/Runbooks/Get-AzureVMTutorial.ps1"
  }
  content = "${data.local_file.terraformstopfile.content}"

  tags {
    description = "${var.Description}"
    environment = "${var.Environment}"
  }
}

data "local_file" "terraformupdatemodsfile" {
  filename = "./files/Update-AzureModule.ps1"
  }

resource "azurerm_automation_runbook" "exaterraformupdatemodscript" {
  depends_on          =  ["azurerm_automation_account.terraformautoaccount"]
  name                = "UpdateAzureModules"
  location            = "${var.Location}"
  resource_group_name = "${var.ResGroup}"
  account_name        = "${azurerm_automation_account.terraformautoaccount.name}"
  log_verbose         = "false"
  log_progress        = "true"
  description         = "Azure Update Modules Runbook"
  runbook_type        = "PowerShell"

  publish_content_link {
    uri = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-automation-runbook-getvms/Runbooks/Get-AzureVMTutorial.ps1"
  }
  content = "${data.local_file.terraformupdatemodsfile.content}"

  tags {
    description = "${var.Description}"
    environment = "${var.Environment}"
  }
}

resource "null_resource" "createstartschedule" {
  depends_on          =  ["azurerm_automation_account.terraformautoaccount"]
  provisioner "local-exec" {
    command             = "$StartDateTime = (get-date ${var.StartTime}).AddDays(+1); New-AzureRMAutomationSchedule –AutomationAccountName ${var.AutomationAccount} –Name AutomatedVMStartSchedule -StartTime $StartDateTime -DayInterval 1 -ResourceGroupName ${var.ResGroup} -TimeZone \"New Zealand Standard Time\""
    interpreter         = ["PowerShell", "-Command"]
  }
}

resource "null_resource" "createstopschedule" {
  depends_on          =  ["azurerm_automation_account.terraformautoaccount"]
  provisioner "local-exec" {
    command             = "$StopDateTime = (get-date ${var.StopTime}).AddDays(+1); New-AzureRMAutomationSchedule –AutomationAccountName ${var.AutomationAccount} –Name AutomatedVMStopSchedule -StartTime $StopDateTime -DayInterval 1 -ResourceGroupName ${var.ResGroup} -TimeZone \"New Zealand Standard Time\""
    interpreter         = ["PowerShell", "-Command"]
  }
}

resource "null_resource" "linkingstartschedule" {
  depends_on          =  ["null_resource.createstartschedule"]
  provisioner "local-exec" {
    command             = "$params = @{\"TagName\"=\"${var.TagName}\";\"TagKey\"=\"${var.TagKey}\"}; Register-AzureRmAutomationScheduledRunbook –AutomationAccountName ${var.AutomationAccount} –Name ${azurerm_automation_runbook.exaterraformstartscript.name} –ScheduleName AutomatedVMStartSchedule –Parameters $params -ResourceGroupName ${var.ResGroup}"
    interpreter         = ["PowerShell", "-Command"]
  }
}

resource "null_resource" "linkingstopschedule" {
  depends_on          =  ["null_resource.createstopschedule"]
  provisioner "local-exec" {
    command             = "$params = @{\"TagName\"=\"${var.TagName}\";\"TagKey\"=\"${var.TagKey}\"}; Register-AzureRmAutomationScheduledRunbook –AutomationAccountName ${var.AutomationAccount} –Name ${azurerm_automation_runbook.exaterraformstopscript.name} –ScheduleName AutomatedVMStopSchedule –Parameters $params -ResourceGroupName ${var.ResGroup}"
    interpreter         = ["PowerShell", "-Command"]
  }
}

resource "null_resource" "updatingazuremodules" {
  depends_on          =  ["null_resource.createrunasaccount"]
  provisioner "local-exec" {
    command             = "$params = @{\"AutomationResourceGroup\"=\"${var.ResGroup}\";\"AutomationAccount\"=\"${var.AutomationAccount}\"}; Start-AzureRmAutomationRunbook -AutomationAccount ${var.AutomationAccount} -ResourceGroupName ${var.ResGroup} -Name ${azurerm_automation_runbook.exaterraformupdatemodscript.name} –Parameters $params"
    interpreter         = ["PowerShell", "-Command"]
  }
}
