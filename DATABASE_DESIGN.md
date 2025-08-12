# 小AI助手 - 完整数据库设计

## 数据库概述

基于你的项目需求，设计了一个完整的数据库架构，支持用户管理、AI聊天、任务管理、番茄钟功能和主题设置。

## 技术选择

- **开发环境**: SQLite (轻量级，适合开发测试)
- **生产环境**: PostgreSQL (高性能，支持复杂查询)
- **ORM**: SQLAlchemy (Python) / Hive (Flutter本地存储)

## 数据库表设计

### 1. 用户管理模块

#### users (用户表)
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    avatar_url VARCHAR(500),
    theme_color VARCHAR(20) DEFAULT 'blue', -- 新增：主题颜色
    is_premium BOOLEAN DEFAULT FALSE, -- 是否付费用户
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- 索引
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_created_at ON users(created_at);
```

#### user_sessions (用户会话表)
```sql
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    refresh_token_hash VARCHAR(255),
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_agent TEXT,
    ip_address INET
);

-- 索引
CREATE INDEX idx_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_sessions_token ON user_sessions(token_hash);
CREATE INDEX idx_sessions_expires ON user_sessions(expires_at);
```

### 2. AI聊天模块

#### chat_conversations (聊天会话表)
```sql
CREATE TABLE chat_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) DEFAULT '新对话',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_archived BOOLEAN DEFAULT FALSE
);

-- 索引
CREATE INDEX idx_conversations_user_id ON chat_conversations(user_id);
CREATE INDEX idx_conversations_updated_at ON chat_conversations(updated_at);
```

#### chat_messages (聊天消息表)
```sql
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES chat_conversations(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL, -- 'user' 或 'assistant'
    content TEXT NOT NULL,
    metadata JSONB, -- 存储额外信息，如任务分解结果
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT check_role CHECK (role IN ('user', 'assistant'))
);

-- 索引
CREATE INDEX idx_messages_conversation_id ON chat_messages(conversation_id);
CREATE INDEX idx_messages_created_at ON chat_messages(created_at);
CREATE INDEX idx_messages_role ON chat_messages(role);
```

### 3. 任务管理模块

#### tasks (任务表)
```sql
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    conversation_id UUID REFERENCES chat_conversations(id) ON DELETE SET NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    priority VARCHAR(10) DEFAULT 'medium', -- 'low', 'medium', 'high'
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'in_progress', 'completed', 'cancelled'
    due_date DATE,
    estimated_minutes INTEGER, -- 预估完成时间（分钟）
    actual_minutes INTEGER, -- 实际完成时间（分钟）
    parent_task_id UUID REFERENCES tasks(id) ON DELETE CASCADE, -- 支持子任务
    order_index INTEGER DEFAULT 0, -- 排序
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    
    CONSTRAINT check_priority CHECK (priority IN ('low', 'medium', 'high')),
    CONSTRAINT check_status CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled'))
);

-- 索引
CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
CREATE INDEX idx_tasks_parent_id ON tasks(parent_task_id);
CREATE INDEX idx_tasks_created_at ON tasks(created_at);
```

#### task_steps (任务步骤表)
```sql
CREATE TABLE task_steps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    is_completed BOOLEAN DEFAULT FALSE,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

-- 索引
CREATE INDEX idx_task_steps_task_id ON task_steps(task_id);
CREATE INDEX idx_task_steps_order ON task_steps(order_index);
```

### 4. 番茄钟模块

#### pomodoro_sessions (番茄钟会话表)
```sql
CREATE TABLE pomodoro_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    task_id UUID REFERENCES tasks(id) ON DELETE SET NULL,
    mode VARCHAR(20) NOT NULL, -- 'pomodoro', 'short_break', 'long_break'
    duration_minutes INTEGER NOT NULL, -- 设定时长
    actual_minutes INTEGER, -- 实际时长
    started_at TIMESTAMP NOT NULL,
    ended_at TIMESTAMP,
    completed BOOLEAN DEFAULT FALSE,
    interrupted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT check_mode CHECK (mode IN ('pomodoro', 'short_break', 'long_break'))
);

-- 索引
CREATE INDEX idx_pomodoro_user_id ON pomodoro_sessions(user_id);
CREATE INDEX idx_pomodoro_task_id ON pomodoro_sessions(task_id);
CREATE INDEX idx_pomodoro_started_at ON pomodoro_sessions(started_at);
CREATE INDEX idx_pomodoro_mode ON pomodoro_sessions(mode);
```

#### pomodoro_stats (番茄钟统计表)
```sql
CREATE TABLE pomodoro_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    completed_pomodoros INTEGER DEFAULT 0,
    total_focus_minutes INTEGER DEFAULT 0,
    total_break_minutes INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, date)
);

