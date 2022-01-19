if ($env:GITHUB_SERVER_URL -and $env:CODESPACES) {
    #GitHub Codespaces
    $checkCodeRunPlatform = "GitHubCodespaces"
    Write-Host "running on:" $checkCodeRunPlatform
}
elseif ($env:SYSTEM_TEAMPROJECTID -and $env:BUILD_REPOSITORY_ID) {
    #Azure DevOps
    $checkCodeRunPlatform = "AzureDevOps"
    Write-Host "running on:" $checkCodeRunPlatform
}
elseif ($PSPrivateMetadata) {
    #Azure Automation
    $checkCodeRunPlatform = "AzureAutomation"
    Write-Output "running on:" $checkCodeRunPlatform
}
elseif ($env:GITHUB_ACTIONS) {
    #GitHub Actions
    $checkCodeRunPlatform = "GitHubActions"
    Write-Host "running on:" $checkCodeRunPlatform
}
elseif ($env:ACC_IDLE_TIME_LIMIT -and $env:AZURE_HTTP_USER_AGENT -and $env:AZUREPS_HOST_ENVIRONMENT) {
    #Azure Cloud Shell
    $checkCodeRunPlatform = "CloudShell"
    Write-Host "running on:" $checkCodeRunPlatform
}
else {
    #Other Console
    $checkCodeRunPlatform = "Console"
    Write-Host "running on:" $checkCodeRunPlatform
}
#todo? Azure Functions