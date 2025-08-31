#!/bin/bash
# export_web.sh

PROJECT_DIR="."
EXPORT_DIR="$PROJECT_DIR/build/web"
PRESET_NAME="Web" # 必须与Godot编辑器中的预设名称完全一致

# 创建导出目录
mkdir -p $EXPORT_DIR

# 切换到项目目录
cd $PROJECT_DIR

# 导出Web版本
echo "正在导出Web版本..."
godot --headless --export-release "$PRESET_NAME" "$EXPORT_DIR/index.html"

# 检查导出是否成功
if [ $? -eq 0 ]; then
    echo "导出成功！文件位于: $EXPORT_DIR"
else
    echo "导出失败！"
    exit 1
fi