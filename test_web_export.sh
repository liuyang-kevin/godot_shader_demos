#!/bin/bash
# start_server.sh

EXPORT_DIR="./export/web"
PORT=8080
GODOT_SCRIPT="./addons/webserver/WebServerAdvanced.gd"

# 检查导出目录是否存在
if [ ! -d "$EXPORT_DIR" ]; then
    echo "错误: 导出目录不存在: $EXPORT_DIR"
    echo "请先导出您的Godot项目到Web平台"
    exit 1
fi

# 启动服务器
echo "启动Godot Web服务器..."
echo "服务目录: $EXPORT_DIR"
echo "端口: $PORT"
echo ""

godot --script "$GODOT_SCRIPT" -- --port "$PORT" --root "$EXPORT_DIR"