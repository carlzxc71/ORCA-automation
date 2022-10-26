// PARAMETERS

@description('Location of rsources')
param location string = resourceGroup().location

@description('Enter the name of Automation Account')
param azureAutomationAccountName string = 'aa-sendgrid-test-weu-001'

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
@allowed([
  'Basic'
  'Standard'
])
param publicIpSku string = 'Basic'

@description('The OS version')
@allowed([
  '2022-datacenter-smalldisk-g2'
  '2019-datacenter-gensecond'
])
param OSVersion string = '2019-datacenter-gensecond'

@description('Size of the VM')
param vmSize string = 'Standard_B2s'

@description('The name of the VM used for automation')
param automationVMName string = 'vm-orca-weu-001'

@description('Enter keyvault name')
param keyVaultName string = 'kv-orca-prod-weu-001'


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
}

resource automationRunbookStartVM 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  name: 'Start-VM'
  parent: azureAutomationAccount
  location: location
  properties: {
    runbookType: 'PowerShell7'
  }
}

resource automationRunbookStopVM 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  name: 'Stop-VM'
  parent: azureAutomationAccount
  location: location
  properties: {
    runbookType: 'PowerShell7'
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
