[CmdletBinding()]
param (
    [string] $vmName = "<Enter your VM name here>",
    [string] $resourceGroupName = "<Enter your RG here>"
)

$ProgressPreference="silentlyContinue"

Disable-AzContextAutosave -Scope Process
  
# Connect to Azure with system-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity).context
  
# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext 

# Stop the VM
Stop-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -Confirm:$false -Force