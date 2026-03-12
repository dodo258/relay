#!/bin/bash
#
# realm-relay 全自动同步脚本 (无人值守版)
# 功能：自动同步上游更新，应用 branding 修改，自动提交推送
# 用法：直接运行，或通过 cron 定时执行
#

set -e

# 日志文件
LOG_FILE="/tmp/realm-relay-sync.log"
LOCK_FILE="/tmp/realm-relay-sync.lock"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 防重复运行
if [ -f "$LOCK_FILE" ]; then
    echo "$(date): 脚本已在运行，退出" >> $LOG_FILE
    exit 0
fi
touch "$LOCK_FILE"
trap "rm -f $LOCK_FILE" EXIT

echo "$(date): === 开始同步检查 ===" >> $LOG_FILE

# 进入仓库目录
cd "$(dirname "$0")"

# 确保远程仓库配置
if ! git remote | grep -q "upstream"; then
    git remote add upstream https://github.com/zywe03/realm-xwPF.git 2>/dev/null || true
fi

if ! git remote | grep -q "origin"; then
    git remote add origin https://github.com/dodo258/relay.git 2>/dev/null || true
fi

# 获取上游更新
git fetch upstream 2>&1 >> $LOG_FILE

# 检查是否有更新
LOCAL=$(git rev-parse @ 2>/dev/null || echo "none")
REMOTE=$(git rev-parse upstream/main 2>/dev/null || echo "none")

if [ "$LOCAL" = "$REMOTE" ] || [ "$REMOTE" = "none" ]; then
    echo "$(date): ✓ 已是最新，无需同步" >> $LOG_FILE
    exit 0
fi

echo "$(date): → 发现上游更新，开始同步..." >> $LOG_FILE

# 创建同步分支
SYNC_BRANCH="auto-sync-$(date +%Y%m%d-%H%M%S)"
git checkout -b "$SYNC_BRANCH" upstream/main 2>&1 >> $LOG_FILE

# 应用 branding 修改
echo "$(date): 应用 branding 修改..." >> $LOG_FILE

# 1. 重命名主脚本
if [ -f "xwPF.sh" ]; then
    git mv xwPF.sh relay.sh
    echo "$(date): 重命名 xwPF.sh → relay.sh" >> $LOG_FILE
fi

# 2. 替换脚本内品牌名
if [ -f "relay.sh" ]; then
    sed -i.bak 's/xwPF/Relay/g' relay.sh 2>/dev/null || true
    rm -f relay.sh.bak
fi

# 3. 更新 README（添加署名）
if [ -f "README.md" ] && ! grep -q "本项目基于.*realm-xwPF" README.md; then
    cat > /tmp/readme_header.txt << 'EOF'
# Relay - 端口转发管理工具

> 本项目基于 [zywe03/realm-xwPF](https://github.com/zywe03/realm-xwPF) 定制开发  
> **原作者**: [zywe03](https://github.com/zywe03)

---

EOF
    tail -n +3 README.md >> /tmp/readme_header.txt
    mv /tmp/readme_header.txt README.md
    echo "$(date): 更新 README 署名" >> $LOG_FILE
fi

# 提交修改
git add -A
git commit -m "auto-sync: 同步上游更新 $(date +%Y-%m-%d %H:%M)

- 自动同步自 zywe03/realm-xwPF
- 应用 branding: xwPF → Relay
- 保留原作者署名" 2>&1 >> $LOG_FILE || true

# 合并到 main
git checkout main 2>&1 >> $LOG_FILE
git merge "$SYNC_BRANCH" --no-ff -m "Merge: $SYNC_BRANCH" 2>&1 >> $LOG_FILE

# 删除临时分支
git branch -d "$SYNC_BRANCH" 2>&1 >> $LOG_FILE || true

# 推送到 GitHub
git push origin main 2>&1 >> $LOG_FILE

echo "$(date): ✅ 同步完成并推送到 GitHub" >> $LOG_FILE

# 可选：发送通知（如果配置了 Telegram Bot）
if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d "chat_id=$TELEGRAM_CHAT_ID" \
        -d "text=🔄 Relay 仓库已自动同步上游更新" > /dev/null 2>&1 || true
fi

echo "$(date): === 同步结束 ===" >> $LOG_FILE
