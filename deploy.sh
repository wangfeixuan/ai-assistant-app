#!/bin/bash

echo "🚀 AI助手部署脚本"
echo "=================="

# 检查是否在正确的目录
if [ ! -f "requirements.txt" ]; then
    echo "❌ 请在项目根目录运行此脚本"
    exit 1
fi

echo "📦 准备部署文件..."

# 创建 .gitignore 文件（如果不存在）
if [ ! -f ".gitignore" ]; then
    cat > .gitignore << EOF
# Python
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
env/
venv/
.venv/
pip-log.txt
pip-delete-this-directory.txt
.tox/
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
*.log
.git
.mypy_cache
.pytest_cache
.hypothesis

# Flutter
flutter_ai_assistant/build/
flutter_ai_assistant/.dart_tool/
flutter_ai_assistant/.flutter-plugins
flutter_ai_assistant/.flutter-plugins-dependencies
flutter_ai_assistant/.packages
flutter_ai_assistant/pubspec.lock

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Logs
*.log
backend/backend.log
backend/server.log

# Environment
.env.local
.env.production
EOF
    echo "✅ 创建了 .gitignore 文件"
fi

# 检查 Git 状态
if [ ! -d ".git" ]; then
    echo "🔧 初始化 Git 仓库..."
    git init
    git add .
    git commit -m "🎉 初始化AI助手项目"
    echo "✅ Git 仓库已初始化"
else
    echo "📝 更新 Git 仓库..."
    git add .
    git commit -m "🔄 更新项目文件"
    echo "✅ Git 仓库已更新"
fi

echo ""
echo "🎯 下一步操作："
echo "1. 在 GitHub 创建新仓库：ai-assistant-app"
echo "2. 运行以下命令连接到 GitHub："
echo "   git remote add origin https://github.com/你的用户名/ai-assistant-app.git"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "3. 然后按照 '手机部署指南.md' 继续部署到 Railway 和 Vercel"
echo ""
echo "🆘 需要帮助？查看 '手机部署指南.md' 文件！"
