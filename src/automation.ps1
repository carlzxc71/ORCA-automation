## Parameters

Param(
    [Parameter(Mandatory = $false)]
    [String] $destEmailAddress = "carl.lindberg@iver.se",
    [Parameter(Mandatory = $false)]
    [String] $fromEmailAddress = "automation@hultaforsgroup.com",
    [Parameter(Mandatory = $false)]
    [String] $subject = "Automated ORCA report",
    [Parameter(Mandatory = $false)]
    [String] $content = "Hello, attached is your ORCA-report.",
    [Parameter(Mandatory = $false)]
    [String] $ResourceGroupName,
    [Parameter(Mandatory = $true)]
    [String] $azureKeyVault = "kv-sendgrid-test-weu-001"
)
  
# Import Exchange & ORCA modules and connect using managed identity
  
if (!(Get-Module -Name ExchangeOnlineManagement)) {
      
    Install-Module ExchangeOnlineManagement -Force
}
  
if (!(Get-Module -Name ORCA)) {
      
    Install-Module ORCA -Force
}
  
if (!(Get-Module -Name Az)) {
      
    Install-Module Az -Force
}
  
Import-Module -Name ExchangeOnlineManagement
Import-Module -Name ORCA
Import-Module -Name Az
Connect-ExchangeOnline -ManagedIdentity -Organization "hultafors.onmicrosoft.com"
  
# Get the ORCA report
  
$attachment = Invoke-ORCA -Output HTML -OutputOptions @{HTML = @{DisplayReport = $False } } 
  
# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process
  
# Connect to Azure with system-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity).context
  
# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext 
  
$VaultName = $azureKeyVault
  
$SENDGRID_API_KEY = Get-AzKeyVaultSecret `
    -VaultName $VaultName `
    -Name "SendGridAPIKey" `
    -AsPlainText -DefaultProfile $AzureContext
  
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer " + $SENDGRID_API_KEY)
$headers.Add("Content-Type", "application/json")
  
#Convert File to Base64
$FileContent = get-content $attachment.result
$ConvertToBytes = [System.Text.Encoding]::UTF8.GetBytes($FileContent)
$EncodedFile = [System.Convert]::ToBase64String($ConvertToBytes)
  
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
    from             = @{
        email = $fromEmailAddress
    }
    subject          = $subject
    attachments      = @(
      
        @{
          
            "content"     = $EncodedFile
            "filename"    = "ORCA-report.html"
            "type"        = "text/html"
            "disposition" = "attachment"
        }
    )
    content          = @(
        @{
            type  = "text/plain"
            value = $content
        }
    )
}
  
  
$bodyJson = $body | ConvertTo-Json -Depth 4
  
$response = Invoke-RestMethod -Uri https://api.sendgrid.com/v3/mail/send -Method Post -Headers $headers -Body $bodyJson
