#!/usr/bin/env bash
# dsh-purge 1.1.71-rc2.1 一键安装（macOS / Linux）
# 用法： curl -fsSL <raw 地址> | bash
set -euo pipefail

PLUGIN_VERSION="1.1.71-rc2.1"
HOST_VERSION="0.2.1-rc.2"
PKG="https://github.com/evan545295555-hash/Evans-repo/releases/download/v${PLUGIN_VERSION}/dsh-purge-${PLUGIN_VERSION}.tgz"
DSH_HOME_DIR="${DSH_HOME:-$HOME/.dsh}"

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
ok()  { printf '\033[1;32m✅\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m❌\033[0m %s\n' "$*" >&2; exit 1; }

say "dsh-purge ${PLUGIN_VERSION} 安装器"

# 1) Node
command -v node >/dev/null 2>&1 || die "没检测到 Node.js。先装它：https://nodejs.org （选 LTS，双击安装）"
NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
[ "$NODE_MAJOR" -ge 18 ] || die "Node 版本太低（$(node -v)），需要 18 以上"
ok "Node $(node -v)"

# 2) 宿主
if ! command -v dsh >/dev/null 2>&1; then
  say "没装 DeepSeek Harness，正在安装 ${HOST_VERSION}（约 830 MB，耐心等）"
  npm i -g "@deepseek-ai/dsh@${HOST_VERSION}"
elif [ "$(dsh --version 2>/dev/null | tr -d '[:space:]')" != "$HOST_VERSION" ]; then
  say "宿主版本是 $(dsh --version 2>/dev/null)，切换到 ${HOST_VERSION}"
  npm i -g "@deepseek-ai/dsh@${HOST_VERSION}"
fi
ok "宿主 $(dsh --version)"

# 3) profile
dsh --profile web --dump-config >/dev/null 2>&1 || true

# 4) 插件
say "下载并安装插件"
dsh plugin --profile web add --ignore-scripts "$PKG"

# 5) 登记
say "登记到 profile"
cd "$DSH_HOME_DIR/profiles/web"
node node_modules/dsh-purge/scripts/ensure-profile-bundle.mjs

# 6) 验收
COUNT="$(dsh --profile web --dump-config 2>/dev/null | grep -c '^- id: dsh-purge$' || true)"
[ "$COUNT" = "1" ] || die "安装后挂载数异常：$COUNT（预期 1）"

echo
ok "安装完成，重启 DeepSeek Harness 生效"
echo "   启动命令： dsh web"
echo "   回滚命令： dsh plugin --profile web remove dsh-purge"
