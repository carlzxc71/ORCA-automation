// PARAMETERS

@description('Location of rsources')
param location string = resourceGroup().location

@description('Enter the name of Automation Account')
param azureAutomationAccountName string = 'aa-sendgrid-test-weu-001'

@description('Name of the Virtual Machine')
param automationVMName string = 'vm-orca-prod-weu-001'

@description('Name of the Automation VM Admin')
param automationVMAdmin string = 'orca-admin001'

@description('Password of the VM Admin account')
@secure()
param automnationVMPassword string

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

// RESOURCES - Virtual Machine

resource automationVM 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: automationVMName  
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-datacenter-gensecond'
        version: 'latest'
      }
    }
    osProfile: {
      adminUsername: automationVMAdmin
      adminPassword: automnationVMPassword
    }
  }
}
