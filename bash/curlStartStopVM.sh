appId=<application (client) id> #example: appId=48700ee1-cda8-4ae5-af49-d7207af1e982
appSecret=<secret>
tenantId=<tenantId>
vmResourceId=<vmResourceId>
apiVersion=\?api-version\=2022-03-01
startUri=https://management.azure.com$vmResourceId/start$apiVersion
deallocateUri=https://management.azure.com$vmResourceId/deallocate$apiVersion
declare accessToken=$(curl -X POST -d "grant_type=client_credentials&client_id=$appId&client_secret=$appSecret&resource=https%3A%2F%2Fmanagement.azure.com%2F" https://login.microsoftonline.com/$tenantId/oauth2/token | jq ".access_token" -r)
curl -X POST -d "" -v -H "Authorization: Bearer $accessToken" -H "Content-Type:application/json" -H "Accept:application/json" $deallocateUri | jq .
