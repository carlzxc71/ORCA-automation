Connect-MgGraph -Scopes "User.Read.all","Application.Read.All","AppRoleAssignment.ReadWrite.All"
$params = @{
    ServicePrincipalId = '<Enter managed object ID of Virtual Machine>' # managed identity object id - you can find this under your resource group in the Azure Portal -> deployments -> vmDeployment -> outputs
    PrincipalId = '<Enter managed object ID of Virtual Machine>' # managed identity object id - you can find this under your resource group in the Azure Portal -> deployments -> vmDeployment -> outputs
    ResourceId = (Get-MgServicePrincipal -Filter "AppId eq '00000002-0000-0ff1-ce00-000000000000'").id # Exchange online
    AppRoleId = "dc50a0fb-09a3-484d-be87-e023b12c6440" # Exchange.ManageAsApp
}

New-MgServicePrincipalAppRoleAssignedTo @params