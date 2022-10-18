param(
    [string]$SubscriptionID = "a1a98bd6-d818-4a38-93fa-acf5caf69a08"
)

# Sign in to your Azure subscription
$sub = Get-AzSubscription -ErrorAction SilentlyContinue
if(-not($sub))
{
    Connect-AzAccount
    Select-AzSubscription -Subscription $SubscriptionID
}

# If you have multiple subscriptions, set the one to use
# Select-AzSubscription -SubscriptionId <SUBSCRIPTIONID>

$resourceGroup = "WEU1RG007"
$automationAccount = "aa-sendgrid-test-weu-001"
$region = "westeurope"
$SendGridAPIKey = "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"
$VaultName = "kv-sendgrid-test-weu-001"
$userAssignedManagedIdentity = "id-sendgrid-twilio"

# Create the new key vault
$newKeyVault = New-AzKeyVault `
    -VaultName $VaultName `
    -ResourceGroupName $resourceGroup `
    -Location $region

$resourceId = $newKeyVault.ResourceId

# Convert the SendGrid API key into a SecureString
$Secret = ConvertTo-SecureString -String $SendGridAPIKey `
    -AsPlainText -Force

Set-AzKeyVaultSecret -VaultName $VaultName `
    -Name 'SendGridAPIKey' `
    -SecretValue $Secret

# Grant Key Vault access to the Automation account's system-assigned managed identity.
## Must create automation account first
$SA_PrincipalId = (Get-AzAutomationAccount `
    -ResourceGroupName $resourceGroup `
    -Name $automationAccount).Identity.PrincipalId

Set-AzKeyVaultAccessPolicy `
    -VaultName $vaultName `
    -ObjectId $SA_PrincipalId `
    -PermissionsToSecrets Set, Get

# Grant Key Vault access to the user-assigned managed identity.
## Must create if it does not exist already
$UAMI = Get-AzUserAssignedIdentity `
    -ResourceGroupName $resourceGroup `
    -Name $userAssignedManagedIdentity

Set-AzKeyVaultAccessPolicy `8c8f9837-9fb0-47ea-95c1-1559e4ab23d6
    -VaultName $vaultName `
    -ObjectId $UAMI.PrincipalId `
    -PermissionsToSecrets Set, Get

## RBAC Role

New-AzRoleAssignment `
    -ObjectId $SA_PrincipalId `
    -ResourceGroupName $resourceGroup `
    -RoleDefinitionName "Reader"

    New-AzRoleAssignment `
    -ObjectId $UAMI.PrincipalId`
    -ResourceGroupName $resourceGroup `
    -RoleDefinitionName "Reader"


## Graph permissions & module

$moduleName = 'ExchangeOnlineManagement'
$moduleVersion = '2.0.6-Preview7'
New-AzAutomationModule -AutomationAccountName $automationAccount -ResourceGroupName $resourceGroup -Name $moduleName -ContentLinkUri "https://www.powershellgallery.com/api/v2/package/$moduleName/$moduleVersion"

Connect-MgGraph
$params = @{
    ServicePrincipalId = '8c8f9837-9fb0-47ea-95c1-1559e4ab23d6' # managed identity object id
    PrincipalId = '8c8f9837-9fb0-47ea-95c1-1559e4ab23d6' # managed identity object id
    ResourceId = (Get-MgServicePrincipal -Filter "AppId eq '00000002-0000-0ff1-ce00-000000000000'").id # Exchange online
    AppRoleId = "dc50a0fb-09a3-484d-be87-e023b12c6440" # Exchange.ManageAsApp
}
New-MgServicePrincipalAppRoleAssignedTo @params

$roleId = (Get-MgRoleManagementDirectoryRoleDefinition -Filter "DisplayName eq 'Exchange Administrator'").id
New-MgRoleManagementDirectoryRoleAssignment -PrincipalId 798e77c8-a433-47b0-99db-f7667034b332 -RoleDefinitionId 29232cdf-9323-42fd-ade2-1d097af3e4de -DirectoryScopeId "/"