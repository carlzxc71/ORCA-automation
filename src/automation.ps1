 ## Parameters

 Param(
    [String] $destEmailAddress = "<enter destination email>",
    [String] $fromEmailAddress = "<enter from email address, automation@domain.com>",
    [String] $subject = "Automated ORCA report",
    [String] $content = "Hello, attached is your ORCA-report.",
    [String] $azureKeyVault = "<enter name of your keyvault>",
    [String] $onmicrosoftDomain = "<changeme.onmicrosoft.com>" 

)
  
# Connect to Exchange Online and extract the ORCA report
Connect-ExchangeOnline -ManagedIdentity -Organization $onmicrosoftDomain

# If -ManagedIdentity wont work and you need to configure auth using an app registration and certificate instead: https://learn.microsoft.com/en-us/powershell/exchange/app-only-auth-powershell-v2?view=exchange-ps
# Connect-ExchangeOnline -CertificateThumbPrint "<certificate thumbprint>" -AppID "<application ID>" -Organization $onmicrosoftDomain  

$attachment = Invoke-ORCA -Output HTML -OutputOptions @{HTML = @{DisplayReport = $False } } 
  
# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process
  
# Connect to Azure with system-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity).context
  
# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext  -ErrorAction SilentlyContinue 
  
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
 
