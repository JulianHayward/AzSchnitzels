if ($env:GITHUB_SERVER_URL -and $env:CODESPACES) {
    #GitHub Codespaces
    Write-Host "running: GitHub CodeSpaces"
    Write-Host "GITHUB_SERVER_URL" $env:GITHUB_SERVER_URL
    Write-Host "CODESPACES" $env:CODESPACES
}
elseif ($env:SYSTEM_TEAMPROJECTID -and $env:BUILD_REPOSITORY_ID) {
    #Azure DevOps
    Write-Host "running: Azure DevOps"
    Write-Host "BUILD_REPOSITORY_ID" $env:BUILD_REPOSITORY_ID
    Write-Host "SYSTEM_TEAMPROJECTID" $env:SYSTEM_TEAMPROJECTID
}
elseif ($PSPrivateMetadata){
    #Azure Automation
    Write-Output "running: Azure Automation"
    Write-Output "PSPrivateMetadata:" $PSPrivateMetadata
}
else {
    #Other Console
    Write-Host "not Codespaces, not Azure DevOps, not Azure Automation - likely local console"
}
#todo? Azure Functions, GitHub Actions
