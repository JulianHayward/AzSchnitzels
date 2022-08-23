#required permission: 'Application.Read.All' and 'AppRoleAssignment.ReadWrite.All'


#-------------------------------------
# Variables
$servicePrincipalObjectId = "<someGuid>"
$microsoftGraphApplicationId = "00000003-0000-0000-c000-000000000000" #the app (client) id for 'Microsoft Graph' equals in each and every tenant (at least for AzureCloud), the objectId however differs
#use the appRole id (e.g. 5b567255-7703-4780-807c-7be8301ae99b) OR the appRole name (e.g. Group.Read.All)
$appRole = "5b567255-7703-4780-807c-7be8301ae99b" #Group.Read.All

$resourceUrl = "https://graph.microsoft.com"

#-------------------------------------
# Get Bearer token
try {
    $getAzAccessToken = Get-AzAccessToken -ResourceUrl $resourceUrl -ErrorAction Stop
}
catch {
    $_
    throw "s.th. went wrong"
}

$header = @{
    "Content-Type"  = "application/json";
    "Authorization" = "Bearer $($getAzAccessToken.Token)"
}

#-------------------------------------
# Get resource SP objectId and collect the appRoles in a lookup hashTable
Write-Host ""
Write-Host "- - - - - - - - - - - -"
Write-Host "Get resource SP objectId for appId: '$($microsoftGraphApplicationId)' and collect the appRoles in a lookup hashTable"
pause
#https://docs.microsoft.com/en-us/graph/api/serviceprincipal-get
#required permission: 'Application.Read.All'
$uri = "$($resourceUrl)/v1.0/servicePrincipals?`$filter=appId eq '$($microsoftGraphApplicationId)'"
$method = "GET"
$getSP = $null
try {
    $getSP = Invoke-WebRequest -Uri $uri -Method $method -Headers $header -ErrorAction Stop
}
catch {
    $_
    throw "s.th. went wrong"
}
$spObject = ($getSP.Content | ConvertFrom-Json).value

Write-Host "microsoftGraphApplicationId: '$microsoftGraphApplicationId' returned SP: '$($spObject.displayName)' with appId: '$($spObject.id)' ($($spObject.appRoles.Count) appRoles)"

# Lookup hashTable / map appRole id/name
$htAppRoles = @{}
$htAppRoles.permissionId = @{}
$htAppRoles.permissionName = @{}
foreach ($SPAppRole in $spObject.appRoles | Sort-Object -Property value) {
    $htAppRoles.permissionId.($SPAppRole.id) = $SPAppRole.value
    $htAppRoles.permissionName.($SPAppRole.value) = $SPAppRole.id
    #Write-Host "$($appRole.value) - '$($appRole.id)'"
}
if ($htAppRoles.permissionId.($appRole)) {
    $targetAppRoleId = $appRole
    $targetAppRoleName =$htAppRoles.permissionId.($appRole)
}
elseif ($htAppRoles.permissionName.($appRole)) {
    $targetAppRoleId = $htAppRoles.permissionName.($appRole)
    $targetAppRoleName = $appRole
}
else{
    Write-Host "appRole '$($appRole)' not found"
    throw
}

$servicePrincipalObjectIdOfTheResourceApp = $spObject.id


#-------------------------------------
# Create appRole assignment
Write-Host ""
Write-Host "- - - - - - - - - - - -"
Write-Host "Create appRole assignment for SP objectId '$($servicePrincipalObjectId)' - appRole id: '$($targetAppRoleId)'; appRole name: '$($targetAppRoleName)'"
pause
#https://docs.microsoft.com/en-us/graph/api/serviceprincipal-post-approleassignedto
#required permission: 'AppRoleAssignment.ReadWrite.All'
$uri = "$($resourceUrl)/v1.0/servicePrincipals/$($servicePrincipalObjectId)/appRoleAssignedTo"
$method = "POST"
$body = @"
    {
        "principalId": "$($servicePrincipalObjectId)",
        "resourceId": "$servicePrincipalObjectIdOfTheResourceApp",
        "appRoleId": "$targetAppRoleId"
    }
