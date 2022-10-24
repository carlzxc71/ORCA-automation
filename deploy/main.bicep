// PARAMETERS

@description('Location of rsources')
param location string = resourceGroup().location

@description('Enter the name of Automation Account')
param azureAutomationAccountName string = 'aa-sendgrid-test-weu-002'

resource azureAutomationAccount 'Microsoft.Automation/automationAccounts@2022-08-08' = {
  name: azureAutomationAccountName
  location: location
  properties: {
    publicNetworkAccess: true
    disableLocalAuth: false 
    encryption: {
      identity: {
        
      }
      keySource: 'Microsoft.Automation'
    }
    sku: {
      name: 'Basic'
    }  
  }
}
