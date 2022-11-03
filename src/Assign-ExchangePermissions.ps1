Connect-MgGraph -Scopes "User.Read.all","Application.Read.All","AppRoleAssignment.ReadWrite.All"
$params = @{
    ServicePrincipalId = '73895db6-9bf0-4f67-9a68-0a9ba65aa1fe' # managed identity object id
    PrincipalId = '73895db6-9bf0-4f67-9a68-0a9ba65aa1fe' # managed identity object id
    ResourceId = (Get-MgServicePrincipal -Filter "AppId eq '00000002-0000-0ff1-ce00-000000000000'").id # Exchange online
    AppRoleId = "dc50a0fb-09a3-484d-be87-e023b12c6440" # Exchange.ManageAsApp
}

New-MgServicePrincipalAppRoleAssignedTo @params

$roleId = (Get-MgRoleManagementDirectoryRoleDefinition -Filter "DisplayName eq 'Exchange Administrator'").id
New-MgRoleManagementDirectoryRoleAssignment -PrincipalId 73895db6-9bf0-4f67-9a68-0a9ba65aa1fe -RoleDefinitionId 29232cdf-9323-42fd-ade2-1d097af3e4de -DirectoryScopeId "/"