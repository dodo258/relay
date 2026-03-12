#!/bin/bash
#
# realm-relay 智能同步脚本 (预览确认版)
# 功能：检测上游更新，显示差异，用户确认后才同步
#

set -e

# 日志
LOG_FILE="/tmp/realm-relay-sync.log"

echo -e "\033[0;32m=== Realm Relay 智能同步脚本 ===\033[0m"
echo ""

cd "$(dirname "$0")"

# 确保上游配置
if ! git remote | grep -q "upstream"; then
    git remote add upstream https://github.com/zywe03/realm-xwPF.git
fi

echo "📡 正在检查上游更新..."
git fetch upstream 2>/dev/null

LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse upstream/main)
BASE=$(git merge-base @ upstream/main)

if [ "$LOCAL" = "$REMOTE" ]; then
    echo "✅ 已经是最新版本，无需同步"
    exit 0
fi

echo ""
echo -e "\033[1;33m⚠️  检测到上游更新！\033[0m"
echo ""

# 显示更新的文件列表
echo "📋 上游修改的文件列表："
echo "-------------------"
git diff --name-only HEAD upstream/main | head -20
echo "-------------------"
echo ""

# 检查是否涉及关键文件（UI/核心）
echo "🔍 检查关键文件..."
CRITICAL_FILES=("lib/ui.sh" "relay.sh")
HAS_CRITICAL=false

for file in "${CRITICAL_FILES[@]}"; do
    if git diff --name-only HEAD upstream/main | grep -q "^$file$"; then
        echo -e "  ⚠️  \033[1;31m[重要] $file 被修改\033[0m - 可能影响界面"
        HAS_CRITICAL=true
    fi
done

if [ "$HAS_CRITICAL" = false ]; then
    echo -e "  ✓ \033[0;32m关键文件未修改，相对安全\033[0m"
fi

echo ""
echo "📊 更新统计："
git log --oneline HEAD..upstream/main | head -5
echo ""

# 显示重要文件的差异预览
echo "📝 关键文件差异预览（前30行）："
echo "================================"
for file in "${CRITICAL_FILES[@]}"; do
    if git diff --name-only HEAD upstream/main | grep -q "^$file$"; then
        echo -e "\n\033[1;36m--- $file 变化预览 ---\033[0m"
        git diff HEAD upstream/main -- "$file" | head -30
        echo ""
    fi
done
echo "================================"

# 用户确认
echo ""
echo -e "\033[1;33m请选择操作：\033[0m"
echo "1) ✅ 同步这些更新（会自动合并，保留你的界面修改）"
echo "2) ❌ 跳过此次更新（保持当前版本）"
echo "3) 🔍 查看完整差异"
echo ""
read -p "输入选项 (1-3): " choice

case $choice in
    1)
        echo ""
        echo "🔄 开始同步..."
        # 创建预览分支
        PREVIEW_BRANCH="preview-sync-$(date +%m%d-%H%M)"
        git checkout -b "$PREVIEW_BRANCH" upstream/main
        
        # 应用我们的核心修改（不覆盖界面）
        echo "  - 应用 branding 修改..."
        if [ -f "xwPF.sh" ]; then
            git mv xwPF.sh relay.sh
        fi
        sed -i.bak 's/xwPF/Relay/g' relay.sh 2>/dev/null || true
        rm -f relay.sh.bak
        
        # 添加署名
        if [ -f "README.md" ] && ! grep -q "本项目基于.*realm-xwPF" README.md; then
            cat > /tmp/header.txt << 'EOF'
# Relay - 端口转发管理工具

> 本项目基于 [zywe03/realm-xwPF](https://github.com/zywe03/realm-xwPF) 定制开发  
> **原作者**: [zywe03](https://github.com/zywe03)

---

EOF
            tail -n +3 README.md >> /tmp/header.txt 2>/dev/null || cat README.md >> /tmp/header.txt
            mv /tmp/header.txt README.md
        fi
        
        # 提交到预览分支
        git add -A
        git commit -m "sync: 同步上游更新 $(date +%Y-%m-%d)

- 从 zywe03/realm-xwPF 同步
- 应用 branding 修改
- 保留自定义界面" || true
        
        echo ""
        echo -e "\033[0;32m✅ 已在预览分支: $PREVIEW_BRANCH\033[0m"
        echo ""
        echo "你可以："
        echo "  1. 测试预览分支是否正常"
        echo "  2. 确认没问题后运行: ./apply-sync.sh $PREVIEW_BRANCH"
        echo "  3. 不满意就切回main: git checkout main"
        ;;
    
    2)
        echo ""
        echo "❌ 已跳过此次更新"
        echo "下次检测时间: $(date -v+1d +%Y-%m-%d)"
        ;;
    
    3)
        echo ""
        git log --oneline -10 HEAD..upstream/main
        echo ""
        echo "完整差异已准备好，可运行: git diff HEAD upstream/main | less"
        ;;
    
    *)
        echo ""
        echo "无效选项，已取消"
        ;;
esac

echo ""
echo "📌 提示: 将此脚本加入定时任务可自动检测"
echo "   crontab: 0 9 * * * cd /path/to/relay && ./smart-sync.sh"