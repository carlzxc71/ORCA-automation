[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string] $vmName = "vm-sendgrid-test-weu-001",
    [Parameter(Mandatory=$false)]
    [string] $resourceGroupName = "WEU1RG007"
)

$ProgressPreference="silentlyContinue"

Disable-AzContextAutosave -Scope Process
  
# Connect to Azure with system-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity).context
  
# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext 

# Stop the VM
Start-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -Confirm:$false