-- 索引
CREATE INDEX idx_pomodoro_stats_user_date ON pomodoro_stats(user_id, date);
CREATE INDEX idx_pomodoro_stats_date ON pomodoro_stats(date);
```

### 5. 每日语录模块

#### daily_quotes (每日语录表)
```sql
CREATE TABLE daily_quotes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content TEXT NOT NULL,
    author VARCHAR(100),
    category VARCHAR(50), -- 'motivation', 'productivity', 'wisdom'
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT check_category CHECK (category IN ('motivation', 'productivity', 'wisdom'))
);

-- 索引
CREATE INDEX idx_quotes_category ON daily_quotes(category);
CREATE INDEX idx_quotes_active ON daily_quotes(is_active);
```

#### user_quote_history (用户语录历史表)
```sql
CREATE TABLE user_quote_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    quote_id UUID REFERENCES daily_quotes(id) ON DELETE CASCADE,
    shown_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, shown_date)
);

-- 索引
CREATE INDEX idx_quote_history_user_date ON user_quote_history(user_id, shown_date);
```

### 6. 用户设置模块

#### user_preferences (用户偏好设置表)
```sql
CREATE TABLE user_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    theme_color VARCHAR(20) DEFAULT 'blue', -- 'blue', 'pink', 'purple', 'green', 'yellow'
    pomodoro_duration INTEGER DEFAULT 25, -- 番茄钟时长（分钟）
    short_break_duration INTEGER DEFAULT 5,
    long_break_duration INTEGER DEFAULT 15,
    auto_start_breaks BOOLEAN DEFAULT FALSE,
    notification_enabled BOOLEAN DEFAULT TRUE,
    sound_enabled BOOLEAN DEFAULT TRUE,
    daily_goal INTEGER DEFAULT 8, -- 每日目标番茄钟数量
    timezone VARCHAR(50) DEFAULT 'UTC',
    language VARCHAR(10) DEFAULT 'zh-CN',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT check_theme_color CHECK (theme_color IN ('blue', 'pink', 'purple', 'green', 'yellow'))
);

-- 索引
CREATE INDEX idx_preferences_user_id ON user_preferences(user_id);
```

### 7. 系统日志模块

#### activity_logs (活动日志表)
```sql
CREATE TABLE activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(50) NOT NULL, -- 'login', 'task_created', 'pomodoro_completed', etc.
    resource_type VARCHAR(50), -- 'task', 'pomodoro', 'user', etc.
    resource_id UUID,
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 索引
CREATE INDEX idx_activity_logs_user_id ON activity_logs(user_id);
CREATE INDEX idx_activity_logs_action ON activity_logs(action);
CREATE INDEX idx_activity_logs_created_at ON activity_logs(created_at);
```

## 数据关系图

```
users (1) -----> (N) chat_conversations
users (1) -----> (N) tasks
users (1) -----> (N) pomodoro_sessions
users (1) -----> (1) user_preferences
users (1) -----> (N) user_quote_history

chat_conversations (1) -----> (N) chat_messages
chat_conversations (1) -----> (N) tasks

tasks (1) -----> (N) task_steps
tasks (1) -----> (N) pomodoro_sessions
tasks (1) -----> (N) tasks (parent-child)

daily_quotes (1) -----> (N) user_quote_history
```

## 初始化数据

### 默认语录数据
```sql
INSERT INTO daily_quotes (content, author, category) VALUES
('每一个小步骤都是向目标迈进的勇敢尝试', '小AI助手', 'motivation'),
('今天的努力是明天成功的基石', '小AI助手', 'productivity'),
('专注当下，未来自然会到来', '小AI助手', 'wisdom'),
('拖延是梦想的敌人，行动是成功的朋友', '小AI助手', 'motivation'),
('每个番茄钟都是一次小小的胜利', '小AI助手', 'productivity');
```

### 默认用户偏好
```sql
-- 这个会在用户注册时自动创建
```

## 数据库优化建议

### 1. 性能优化
- 为经常查询的字段添加索引
- 使用分区表处理大量历史数据
- 定期清理过期的会话数据

### 2. 数据备份
- 每日自动备份
- 重要操作前手动备份
- 异地备份策略

### 3. 监控指标
- 查询性能监控
- 存储空间使用情况
- 连接数监控

## Flutter本地存储设计

对于Flutter应用，使用Hive进行本地存储：

```dart
// 用户偏好
@HiveType(typeId: 0)
class UserPreferences {
  @HiveField(0)
  String themeColor;
  
  @HiveField(1)
  int pomodoroDuration;
  
  @HiveField(2)
  bool notificationEnabled;
}

// 本地任务缓存
@HiveType(typeId: 1)
class LocalTask {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String title;
  
  @HiveField(2)
  bool isCompleted;
  
  @HiveField(3)
  DateTime createdAt;
}
```

这个数据库设计支持你的所有功能需求，包括新的颜色主题系统和番茄钟功能。你觉得还需要调整哪些部分？
