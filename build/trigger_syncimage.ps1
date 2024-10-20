
$uri = "https://code.52abp.com/api/v4/projects/337/trigger/pipeline"
$ref = "sync-images"

# 定义要传递的变量
$ciJobMode = $ciConfig.mode  # 替换为实际的作业模式
$branchOrTagKey = "main"     # 替换为实际的版本号



$response = Invoke-RestMethod -Uri $uri -Method Post -Form @{
    token = $GITLAB_RUNNER_TOKEN
    ref = $ref
    "variables[CI_JOB_MODE]" = $ciJobMode
    "variables[Version]" = $version
}

if ($response -eq $null) {
    Write-Error "Pipeline trigger failed."
} else {
    Write-Output "Pipeline triggered successfully."
}

