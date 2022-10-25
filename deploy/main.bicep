// PARAMETERS

@description('Location of rsources')
param location string = resourceGroup().location

@description('Enter the name of Automation Account')
param azureAutomationAccountName string = 'aa-sendgrid-test-weu-001'

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
