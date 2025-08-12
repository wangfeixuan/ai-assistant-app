# 数据库建立指南 - 使用Navicat Premium Lite

## 🎯 建立思路总览

### 第一阶段：环境准备
1. **安装PostgreSQL** (如果还没有)
2. **配置数据库服务**
3. **使用Navicat连接数据库**

### 第二阶段：创建数据库
1. **在Navicat中执行SQL脚本**
2. **验证表结构**
3. **测试数据插入**

### 第三阶段：连接后端
1. **配置后端数据库连接**
2. **测试API接口**
3. **验证完整功能**

---

## 📋 详细操作步骤

### 步骤1：安装PostgreSQL（如果需要）

#### 方法A：使用Homebrew（推荐）
```bash
# 安装PostgreSQL
brew install postgresql

# 启动PostgreSQL服务
brew services start postgresql

# 创建数据库
createdb procrastination_ai
```

#### 方法B：官方安装包
- 下载：https://www.postgresql.org/download/macos/
- 安装后启动PostgreSQL服务

### 步骤2：使用Navicat连接数据库

1. **打开Navicat Premium Lite**
2. **新建连接**：
   - 点击左上角"连接" → "PostgreSQL"
   
3. **配置连接信息**：
   ```
   连接名：拖延症AI助手
   主机：localhost (或 127.0.0.1)
   端口：5432
   数据库：procrastination_ai
   用户名：你的系统用户名 (通常是你的Mac用户名)
   密码：(通常为空，或设置的密码)
   ```

4. **测试连接**：
   - 点击"测试连接"按钮
   - 确保连接成功

### 步骤3：执行数据库初始化脚本

1. **在Navicat中打开SQL编辑器**：
   - 右键数据库连接 → "新建查询"

2. **复制粘贴SQL脚本**：
   - 打开 `database/init_database.sql` 文件
   - 复制全部内容到Navicat的SQL编辑器

3. **执行脚本**：
   - 点击"运行"按钮（或按F5）
   - 等待执行完成

4. **验证结果**：
   - 刷新数据库结构
   - 确认所有表都已创建

### 步骤4：验证数据库结构

执行完脚本后，你应该看到以下表：

#### 核心业务表
- `users` - 用户表
- `tasks` - 任务表
- `task_steps` - 任务步骤表
- `chat_sessions` - 聊天会话表
- `chat_messages` - 聊天消息表

#### 功能扩展表
- `pomodoro_settings` - 番茄钟设置
- `pomodoro_sessions` - 番茄钟会话
- `pomodoro_stats` - 番茄钟统计
- `user_themes` - 用户主题设置
- `theme_colors` - 主题颜色配置
- `daily_quotes` - 每日语录
- `custom_quotes` - 自定义语录

#### 系统表
- `user_sessions` - 用户会话管理

---

## 🔧 后端配置

### 更新数据库连接配置

在 `backend/config.py` 中配置数据库连接：

```python
import os

class Config:
    # 数据库配置
    SQLALCHEMY_DATABASE_URI = os.getenv(
        'DATABASE_URL',
        'postgresql://username:password@localhost:5432/procrastination_ai'
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
```

### 创建环境变量文件

在 `backend/.env` 中设置：

```env
# 数据库连接
DATABASE_URL=postgresql://your_username:your_password@localhost:5432/procrastination_ai

# JWT密钥
JWT_SECRET_KEY=your_super_secret_jwt_key_here

# 其他配置
FLASK_ENV=development
FLASK_DEBUG=True
```

---

## 🧪 测试验证

### 1. 启动后端服务
```bash
cd backend
python run_server.py --init-db
```

### 2. 测试API接口
```bash
python test_new_apis.py
```

### 3. 在Navicat中查看数据
- 刷新表结构
- 查看是否有测试数据插入

---

## 🚨 常见问题解决

### 问题1：连接被拒绝
**解决方案**：
```bash
# 检查PostgreSQL是否运行
brew services list | grep postgresql

# 如果没运行，启动服务
brew services start postgresql
```

### 问题2：数据库不存在
**解决方案**：
```bash
# 创建数据库
createdb procrastination_ai
```

### 问题3：权限问题
**解决方案**：
```bash
# 创建用户并授权
createuser --interactive your_username
```

### 问题4：端口被占用
**解决方案**：
- 检查PostgreSQL配置文件
- 或使用其他端口（如5433）

---

## ✅ 完成检查清单

- [ ] PostgreSQL服务已启动
- [ ] Navicat成功连接数据库
- [ ] 数据库初始化脚本执行成功
- [ ] 所有表都已创建
- [ ] 主题颜色初始数据已插入
- [ ] 后端配置文件已更新
- [ ] API测试通过

完成以上步骤后，你的数据库就完全准备好了！🎉
