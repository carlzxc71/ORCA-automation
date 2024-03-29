// PARAMETERS

@description('Location of rsources')
param location string = resourceGroup().location

@description('Enter the name of Automation Account')
param azureAutomationAccountName string

@description('Enter Admin name of Automation VM')
param automationVMAdmin string = 'orcaadmin'

@description('Enter the password for VM Admin')
@secure()
param automationVMAdminPassword string

@description('The DNS label prefix for the VM')
param dnsLabelPrefix string = toLower('${automationVMName}-${uniqueString(resourceGroup().id, automationVMName)}')

@description('The name of the VM public IP')
param publicIpName string = 'myPublicIP'
@allowed([
  'Dynamic'
  'Static'
])

@description('The allocation method for the VM')
param publicIPAllocationMethod string = 'Dynamic'

@description('Enter public IP SKU')
@allowed([
  'Basic'
  'Standard'
])
param publicIpSku string = 'Basic'

@description('The OS version')
param OSVersion string = '2019-datacenter-gensecond'

@description('Size of the VM')
param vmSize string = 'Standard_B2s'

@description('The name of the VM used for automation')
param automationVMName string

@description('Enter keyvault name')
param keyVaultName string


// RESOURCES - Azure Automation Account

resource azureAutomationAccount 'Microsoft.Automation/automationAccounts@2021-06-22' = {
  name: azureAutomationAccountName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: true
    disableLocalAuth: false 
    encryption: {
      keySource: 'Microsoft.Automation'
    }
    sku: {
      name: 'Basic'
    }  
  }
  tags: {
    orcaAutomatedResource: 'true'
  }
}

resource automationRunbookStartVM 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  name: 'Start-VM'
  parent: azureAutomationAccount
  location: location
  properties: {
    runbookType: 'PowerShell7'
  }
  tags: {
    orcaAutomatedResource: 'true'
  }
}

resource automationRunbookStopVM 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  name: 'Stop-VM'
  parent: azureAutomationAccount
  location: location
  properties: {
    runbookType: 'PowerShell7'
  }
  tags: {
    orcaAutomatedResource: 'true'
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: [
      {
        objectId: automationVMDeployment.outputs.systemManagedIdentity
        permissions: {
          secrets: [
            'get'
            'set'
          ]
        }
        tenantId: subscription().tenantId
      }
    ]
    tenantId: subscription().tenantId
  }
  tags: {
    orcaAutomatedResource: 'true'
  }
}

resource vmContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '9980e02c-c2be-4d73-94e8-173b1dc7cf3c'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, azureAutomationAccount.id, vmContributorRoleDefinition.id)
  scope: resourceGroup()
  properties: {
    principalId: azureAutomationAccount.identity.principalId
    roleDefinitionId: vmContributorRoleDefinition.id
    principalType: 'ServicePrincipal'
  }
}

// MODULES

module automationVMDeployment 'modules/vm.bicep' = {
  name: 'vmDeployment'
  params: {
    location: location
    automationVMAdmin: automationVMAdmin
    automationVMAdminPassword: automationVMAdminPassword
    OSVersion: OSVersion
    publicIPAllocationMethod: publicIPAllocationMethod 
    publicIpName: publicIpName
    publicIpSku: publicIpSku
    automationVMName: automationVMName
    dnsLabelPrefix: dnsLabelPrefix
    vmSize: vmSize
  }
}

// OUTPUTS

output keyVaultName string = keyVault.name
output automationAccountNameOutput string = azureAutomationAccount.name
