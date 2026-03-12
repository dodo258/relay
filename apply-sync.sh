#!/bin/bash
#
# 应用同步分支到 main
# 用法: ./apply-sync.sh <预览分支名>
#

if [ -z "$1" ]; then
    echo "用法: $0 <预览分支名>"
    echo "示例: $0 preview-sync-0312-1430"
    exit 1
fi

PREVIEW_BRANCH="$1"

echo "=== 应用同步分支 ==="
echo ""

# 检查分支是否存在
if ! git branch | grep -q "$PREVIEW_BRANCH"; then
    echo "错误: 分支 $PREVIEW_BRANCH 不存在"
    exit 1
fi

echo "合并 $PREVIEW_BRANCH → main"
git checkout main
git merge "$PREVIEW_BRANCH" --no-ff -m "Merge: 应用同步更新

合并分支: $PREVIEW_BRANCH
时间: $(date '+%Y-%m-%d %H:%M')"

# 删除预览分支
git branch -d "$PREVIEW_BRANCH"

# 推送到 GitHub
echo ""
echo "推送到 GitHub..."
git push origin main

echo ""
echo "✅ 同步完成并已推送！"
