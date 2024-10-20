# 获取当前工作目录的父目录路径
$rootPath = Split-Path -Parent (Get-Location).Path

# 构建 ci-config.json 文件的完整路径
$ciConfigPath = Join-Path $rootPath "src" "ci-config.json"

# 读取 ci-config.json 文件的内容并将其转换为 JSON 对象
$ciConfig = (Get-Content -Path $ciConfigPath -Encoding UTF8) | ConvertFrom-Json

# 设置环境变量 "Mode" 为 JSON 对象中的 mode 属性值
[Environment]::SetEnvironmentVariable("Mode", $ciConfig.mode)

# 将 mode 的值输出到 GitHub Actions 的上下文中
echo "mode=$($ciConfig.mode)" >> $env:GITHUB_OUTPUT