"@
$createAppRoleAssignment = $null
try {
    $createAppRoleAssignment = Invoke-WebRequest -Uri $uri -Method $method -Body $body -Headers $header -ErrorAction Stop
}
catch {
    $_
    throw "s.th. went wrong"
}
$createAppRoleAssignment.StatusCode
$createAppRoleAssignmentObject = $createAppRoleAssignment.Content | ConvertFrom-Json
$createAppRoleAssignmentObject
$appRoleAssignmentId = $createAppRoleAssignmentObject.id


#-------------------------------------
# Get appRole assignments
Write-Host ""
Write-Host "- - - - - - - - - - - -"
Write-Host "Get appRole assignments for SP objectId '$($servicePrincipalObjectId)'"
pause
#https://docs.microsoft.com/en-us/graph/api/serviceprincipal-list-approleassignments
#required permission: 'Application.Read.All'
$uri = "$($resourceUrl)/v1.0/servicePrincipals/$($servicePrincipalObjectId)/appRoleAssignments"
$method = "GET"
$getAppRoleAssignments = $null
try {
    $getAppRoleAssignments = Invoke-WebRequest -Uri $uri -Method $method -Headers $header -ErrorAction Stop
}
catch {
    $_
    throw "s.th. went wrong"
}
$getAppRoleAssignmentsObject = ($getAppRoleAssignments.Content | ConvertFrom-Json).value
Write-Host "$($getAppRoleAssignmentsObject.Count) permissions:"
$cnt = 0
foreach ($appRoleAssignment in $getAppRoleAssignmentsObject) {
    $cnt++
    Write-Host " $cnt - - - - - - - - - - - -"
    Write-Host "  assignment id:" $appRoleAssignment.id
    Write-Host "  appRole id:" $appRoleAssignment.appRoleId
    Write-Host "  appRole name:" $targetAppRoleName
}


#-------------------------------------
# Delete the just created appRole assignment
Write-Host ""
Write-Host "- - - - - - - - - - - -"
Write-Host "Delete the just created appRole assignment 'id: $($appRoleAssignmentId)'"
pause
#https://docs.microsoft.com/en-us/graph/api/serviceprincipal-delete-approleassignedto
#required permission: 'AppRoleAssignment.ReadWrite.All'
$uri = "$($resourceUrl)/v1.0/servicePrincipals/$($servicePrincipalObjectId)/appRoleAssignedTo/$($appRoleAssignmentId)"
$method = "DELETE"
$deleteAppRoleAssignment = $null
try {
    $deleteAppRoleAssignment = Invoke-WebRequest -Uri $uri -Method $method -Headers $header -ErrorAction Stop
}
catch {
    $_
    throw "s.th. went wrong"
}
$deleteAppRoleAssignment.StatusCode


#-------------------------------------
# Get appRole assignments again
Write-Host ""
Write-Host "- - - - - - - - - - - -"
Write-Host "Get appRole assignments for SP objectId '$($servicePrincipalObjectId)' again"
pause
#https://docs.microsoft.com/en-us/graph/api/serviceprincipal-list-approleassignments
#required permission: 'Application.Read.All'
$uri = "$($resourceUrl)/v1.0/servicePrincipals/$($servicePrincipalObjectId)/appRoleAssignments"
$method = "GET"
$getAppRoleAssignments = $null
try {
    $getAppRoleAssignments = Invoke-WebRequest -Uri $uri -Method $method -Headers $header -ErrorAction Stop
}
catch {
    $_
    throw "s.th. went wrong"
}
$getAppRoleAssignmentsObject = ($getAppRoleAssignments.Content | ConvertFrom-Json).value
Write-Host "$($getAppRoleAssignmentsObject.Count) permissions:"
$cnt = 0
foreach ($appRoleAssignment in $getAppRoleAssignmentsObject) {
    $cnt++
    Write-Host " $cnt - - - - - - - - - - - -"
    Write-Host "  assignment id:" $appRoleAssignment.id
    Write-Host "  appRole id:" $appRoleAssignment.appRoleId
    Write-Host "  appRole name:" $targetAppRoleName
}
