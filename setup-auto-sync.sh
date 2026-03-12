#!/bin/bash
#
# 设置自动同步定时任务
# 用法: ./setup-auto-sync.sh
#

echo "=== 设置 Realm Relay 自动同步 ==="
echo ""

# 获取当前目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SYNC_SCRIPT="$SCRIPT_DIR/auto-sync.sh"

# 检查脚本存在
if [ ! -f "$SYNC_SCRIPT" ]; then
    echo "错误: 找不到 auto-sync.sh 脚本"
    exit 1
fi

# 添加执行权限
chmod +x "$SYNC_SCRIPT"

echo "同步脚本路径: $SYNC_SCRIPT"
echo ""

# 询问同步频率
echo "选择同步频率:"
echo "1) 每天检查一次 (推荐)"
echo "2) 每小时检查一次"
echo "3) 每周检查一次"
echo "4) 手动运行（不设置定时任务）"
read -p "请选择 (1-4): " choice

# 根据选择设置 cron
case $choice in
    1)
        # 每天凌晨 3 点检查
        CRON_EXPR="0 3 * * *"
        FREQ_DESC="每天凌晨 3 点"
        ;;
    2)
        # 每小时检查
        CRON_EXPR="0 * * * *"
        FREQ_DESC="每小时"
        ;;
    3)
        # 每周一凌晨 3 点
        CRON_EXPR="0 3 * * 1"
        FREQ_DESC="每周一凌晨 3 点"
        ;;
    4)
        echo ""
        echo "已跳过定时任务设置"
        echo "手动运行请执行: $SYNC_SCRIPT"
        exit 0
        ;;
    *)
        echo "无效选择，默认每天检查"
        CRON_EXPR="0 3 * * *"
        FREQ_DESC="每天凌晨 3 点"
        ;;
esac

# 添加到 crontab
CRON_JOB="$CRON_EXPR cd \"$SCRIPT_DIR\" && ./auto-sync.sh >> /tmp/realm-relay-cron.log 2>&1"

# 先删除旧的相同任务
(crontab -l 2>/dev/null | grep -v "realm-relay" | grep -v "auto-sync") | crontab -

# 添加新任务
(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

echo ""
echo "✅ 定时任务已设置!"
echo "频率: $FREQ_DESC"
echo "日志: /tmp/realm-relay-sync.log"
echo ""
echo "查看定时任务: crontab -l"
echo "手动运行: $SYNC_SCRIPT"
echo ""

# 询问是否立即运行一次
read -p "是否立即运行一次同步检查? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "正在运行..."
    "$SYNC_SCRIPT"
    echo ""
    echo "查看日志:"
    tail -20 /tmp/realm-relay-sync.log
fi
