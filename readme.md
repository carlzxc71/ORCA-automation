# Introduction

Welcome to my first ever open-source project!

This project allows you to implement the required services and activate a system that will run your EOP configuration and match it with Microsofts best practice once a month. <br>
The Microsoft Defender for Office 365 Recommended Configuration Analyzer (ORCA)

## Why would you want this?

- You may want to keep up to date with the everchanging best practices from Microsoft when it comes to security without giving out Security Reader/Admin permissions

- Security best practices change all the time and this way you can get an update monthly (or more frequently) and ensure you are inline with the recommendations. 

- Merger or aquisitions has happened and you onboard the domain of the new company in to your Microsoft 365 tenant as an accepted domin, but you forget to add them to policies and configure DKIM, this way you are alerted of this.

## Why does the solution not use Azure Automation or Azure Functions instead of a VM

At the time of developing this solution the ExchangeOnlineManagement module had just announced their release of the -ManagedIdentity switch. The switch was limited to only work on Azure VM or Azure VM scaleset machines. 

When trying to call this command with the switch locally you would just receive a timeout, same for Azure Functions. 

The ORCA module has network-dependencies and uses the Resolve-DNSName commandlet. This is not allowed to run inside Azure Automation sandboxes, so we could not run the automation.ps1 script inside a Runbook. 

There is one automation account used and that is to power on and off the virtual machine which in this case will simulate the Runbook sandbox VM. <br>
The VM will be powered off at all times except for a few hours every month to keep costs down.

## What does this solution do

1. Triggers an Automation runbook on the 1st of each month to start an Azure VM
2. The Azure VM has a scheduled task that runs on system startup that triggers a script
3. The script authenticates to Exchange Online using the VM which has a Managed Identity & extracts the ORCA-report
4. The report is emailed to your preferred destination
5. Another runbook triggers to shutdown the virtual machine and deallocate it so you are not billed for VM uptime

We use Twilio Sendgrid Email API services because this is a service Microsoft has partnership with and you can configure a free subscription to their services directly in the Azure Portal. <br>
This is what will allow us to send email in automated powershell-scripts.

Resources being configured:

- Virtual machine with Managed Identity
- Azure Automation account
- Keyvault
- Twilio SaaS subscription (Free plan)

## Pre-requisites

- Privileged user administrator or Global Administrator in Azure Active Directory to assign Azure AD roles
- Owner permissions over at least one Resource Group where resources are deployed
- Azure CLI, Azure Powershell & MS Graph module installed
- Have access to a shared mailbox that will be used for Email Registration to twilio, ex: automation@domain.com 
- You deploying the solution should have some prior experience with:
  - Azure, the portal and managing resource groups and resources
  - Powershell and CLI

## Guide for implementation

#### 1. Fork and clone this Git repository

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

- It is always a good idea to check for upgrades for Bicep before deploying templates
```AC CLI
az bicep upgrade
```

#### 3. Run the template to automatically provision all the dependant Azure Resources

- The git repository contains a folder with bicep templates that will provision some resources required for the solution to work
    - Azure Automation account with two runbooks & managed identity
    - A keyvault to store the secret API key used in the email integration
    - A role assignment for the Key Vault, granted VM contributor to power the virtual machine on and off using its managed identity
    - A virtual machine (used to simulate the Automation sandbox environment)

- Important: Go through all the parameters in deploy/params.json file and update them to suit your setup
  - Double check network variables in vm.bicep and update any inputs here to suit your environment

- In your shell run the following command to deploy the resources after updating params.json
```AZ CLI
az deployment group create -g <name of RG> --template-file deploy/main.bicep --parameters deploy/params.json
```

- Enter the password for the virtual machine admin account, IMPORTANT: document this somewhere safe
- Wait for the deployment to finish, if you wish you can visit the resource group in the portal and click on deployments to follow all items being deployed or just wait for the terminal to finish

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
    - After you have verified your sender you will have completed the setup required in Sendgrids portal

Note: We use **Single Sender Verification** when performing the first-time setup, which is recommended for proof of concepts/test-setups. <br>
After you have verified the entire setup for this solution you can look into **Domain Verification**

#### 5. Create the keyvault secret and assign the VM managed identity Exchange Online Permissions

