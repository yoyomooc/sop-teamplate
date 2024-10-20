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

# 读取当前项目配置
$ciConfigPath = Join-Path $rootPath "src" "ci-config.json"
$ciConfig = (Get-Content -Path $ciConfigPath -Encoding UTF8) | ConvertFrom-Json

$branchOrTagKey = 'branch'
if ($ciConfig.mode -eq 'tag') {
    $branchOrTagKey = 'tag'
}
$branchOrTag = $ciConfig.branch
$commit = $ciConfig.commit
$creationTime = [DateTime]::Parse($ciConfig.creationTime).ToUniversalTime().AddHours(8)

Write-Host "$creationTime"+$creationTime

$gitlabPipelineId = $ciConfig.gitlabPipelineId

$workflowUrl = "https://github.com/${env:repository}/actions/runs/${env:run_id}"
$pipelineUrl = "${env:GIT_REPO_PIPLINE}/${gitlabPipelineId}"

# 计算构建时长
$buildDuration = $currentDate - $creationTime

# 根据编译结果生成通知消息
if ($BuildSuccess) {
    $title = "编译成功通知"
    $message = "编译成功！✨ 代码已经顺利上线，快去看看吧！"
    $emoji = "🚀"
} else {
    $title = "编译失败通知"
    $message = "编译失败！💔 请检查代码，尽快修复问题哦！"
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
                        "text": "--- ${currentDateStr} ---\n${message}\n\n--- 构建信息 ---\n${branchOrTagKey}: ${branchOrTag}\n提交: ${commit}\n创建时间: ${creationTime}\n构建时长: ${buildDuration}\nGitHub 工作流: "
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
