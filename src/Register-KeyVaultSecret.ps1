$SendGridAPIKey = "<Paste your API code here>"
$VaultName = "<Enter keyvault name here>"

Connect-AzAccount #Login to Azure through Powershell

# Convert the SendGrid API key into a SecureString
$Secret = ConvertTo-SecureString -String $SendGridAPIKey `
    -AsPlainText -Force

# Create the Keyvault Secret
Set-AzKeyVaultSecret -VaultName $VaultName `
    -Name 'SendGridAPIKey' `
    -SecretValue $Secret