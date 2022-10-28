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
- Have access to a shared mailbox that will be used for Email Registration to twilio, ex: automation@domain.com 

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

- Important: Check all the parameters being set in main.bicep and update the values to suit your deployment
    - I had an issue where I tried to deploy but the key-vault name was being used, simply update the parameter and run the deploy command again

- In your shell run the following command to deploy the resources
```AZ CLI
az deployment group create -g <name of RG> --template-file deploy/main.bicep
````

- Enter the password for the virtual machine admin account, IMPORTANT: document this somewhere safe
- Wait for the deployment to finish, if you wish you can visit the resource group in the portal and click on deployment to follow all items being deployed

#### 4. Register a SaaS-subscription for Twilio Sendgrid Email Platform

Microsoft recommends using Twilio for sending emails so we should be able to trust that they are a reliant partner. They even let you register for their services through the Azure Portal<br>
Remember that you need a mailbox that you can access which will be used for the setup, example: automation@domain.com 

Source-reference from MS Docs: [Send an Email with Automation](https://learn.microsoft.com/en-us/azure/automation/automation-send-email)

- Visit the manual from Twilio for setup, ignore the part with creating subscription and resource groups as we have those already, [Twilio email setup manual](https://docs.sendgrid.com/for-developers/partners/microsoft-azure-2021#create-a-sendgrid-account)
- [Create a Twilio Sendgrid Account](https://docs.sendgrid.com/for-developers/partners/microsoft-azure-2021#create-a-twilio-sendgrid-account)
    - Chose your resource group created in the previous step
    - Enter a name for the resource
    - Chose Free plan
    - Recurring billing: On
    - Leave anything else as default
    - After accepting terms your subscription is being provisioned
    - When provisioning finishes click **Configure account now**
        - You may need to accept the application to gain access to some information for your tenant, chose **accept**
    - Complete the **tell us about yourself**-part

- Create the API-key
    - In the left pane click **Settings** -> **API Keys**
    - Click **Create API key** -> Give it a name and full access permissions
    - Copy the API key and store it somewhere, you need it later

- Create a single sender
    - Chose **Create a single sender**
        - Fill in the required information, make sure From Email Address and Reply to is set to the mailbox you have created for this
    - Login to your mailbox and verify the email that Twilio sends you
        - You may need to use **Resend verification email** if nothing shows up, I have had instances where it was fast and sometimes I had to wait for some time
    - After you have verified your sender you will have completed the setup required in Sendgrids portal¨

Note: We use **Single Sender Verification** when performing the first-time setup, which is recommended for proof of concepts/test-setups. <br>
After you have verified the entire setup for this solution you can look into **Domain Verification**





