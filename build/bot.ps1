param(
    [string]$BotUrl,
    [string]$Msg,
    [bool]$BuildSuccess
)

# 设置时区
$currentDate = (Get-Date).ToUniversalTime().AddHours(8)
$currentDateStr = $currentDate.ToString('yyyy-MM-dd HH:mm:ss')

Write-Host "$currentDate"+$currentDate



$rootPath = Split-Path -Parent (Get-Location).Path




# 读取当前项目配置 -- ci-config.json
$ciConfigPath = Join-Path $rootPath "src" "ci-config.json"
$ciConfig = (Get-Content -Path $ciConfigPath -Encoding UTF8) | ConvertFrom-Json

$branchOrTagKey = 'branch'
if ($ciConfig.mode -eq 'tag') {
    $branchOrTagKey = 'tag'
}
$branchOrTag = $ciConfig.branch
$commit = $ciConfig.commit


$gitlabPipelineId = $ciConfig.gitlabPipelineId

$workflowUrl = "https://github.com/${env:repository}/actions/runs/${env:run_id}"
$pipelineUrl = "${env:GIT_REPO_PIPLINE}/${gitlabPipelineId}"




# 获取当前时间
$creationTime = [DateTime]::ParseExact($ciConfig.creationTime, "yyyy-MM-dd HH:mm:ss", $null).ToUniversalTime()
$creationTimeStr = $creationTime.ToString('yyyy-MM-dd HH:mm:ss')


Write-Host "$creationTime"+$creationTime


# 计算构建时长
$buildDuration = $currentDate - $creationTime


#$BuildImageName

Write-Host "$成功的镜像名称："+$BuildImageName




# 根据编译结果生成通知消息
if ($BuildSuccess) {

$uri = "https://code.52abp.com/api/v4/projects/337/trigger/pipeline"
$ref = "sync-images"

# 定义要传递的变量
$ciJobMode = $ciConfig.mode  # 替换为实际的作业模式
$branchOrTagKey = "main"     # 替换为实际的版本号



$response = Invoke-RestMethod -Uri "https://code.52abp.com/api/v4/projects/337/trigger/pipeline" -Method Post -Form @{
    token = $GITLAB_RUNNER_TOKEN
    ref = "sync-images"
    "variables[CI_JOB_MODE]" = $ciJobMode
    "variables[Version]" = $branchOrTagKey
}

if ($response -eq $null) {
    Write-Error "Pipeline trigger failed."
} else {
    Write-Output "Pipeline triggered successfully."
}









    $title = "sop-teamplate-CI编译成功通知 $ref $uri $ciJobMode $version"
    $message = "sop-teamplate-CI编译成功！✨ 镜像：$BuildImageName 构建成功！"
    $emoji = "🚀"
} else {
    $title = "sop-teamplate-CI编译失败通知"
    $message = "sop-teamplate-CI编译失败！💔 请检查代码，尽快修复问题哦！"
    $emoji = "💔"
}

# 构建富文本内容
$content = @"
{
    "msg_type": "post",
    "content": {
        "post": {
            "zh_cn": {
                "title": "$title",
                "content": [
                    [{
                        "tag": "text",
                        "text": "当前时间： ${currentDateStr} ， ${message}\n\n--- 构建信息 ---\n${branchOrTagKey}: ${branchOrTag}\n提交: ${commit}\n创建时间: ${creationTimeStr}\n构建时长: ${buildDuration}\nGitHub 工作流: "
                    }, {
                        "tag": "a",
                        "text": "查看详情",
                        "href": "${workflowUrl}"
                    }, {
                        "tag": "text",
                        "text": "\nGitLab 流水线: "
                    }, {
                        "tag": "a",
                        "text": "查看详情",
                        "href": "${pipelineUrl}"
                    }, {
                        "tag": "text",
                        "text": "\n${emoji} ${title} 🎉"
                    }]
                ]
            }
        }
    }
}
"@

# ----------------- 发送通知 -----------------
$bodyJson = $content | ConvertFrom-Json | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod `
        -Method 'Post' `
        -ContentType 'application/json' `
        -Uri $BotUrl `
        -Body $bodyJson
    Write-Host "通知发送成功"
} catch {
    Write-Host "通知发送失败: $_"
    # 记录错误日志或其他处理
}
