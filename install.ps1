# dsh-purge 1.1.71-rc2.1 一键安装（Windows PowerShell）
# 用法： irm <raw 地址> | iex
$ErrorActionPreference = "Stop"

$PluginVersion = "1.1.71-rc2.1"
$HostVersion   = "0.2.1-rc.2"
$Pkg = "https://github.com/evan545295555-hash/Evans-repo/releases/download/v$PluginVersion/dsh-purge-$PluginVersion.tgz"
$DshHomeDir = if ($env:DSH_HOME) { $env:DSH_HOME } else { Join-Path $env:USERPROFILE ".dsh" }

function Say($m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Ok($m)  { Write-Host "OK  $m" -ForegroundColor Green }
function Die($m) { Write-Host "ERR $m" -ForegroundColor Red; exit 1 }

Say "dsh-purge $PluginVersion 安装器"

# 1) Node
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  Die "没检测到 Node.js。先装它：https://nodejs.org （选 LTS，双击安装）"
}
$major = [int](node -p "process.versions.node.split('.')[0]")
if ($major -lt 18) { Die "Node 版本太低（$(node -v)），需要 18 以上" }
Ok "Node $(node -v)"

# 2) 宿主
$needHost = $true
if (Get-Command dsh -ErrorAction SilentlyContinue) {
  $cur = (dsh --version 2>$null | Out-String).Trim()
  if ($cur -eq $HostVersion) { $needHost = $false; Ok "宿主 $cur" }
}
if ($needHost) {
  Say "安装 DeepSeek Harness $HostVersion（约 830 MB，耐心等）"
  npm i -g "@deepseek-ai/dsh@$HostVersion"
  Ok "宿主 $((dsh --version | Out-String).Trim())"
}

# 3) profile
dsh --profile web --dump-config | Out-Null

# 4) 插件
Say "下载并安装插件"
dsh plugin --profile web add --ignore-scripts $Pkg

# 5) 登记
Say "登记到 profile"
Set-Location (Join-Path $DshHomeDir "profiles\web")
node node_modules/dsh-purge/scripts/ensure-profile-bundle.mjs

# 6) 验收
$n = (dsh --profile web --dump-config | Select-String -Pattern '^- id: dsh-purge$').Count
if ($n -ne 1) { Die "安装后挂载数异常：$n（预期 1）" }

Write-Host ""
Ok "安装完成，重启 DeepSeek Harness 生效"
Write-Host "   启动命令： dsh web"
Write-Host "   回滚命令： dsh plugin --profile web remove dsh-purge"
