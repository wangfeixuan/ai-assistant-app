# 拖延症AI助手 - 启动指南

## 概述
本项目包含三个主要组件：
- **后端**: Python Flask API 服务
- **前端**: Flutter 移动应用
- **数据库**: PostgreSQL + Redis 缓存

## 启动步骤

### 第一步：环境配置

1. **配置环境变量**
   ```bash
   # 已完成：.env 文件已创建
   # 需要编辑 .env 文件，填入实际配置值
   ```

2. **创建虚拟环境**（推荐）
   ```bash
   # 使用 conda（推荐）
   conda create -n procrastination-ai python=3.9
   conda activate procrastination-ai
   
   # 或使用 venv
   python -m venv venv
   source venv/bin/activate  # macOS/Linux
   ```

3. **安装 Python 依赖**
   ```bash
   pip install -r requirements.txt
   ```

### 第二步：数据库准备

1. **启动 PostgreSQL**
   ```bash
   # 如果使用 Homebrew 安装的 PostgreSQL
   brew services start postgresql
   
   # 或者使用 Docker
   docker run --name postgres-ai -e POSTGRES_PASSWORD=password -p 5432:5432 -d postgres
   ```

2. **创建数据库**
   ```bash
   # 连接到 PostgreSQL
   psql postgres
   
   # 创建数据库
   CREATE DATABASE procrastination_ai;
   \q
   ```

3. **启动 Redis**
   ```bash
   # 如果使用 Homebrew 安装的 Redis
   brew services start redis
   
   # 或者使用 Docker
   docker run --name redis-ai -p 6379:6379 -d redis
   ```

### 第三步：启动后端服务

1. **进入后端目录并初始化数据库**
   ```bash
   cd backend
   
   # 初始化数据库表
   python -c "from app import create_app, db; app = create_app(); app.app_context().push(); db.create_all()"
   ```

2. **启动 Flask 服务**
   ```bash
   # 方式1：直接运行
   python app.py
   
   # 方式2：使用 Flask 命令
   export FLASK_APP=app.py
   flask run --host=0.0.0.0 --port=5000
   ```

   **重要**: 使用 `--host=0.0.0.0` 确保 Flutter 应用可以从手机连接到后端

### 第四步：启动 Flutter 应用

1. **确保 Flutter 环境已配置**
   ```bash
   # 检查 Flutter 安装
   flutter doctor
   
   # 如果需要配置 PATH（参考记忆）
   export PATH="$PATH:/Users/wangfeixuan/development/flutter/bin"
   ```

2. **进入 Flutter 项目目录**
   ```bash
   cd flutter_ai_assistant
   ```

3. **获取依赖**
   ```bash
   flutter pub get
   ```

4. **配置网络连接**
   - 编辑 Flutter 应用中的 baseUrl
   - 将 localhost 改为你的 Mac 的局域网 IP 地址
   - 例如：`http://192.168.21.169:5000`

5. **启动 Flutter 应用**
   ```bash
   # 连接设备后运行
   flutter run
   
   # 或者指定设备
   flutter devices  # 查看可用设备
   flutter run -d <device_id>
   ```

## 验证启动状态

### 检查后端服务
```bash
curl http://localhost:5000/api/health
# 或
curl http://你的IP:5000/api/health
```

### 检查数据库连接
```bash
# PostgreSQL
psql -h localhost -U username -d procrastination_ai

# Redis
redis-cli ping
```

### 检查 Flutter 应用
- 应用应该能够正常启动
- 登录/注册功能应该能连接到后端
- 检查控制台是否有网络错误

## 常见问题解决

### 1. Flutter 无法连接后端
- 确保后端使用 `--host=0.0.0.0` 启动
- 检查 Flutter 中的 baseUrl 是否使用正确的 IP 地址
- 确保防火墙允许 5000 端口访问

### 2. 数据库连接失败
- 检查 PostgreSQL 服务是否运行
- 验证 .env 文件中的数据库配置
- 确保数据库已创建

### 3. API 字段不匹配
- 登录 API：Flutter 发送 'login' 字段（不是 'email'）
- 注册 API：需要 username, email, password 字段

## 启动顺序总结

1. **启动基础服务**: PostgreSQL → Redis
2. **配置环境**: 虚拟环境 → 安装依赖 → 配置 .env
3. **启动后端**: 初始化数据库 → 启动 Flask 服务
4. **启动前端**: 配置网络 → 启动 Flutter 应用
5. **验证**: 测试各组件连接状态

## 下次启动的快速命令

创建启动脚本后，下次只需：
```bash
# 启动后端
./start_backend.sh

# 启动前端
./start_flutter.sh
```
