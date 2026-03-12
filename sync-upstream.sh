#!/bin/bash
#
# realm-relay 同步脚本
# 功能：同步上游 zywe03/realm-xwPF 更新，自动应用我们的 branding 修改
#

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Realm Relay 同步脚本 ===${NC}"
echo ""

# 检查是否在正确的仓库目录
if [ ! -d ".git" ]; then
    echo -e "${RED}错误：当前目录不是 Git 仓库${NC}"
    echo "请在 realm-relay 仓库根目录运行此脚本"
    exit 1
fi

# 确保上游仓库已配置
if ! git remote | grep -q "upstream"; then
    echo -e "${YELLOW}添加上游仓库...${NC}"
    git remote add upstream https://github.com/zywe03/realm-xwPF.git
fi

echo -e "${GREEN}1. 获取上游更新...${NC}"
git fetch upstream

# 检查上游是否有更新
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse upstream/main)
BASE=$(git merge-base @ upstream/main)

if [ $LOCAL = $REMOTE ]; then
    echo -e "${GREEN}✓ 已经是最新，无需同步${NC}"
    exit 0
elif [ $LOCAL = $BASE ]; then
    echo -e "${YELLOW}→ 上游有新更新，准备同步...${NC}"
else
    echo -e "${YELLOW}⚠ 本地有未推送的修改，建议先提交${NC}"
    read -p "是否继续? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo -e "${GREEN}2. 创建同步分支...${NC}"
SYNC_BRANCH="sync-upstream-$(date +%Y%m%d-%H%M%S)"
git checkout -b $SYNC_BRANCH upstream/main

echo ""
echo -e "${GREEN}3. 应用我们的 branding 修改...${NC}"

# 3.1 重命名主脚本（如果上游脚本是 xwPF.sh）
if [ -f "xwPF.sh" ]; then
    echo "  - 重命名 xwPF.sh → relay.sh"
    git mv xwPF.sh relay.sh
fi

# 3.2 替换脚本内的品牌名
if [ -f "relay.sh" ]; then
    echo "  - 更新脚本内品牌名 xwPF → Relay"
    sed -i '' 's/xwPF/Relay/g' relay.sh 2>/dev/null || sed -i 's/xwPF/Relay/g' relay.sh
fi

# 3.3 添加我们的 README 头部（保留原作者署名）
echo "  - 更新 README 署名"
if [ -f "README.md" ]; then
    # 检查是否已有我们的署名
    if ! grep -q "本项目基于.*realm-xwPF" README.md; then
        # 在文件开头添加署名
        cat > /tmp/readme_header.txt << 'EOF'
# Relay - 端口转发管理工具

> 本项目基于 [zywe03/realm-xwPF](https://github.com/zywe03/realm-xwPF) 定制开发  
> **原作者**: [zywe03](https://github.com/zywe03)

---

EOF
        # 保留原 README 内容（去掉原有的标题行）
        tail -n +3 README.md >> /tmp/readme_header.txt
        mv /tmp/readme_header.txt README.md
    fi
fi

echo ""
echo -e "${GREEN}4. 检查修改状态...${NC}"
git status

echo ""
echo -e "${YELLOW}=== 请检查以下内容 ===${NC}"
echo "1. 核心脚本功能是否正常"
echo "2. README 中文教程是否完整"
echo "3. 原作者署名是否正确"
echo ""
read -p "确认无误后按回车继续提交，或 Ctrl+C 取消..."

echo ""
echo -e "${GREEN}5. 提交修改...${NC}"
git add -A
git commit -m "sync: 同步上游更新 $(date +%Y-%m-%d)

- 从 zywe03/realm-xwPF 同步最新代码
- 应用 branding 修改：xwPF → Relay
- 保留原作者署名
- 保留中文使用教程"

echo ""
echo -e "${GREEN}6. 合并到 main 分支...${NC}"
git checkout main
git merge $SYNC_BRANCH --no-ff -m "Merge: 同步上游更新

合并分支: $SYNC_BRANCH"

# 删除临时分支
git branch -d $SYNC_BRANCH

echo ""
echo -e "${GREEN}7. 推送到 GitHub...${NC}"
git push origin main

echo ""
echo -e "${GREEN}✅ 同步完成！${NC}"
echo ""
echo "更新内容:"
git log --oneline -3
