$azContext = Get-AzContext
$tokenRequestEndPoint = 'https://storage.azure.com'
$newBearerAccessTokenRequest = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($azContext.Account, $azContext.Environment, $azContext.Tenant.id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, "$tokenRequestEndPoint")
$createdBearerToken = $newBearerAccessTokenRequest.AccessToken

$header = @{
    'Content-Type'  = 'application/json';
    'x-ms-version'  = '2021-04-10';
    'Authorization' = "Bearer $createdBearerToken"
}

$storageAccountName = 'myStorageAccountName'
Invoke-WebRequest -uri "https://$($storageAccountName).blob.core.windows.net/?restype=service&comp=properties" -Method 'GET' -Headers $header