In this step you will store the API-key created in the previous step in the Keyvault you have deployed.<br>
The script will use the keyvault to retreive the API-key for sending email and the VM requires Exchange Administrator to run the powershell commandlets `Connect-ExchangeOnline` & `Invoke-ORCAReport`

- Go to the keyvault and to access policies
    - Give your own account Secret & Certificate Management template permissions 
        - Access Policies -> Create
        - Chose Secret Management from template
        - Chose your own account
        - Create

- Run the Register-KeyVaultSecret.ps1 script in Powershell on your local machine
```Powershell
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
```

The managed identity needs certain permissions in order to authenticate and query Exchange Online, we will use MS Graph for this

```Powershell
Connect-MgGraph -Scopes "User.Read.all","Application.Read.All","AppRoleAssignment.ReadWrite.All"
$params = @{
    ServicePrincipalId = '<>' # managed identity object id
    PrincipalId = '<>' # managed identity object id
    ResourceId = (Get-MgServicePrincipal -Filter "AppId eq '00000002-0000-0ff1-ce00-000000000000'").id # Exchange online
    AppRoleId = "dc50a0fb-09a3-484d-be87-e023b12c6440" # Exchange.ManageAsApp
}

New-MgServicePrincipalAppRoleAssignedTo @params
```

We also need to assign the Exchange Administrator role to the Managed Identity as only the application permissions are not supported.

- Head to Azure AD Privileged Identity Management
    - Under **Manage** Chose **Azure AD Roles**
    - **Assign Eligibility** and **Add Assignment**
    - Under **Select Role** chose **Exchange Administrator**
    - Under **Select Members** enter the name of the VM, select and click next
    - Provide justification and chose **Assign**

It may take 10-15 minutes for all the permissions to propagate.

*Note: In theory it should be enough with either the MS-graph permissions or the Exchange Admin role but at the time of developing this solution I have had issues where I did not complete both, this requirement may change later.*

#### 6. Login to the provisioned VM with RDP

In the future the aim is to deliver a solution that will not require this step, but for now we do. 

- Login to the VM through RDP
    - Username: orcaadmin
    - Password: The PW you set when deploying

- On the desktop create a file called: Trigger-ORCA.xml (You may need to show file extensions to ensure its .xml and not .txt)
- Paste in the following code: 

```XML
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Date>2022-10-25T08:03:23.4153238</Date>
    <Author>machine\admin</Author>
    <Description>Triggers and sends the automated ORCA report</Description>
    <URI>\Trigger-ORCAReport</URI>
  </RegistrationInfo>
  <Triggers>
    <BootTrigger>
      <Enabled>true</Enabled>
    </BootTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>S-1-5-21-2123838175-1840825630-523378789-500</UserId>
      <LogonType>Password</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-ExecutionPolicy Bypass -File "C:\Automation\ORCA\Trigger-ORCAReport.ps1"</Arguments>
    </Exec>
  </Actions>
</Task>
````

- Open task scheduler and use **Import task...** 
    - Navigate to where you saved your XML and chose it
- Click **Change user or group** 
    - Enter **orcaadmin**
- Click OK and enter the password for the account orcaadmin
- Enter the following command in Powershell
```Powershell
 New-Item -Path "C:\Automation\ORCA\Trigger-ORCAReport.ps1" -Force 
````
- Open the **Trigger-ORCAReport.ps1** through powershell and paste in the code from automation.ps1 that you received from cloning this repo
    - Update the parameters to suit your needs
    - Put in the name of the keyvault you created earlier in the KV variable
    - Update line 19 with the default domain name of your tenant

- Open Powershell as an Administrator on the Virtual Machine and run the following code:

```Powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Install-PackageProvider -Name NuGet -Confirm:$false -Force
Install-Module NuGet -Confirm:$false -Force

Install-Module ExchangeOnlineManagement -Confirm:$false -Force
Install-Module ORCA -Confirm:$false -Force
Install-Module Az -Confirm:$false -Force
```

- Wait for the script to complete, this will install all required modules for Trigger-ORCAReport.ps1 to run successfully

- After the modules are installed you should be ready to try a test-run of Trigger-ORCAReport.ps1
    - Make sure you change the parameters in the param-block of the script to suit your testing needs

