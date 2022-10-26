# Implementing automated ORCA report

This project allows you to implement the required services and activate a system that will run your EOP configuration and match it with Microsofts best practice once a month. 

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
- Contributor permissions over at least one Resource Group
- Azure CLI and Azure Powershell module installed
- Microsoft Graph module installed

## Guide for implementation

1. 