<#
    .DESCRIPTION
        A runbook which Starts upo all stopped VM's tagged with custom tags matching the key and value outlined below,
        using the Run As Account (Service Principal)

    .NOTES
        AUTHOR: Christopher Scott
                Microsoft Premier Field Engineer
        LASTEDIT: December 20, 2017
#>

param (
[Parameter(Mandatory=$false)] 
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [String] $connectionName = 'AzureRunAsConnection',

    [Parameter(Mandatory=$true)] 
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [String] $TagName,

    [Parameter(Mandatory=$true)] 
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [String] $TagKey
)

#If you used a custom RunAsConnection during the Automation Account setup this will need to reflect that.

try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Login-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 

}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
<#
 Get all VMs in the subscription with the Tag Tier:2 and Start them up if they are deallocated
 In this section we are filtering our Get-AzureRMVM statement by selecting VM's that have a Key of Tier and Value of 0, We also have implemented an If statement to only
 run against VMs that are already running.
#>
                                       #This is where you would set your custom Tags Keys and Values

[array]$VMs = Get-AzureRMVm -Status | `
Where-Object {$PSItem.Tags.Keys -eq $TagName -and $PSItem.Tags.Values -eq $TagKey `
-and $PSItem.PowerState -eq "VM deallocated"}
 
ForEach ($VM in $VMs)
{
    Write-Output "Starting: $($VM.Name)"
    Start-AzureRMVM -Name $VM.Name -ResourceGroupName $VM.ResourceGroupName
}     



<#
This next section is optional. Originally I used this runbook to startUp VMs in a order so at the end of the Tier 0 Runbook
I would call the Tier 1 Runbook and finally the Tier 2 runbook. For Shutdown I would reverse the order to ensure services came up correctly.
By splitting the runbooks I ensured the next set of services did not start or stop until the previous set had finished.

$NextRunbook = <Fill in Next Runbook Name for this example our next Runbook would be "Blog_Startup_Tier1">
$AutomationAccountName = <Automation Account Name ours was "BlogAutomation">
$ResourceGroup = <Automation Account ResourceGroup ours was "AzureAutomation-Blog">

Start-AzureRmAutomationRunbook -Name $NextRunbook -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroup 

#>



