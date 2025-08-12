#!/bin/bash

# 拖延症AI助手 - 后端启动脚本

echo "🚀 启动拖延症AI助手后端服务..."

# 检查是否在虚拟环境中
if [[ "$VIRTUAL_ENV" == "" ]]; then
    echo "⚠️  建议先激活虚拟环境："
    echo "   conda activate procrastination-ai"
    echo "   或 source venv/bin/activate"
    echo ""
fi

# 检查环境变量文件
if [ ! -f ".env" ]; then
    echo "❌ .env 文件不存在，请先配置环境变量"
    exit 1
fi

# 启动 PostgreSQL（如果使用 Homebrew）
echo "📊 启动 PostgreSQL..."
brew services start postgresql 2>/dev/null || echo "PostgreSQL 可能已经在运行或需要手动启动"

# 启动 Redis
echo "🔄 启动 Redis..."
brew services start redis 2>/dev/null || echo "Redis 可能已经在运行或需要手动启动"

# 等待服务启动
sleep 2

# 进入后端目录
cd backend

# 检查数据库表是否存在，如果不存在则创建
echo "🗄️  初始化数据库..."
python3 -c "
from app import create_app, db
app = create_app()
with app.app_context():
    db.create_all()
    print('数据库表已创建或已存在')
" 2>/dev/null || echo "数据库初始化可能需要手动处理"

# 获取本机 IP 地址
LOCAL_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)

echo "🌐 本机 IP 地址: $LOCAL_IP"
echo "📱 请确保 Flutter 应用中的 baseUrl 设置为: http://$LOCAL_IP:5001"
echo ""

# 启动 Flask 服务
echo "🔥 启动 Flask 服务..."
echo "服务将在 http://0.0.0.0:5001 启动"
echo "按 Ctrl+C 停止服务"
echo ""

python3 app.py
