# Implementing automated ORCA report

This project allows you to implement the required services and activate a system that will run your EOP configuration and match it with Microsofts best practice once a month. 

## Why would you want this?

You may want to keep up to date with the everchanging best practices from Microsoft when it comes to security. One way to handle this could be giving one person access to the relevant security portals in Microsoft 365. 

One problem with that is if the person is only responsible for looking at the email security configuration, the person will inevitabely have access to a lot more than this. This is a way to accomplish this using least privileges, by handing out no privileges to more humans. 

As mentioned the security best practices change all the time and this way you can get an update monthly (or more frequently) and ensure you are inline with the recommendations. 

We have also experienced issues where maybe a merger or an aquisition has happened and you onboard the domain of the new company in to your Microsoft 365 tenant as an accepted domin.

This does not automatically add them to your custom anti-spam/anti-phishing, safe-link, safe-attachment & anti-malware policies. It also does not automatically configure DKIM for their domain. We have had many instances where this has happened and if you get an automated report every month you can remediate this. 

## Why does the solution not use Azure Automation or Azure Functions instead of a VM

Bla bla

## Pre-requisites

- Privileged user administrator in Azure Active Directory
- Contributor permissions over at least one Resource Group
- Azure CLI or Azure Powershell
- Microsoft Graph module installed
