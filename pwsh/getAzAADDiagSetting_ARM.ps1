$path = "/providers/microsoft.aadiam/diagnosticSettings/?api-version=2017-04-01-preview"
$ret = Invoke-AzRestMethod -path $path -method "GET"
($ret.content | ConvertFrom-Json).value.properties.logs
