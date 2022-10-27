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
    [Parameter(Mandatory = $false)]
    [String] $azureKeyVault = "kv-sendgrid-test-weu-001"
)
  
# Check to install any missing dependencies

# [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# if (!(Get-Module -ListAvailable -Name Nuget)) {
      
#     Install-PackageProvider -Name NuGet -Confirm:$false -Force
#     Install-Module NuGet -Confirm:$false -Force
# }

  
# if (!(Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
      
#     Install-Module ExchangeOnlineManagement -Confirm:$false -Force
# }
  
# if (!(Get-Module -ListAvailable -Name ORCA)) {
      
#     Install-Module ORCA -Confirm:$false -Force
# }
  
# if (!(Get-Module -ListAvailable -Name Az.Accounts)) {
      
#     Install-Module Az.Accounts -Confirm:$false -Force
# }
  
# Connect to Exchange Online and extract the ORCA report
Connect-ExchangeOnline -ManagedIdentity -Organization "hultafors.onmicrosoft.com"
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
 
