#Install-Module -Name Az.Accounts
#Install-Module -Name Microsoft.Graph

#connect Azure
Connect-AzAccount -UseDeviceAuthentication
$getToken = Get-AzAccessToken -ResourceTypeName MSGraph #$getToken = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com"

#connect MS Graph
Connect-MgGraph -AccessToken $getToken.Token

$servicePrincipalId = "<objectId>" #objectId of the Enterprise Application (Azure Portal/Azure Active Directory/Enterprise Applications)
$spOwnerObject = Get-MgServicePrincipalOwner -ServicePrincipalId $ServicePrincipalId
if ($spOwnerObject) {
    $spOwnerObject.Id
    $spOwnerObject.AdditionalProperties.'@odata.type'
    $spOwnerObject.AdditionalProperties.displayName 
}
else {
    Write-Host "no owner"
}

#show the endPoint used
$endPointUsed = Get-MgServicePrincipalOwner -ServicePrincipalId $ServicePrincipalId -debug 5>&1
($endPointUsed | Select-String -Pattern 'Absolute Uri:') | foreach-object {
    [regex]$regex = '(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})'
    [string]$_ | select-string -pattern $regex | ForEach-Object { $_.Matches } | ForEach-Object { $_.Value }
}
