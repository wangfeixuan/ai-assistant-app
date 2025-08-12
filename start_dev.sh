#!/bin/bash
# 开发环境启动脚本
# 自动检测IP变化，启动后端服务，运行Flutter应用

echo "🚀 启动拖延症AI助手开发环境..."

# 1. 检测并更新IP地址
echo "📍 检测IP地址变化..."
python3 scripts/update_flutter_ip.py

# 2. 启动后端服务（如果没有运行）
echo "🔧 检查后端服务状态..."
if ! lsof -i :5001 > /dev/null 2>&1; then
    echo "启动后端服务..."
    cd backend
    python3 run_server.py &
    BACKEND_PID=$!
    echo "后端服务已启动 (PID: $BACKEND_PID)"
    cd ..
else
    echo "✅ 后端服务已在运行"
fi

# 3. 等待后端服务启动
echo "⏳ 等待后端服务就绪..."
sleep 3

# 4. 测试API连接
echo "🔍 测试API连接..."
CURRENT_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
if curl -s "http://$CURRENT_IP:5001/api/procrastination/diary?page=1&per_page=1" > /dev/null; then
    echo "✅ API连接正常"
else
    echo "❌ API连接失败，请检查后端服务"
    exit 1
fi

# 5. 启动Flutter应用
echo "📱 启动Flutter应用..."
cd flutter_ai_assistant
flutter run --device-id=$(flutter devices | grep iPhone | head -1 | awk '{print $5}' | tr -d '•')

echo "🎉 开发环境启动完成！"
