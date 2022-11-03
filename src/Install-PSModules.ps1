[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Install-PackageProvider -Name NuGet -Confirm:$false -Force
Install-Module NuGet -Confirm:$false -Force

Install-Module ExchangeOnlineManagement -Confirm:$false -Force
Install-Module ORCA -Confirm:$false -Force
Install-Module Az -Confirm:$false -Force