- If successful it should authenticate to Exchange Online, trigger the ORCA-report & send the document to you in an email.

#### 7. Configure the deployed Automation Account to schedule VM start and stop

When you deployed all the Azure resources in step three you configured an Automation Account, this is what we will use to schedule the VM stop and start.

- In the Azure Portal to to **Automation Accounts**
- Chose the account you deployed in step 3 and click **Runbooks**
- You will see two runbooks with Authoring status: New
- Choose **Start-VM**
  - Choose **Edit**
  - Paste the following code found in Start-VM.ps1
```Powershell
[CmdletBinding()]
param (
    [string] $vmName = "<enter VM name here>",
    [string] $resourceGroupName = "<Enter the RG you are working with here>"
)

$ProgressPreference="silentlyContinue"

Disable-AzContextAutosave -Scope Process
  
# Connect to Azure with system-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity).context
  
# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext 

# Stop the VM
Start-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -Confirm:$false
```
- Choose **Save** then **Publish**
- Choose **Link to schedule**
  - Choose **Link a scheduled to your runbook**
  - Choose **Add a schedule**
  - Give it a name: **Start ORCA**
  - Starts: Chose the first of following month (We are assuming you will run this on the 1st of every month, you can adjust to fit you)
  - 8:00 AM for time
  - Set your Timezone
  - Chose **Recurring** -> **Recur every** 1 month
  - Chose **Month days** -> 1
  - Leave everything else as default and choose **Create**
- Choose **Parameters and run settings**
  - Change nothing and just choose **OK**
- Choose **OK**

- Go back to automation accounts and choose **Stop-VM**
  - Repeat the same steps and paste the following code
```Powershell
[CmdletBinding()]
param (
    [string] $vmName = "<Enter your VM name here>",
    [string] $resourceGroupName = "<Enter your RG here>"
)

$ProgressPreference="silentlyContinue"

Disable-AzContextAutosave -Scope Process
  
# Connect to Azure with system-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity).context
  
# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext 

# Stop the VM
Stop-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -Confirm:$false -Force
```
  - Repeat the steps you did for linking to a schedule, just chose a time that is later then whatever time you set for Start-VM
  - In my use case the Trigger-ORCAReport.ps1 runs for a few hours because of the amount of custom domains in the customer tenant
  - This means my time to trigger Stop-VM will take place a few hours later

  Once you have published and linked both runbooks to a schedule you can test the runbooks to make sure it works to stop and start the virtual machine.<br>
  If you have followed along so far this means your VM is currently running.

  - Go ahead and test Stop-VM runbook
  - When you have clicked in on **Stop-VM** runbook you can click **Start** 
    - Leave params empty and just click **OK**
    - Check if your VM stops after status of runbook-run is **Completed** (Sometimes it takes some time for the portal to report that the VM is off)
    - The status in the portal should be: **Stopped (Deallocated)** and will not continue to be billed for runtime

- If you don't run into any issues you can go ahead and test **Start-VM** runbook
  - Repeat the same process, after some time the VM should have status Running and the scheduled task we configured earlier should be running
  - After sometime if the script finishes successfully you will receive an email-report with the ORCA-report

- If successful and you receive the report go ahead and turn off the VM any way you see fit
  - It is supposed to be stopped (deallocated) as we only want it live on the 1st of the month when we want to trigger the report

## References & resources

- [MS Docs: Send an email from an Automation Runbook](https://learn.microsoft.com/en-us/azure/automation/automation-send-email)
- [Web Dev Zone: How to send an email with an attachment using Powershell and SendGrid API](https://dzone.com/articles/how-to-send-an-email-with-attachement-powershell-sendgrid-api)
- [onprem.wtf: How to connect to Exchange Online powershell with a Managed Identity](https://onprem.wtf/post/how-to-connect-exchange-online-managed-identity/)
- [MS Docs: Azure Automation Sandbox limitations](https://learn.microsoft.com/en-us/azure/automation/shared-resources/modules#sandboxes)
- [MS Docs: Exchange Online Management module](https://learn.microsoft.com/en-us/powershell/exchange/exchange-online-powershell-v2?view=exchange-ps)
- [GitHub: ORCA GitHub Repo](https://github.com/cammurray/orca)






