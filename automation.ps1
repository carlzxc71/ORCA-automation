## Parameters

Param(
  [Parameter(Mandatory=$false)]
  [String] $destEmailAddress = "carl.lindberg@iver.se",
  [Parameter(Mandatory=$false)]
  [String] $fromEmailAddress = "automation@hultaforsgroup.com",
  [Parameter(Mandatory=$false)]
  [String] $subject = "Automated ORCA report",
  [Parameter(Mandatory=$false)]
  [String] $content = "Test content",
  [Parameter(Mandatory=$false)]
  [String] $ResourceGroupName
)

# Import Exchange & ORCA modules and connect using managed identity

Get-PSSession | Remove-PSSession
Import-Module -Name ExchangeOnlineManagement
Import-Module -Name ORCA
Connect-ExchangeOnline -ManagedIdentity -Organization "hultafors.onmicrosoft.com" -ManagedIdentityAccountId "a9ee5800-40ef-4c78-8d92-d7ac4baf5a4b"

# Get the ORCA report

$attachment = Invoke-ORCA -Output HTML -OutputOptions @{HTML=@{OutputDirectory=$outputPath}} 

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

# Connect to Azure with system-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity).context

# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext 

$VaultName = "kv-sendgrid-test-weu-001"

$SENDGRID_API_KEY = Get-AzKeyVaultSecret `
    -VaultName $VaultName `
    -Name "SendGridAPIKey" `
    -AsPlainText -DefaultProfile $AzureContext

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer " + $SENDGRID_API_KEY)
$headers.Add("Content-Type", "application/json")

$body = @{
personalizations = @(
    @{
        to = @(
                @{
                    email = $destEmailAddress
                }
        )
    }
)
from = @{
    email = $fromEmailAddress
}
subject = $subject
attachment = $attachment.result
content = @(
    @{
        type = "text/plain"
        value = $content
    }
)
}

$bodyJson = $body | ConvertTo-Json -Depth 4

$response = Invoke-RestMethod -Uri https://api.sendgrid.com/v3/mail/send -Method Post -Headers $headers -Body $bodyJson