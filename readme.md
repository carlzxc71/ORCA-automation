# Introduction

This project allows you to implement the required services and activate a system that will run your EOP configuration and match it with Microsofts best practice once a month. <br>
The Microsoft Defender for Office 365 Recommended Configuration Analyzer (ORCA)

## Why would you want this?

- You may want to keep up to date with the everchanging best practices from Microsoft when it comes to security without giving out Security Reader/Admin permissions

- Security best practices change all the time and this way you can get an update monthly (or more frequently) and ensure you are inline with the recommendations. 

- Merger or aquisitions has happened and you onboard the domain of the new company in to your Microsoft 365 tenant as an accepted domin, but you forget to add them to policies and configure DKIM, this way you are alerted of this

## Why does the solution not use Azure Automation or Azure Functions instead of a VM

At the time of developing this solution the ExchangeOnlineManagement module had just announced their release of the -ManagedIdentity switch. The switch was limited to only work on Azure VM or Azure VM scaleset machines. 

When trying to call this command with the switch locally you would just receive a timeout, same for Azure Functions. 

The ORCA module has network-dependencies and uses the Resolve-DNSName commandlet. This is not allowed to run inside Azure Automation sandboxes, so we could not run the automation.ps1 script inside a Runbook. 

There is one AA used and that is to power on and off the virtual machine which in this case will simulate the Runbook sandbox VM. 

## What does this solution do

1. Triggers an Automation runbook on the 1st of each month to start an Azure VM
2. The Azure VM has a scheduled task that runs on system startup that triggers a script
3. The script authenticates to Exchange Online using the VM has a Managed Identity & extracts the ORCA-report
4. The report is emailed to your preferred destination
5. Another runbook triggers to shutdown the virtual machine and deallocate it so you are not billed for VM uptime

There is a SaaS subscription setup with Twilio Sendgrid Email API, configured through your Azure Portal.
The API is used to send email using a secret API-key stored in Azure Keyvault.

All the resources that are deployed are tagged so they can be identified as part of the solution: 

- Virtual machine with Managed Identity
- Azure Automation account
- Keyvault
- Twilio SaaS subscription (Free plan)

## Pre-requisites

- Privileged user administrator or Global Administrator in Azure Active Directory
- Owner permissions over at least one Resource Group where resources are deployed
- Azure CLI and Azure Powershell module installed
- Microsoft Graph module installed

## Guide for implementation

#### 1. Clone this Git repository

- All the templates and powershell scripts required to run this solution is saved in this repo for you to use
- Clone to directory of your choice and cd into the git-directory

Note that all the commands you will be instructed to execute will assume you are standing in the git-directory when executing them. 

#### 2. Authenticate and create your resource group that will host the Azure Resources

- Login to Azure using AZ CLI, ensure you are using an account with the correct permissions to create resources

```AZ CLI
az login
```
- Ensure you have the correct subscription set as default

```AC CLI
az account list -o table
az account set -s "<Subscription Name>"
```

- Creata a new resource group (if you are using an existing one skip this command)
```AZ CLI
az group create --name <name of RG> --location <location>
```

#### 3. Run the template to automatically provision all the dependant Azure Resources

- The git repository contains a bicep template that will provision some resources required for the solution to work
    - Azure Automation account with two runbooks & managed identity
    - A keyvault to store the secret API key used in the email integration
    - A role assignment for the Key Vault, granted VM contributor to power the virtual machine on and off using its managed identity
    - A virtual machine (used to simulate the Automation sandbox environment)

- In your shell run the following command to deploy the resources
```AZ CLI
az deployment group create -g <name of RG> --template-file deploy/main.bicep
````

- Enter the password for the virtual machine admin account, IMPORTANT: document this somewhere safe



