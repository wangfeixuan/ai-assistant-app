-- 拖延症AI助手 - 数据库初始化脚本
-- 基于DATABASE_DESIGN.md设计
-- 使用方法：在Navicat中连接PostgreSQL数据库后，执行此脚本

-- ============================================
-- 1. 用户管理模块
-- ============================================

-- 用户表
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    avatar_url VARCHAR(500),
    theme_color VARCHAR(20) DEFAULT 'blue',
    is_premium BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- 用户会话表
CREATE TABLE user_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    refresh_token_hash VARCHAR(255),
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_agent TEXT,
    ip_address INET
);

-- ============================================
-- 2. AI聊天模块
-- ============================================

-- AI聊天会话表
CREATE TABLE chat_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- AI聊天消息表
CREATE TABLE chat_messages (
    id SERIAL PRIMARY KEY,
    session_id INTEGER REFERENCES chat_sessions(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    message_type VARCHAR(20) NOT NULL, -- 'user' or 'assistant'
    content TEXT NOT NULL,
    metadata JSONB, -- 存储额外信息
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 3. 任务管理模块
-- ============================================

-- 任务状态枚举类型
CREATE TYPE task_status AS ENUM ('pending', 'in_progress', 'completed', 'cancelled');
CREATE TYPE task_priority AS ENUM ('low', 'medium', 'high', 'urgent');

-- 任务表
CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    original_input TEXT, -- 用户原始输入
    status task_status DEFAULT 'pending',
    priority task_priority DEFAULT 'medium',
    due_date TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 任务步骤表
CREATE TABLE task_steps (
    id SERIAL PRIMARY KEY,
    task_id INTEGER REFERENCES tasks(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    order_index INTEGER NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 4. 番茄钟模块
-- ============================================

-- 番茄钟设置表
CREATE TABLE pomodoro_settings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    work_duration INTEGER DEFAULT 25, -- 工作时间（分钟）
    short_break_duration INTEGER DEFAULT 5, -- 短休息时间
    long_break_duration INTEGER DEFAULT 15, -- 长休息时间
    sessions_until_long_break INTEGER DEFAULT 4, -- 几个番茄钟后长休息
    sound_enabled BOOLEAN DEFAULT TRUE,
    auto_start_breaks BOOLEAN DEFAULT FALSE,
    auto_start_pomodoros BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 番茄钟会话表
CREATE TABLE pomodoro_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    task_id INTEGER REFERENCES tasks(id) ON DELETE SET NULL,
    session_type VARCHAR(20) NOT NULL, -- 'work', 'short_break', 'long_break'
    planned_duration INTEGER NOT NULL, -- 计划时长（分钟）
    actual_duration INTEGER, -- 实际时长（分钟）
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    pause_time TIMESTAMP,
    is_completed BOOLEAN DEFAULT FALSE,
    is_paused BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 番茄钟统计表（每日汇总）
CREATE TABLE pomodoro_stats (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    total_sessions INTEGER DEFAULT 0,
    work_sessions INTEGER DEFAULT 0,
    break_sessions INTEGER DEFAULT 0,
    total_minutes INTEGER DEFAULT 0,
    completed_sessions INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, date)
);

-- ============================================
-- 5. 主题系统模块
-- ============================================

-- 颜色方案枚举类型
CREATE TYPE color_scheme AS ENUM ('pink', 'blue', 'purple', 'green', 'yellow');

-- 用户主题设置表
CREATE TABLE user_themes (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    color_scheme color_scheme DEFAULT 'blue',
    is_dark_mode BOOLEAN DEFAULT FALSE,
    custom_settings JSONB, -- 自定义设置
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- 主题颜色配置表
CREATE TABLE theme_colors (
    id SERIAL PRIMARY KEY,
    color_scheme color_scheme UNIQUE NOT NULL,
    name VARCHAR(50) NOT NULL,
    primary_color VARCHAR(7) NOT NULL, -- #RRGGBB
    secondary_color VARCHAR(7) NOT NULL,
    accent_color VARCHAR(7) NOT NULL,
    background_color VARCHAR(7) NOT NULL,
    surface_color VARCHAR(7) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 6. 每日语录模块
-- ============================================

-- 每日语录表
CREATE TABLE daily_quotes (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    quote_text TEXT NOT NULL,
    quote_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 用户自定义语录表
CREATE TABLE custom_quotes (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    quote_text TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 7. 创建索引
-- ============================================

-- 用户表索引
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_created_at ON users(created_at);

-- 会话表索引
CREATE INDEX idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_expires_at ON user_sessions(expires_at);

-- 聊天表索引
CREATE INDEX idx_chat_sessions_user_id ON chat_sessions(user_id);
CREATE INDEX idx_chat_messages_session_id ON chat_messages(session_id);
CREATE INDEX idx_chat_messages_created_at ON chat_messages(created_at);

-- 任务表索引
CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_created_at ON tasks(created_at);
CREATE INDEX idx_task_steps_task_id ON task_steps(task_id);
CREATE INDEX idx_task_steps_order ON task_steps(order_index);

-- 番茄钟表索引
CREATE INDEX idx_pomodoro_sessions_user_id ON pomodoro_sessions(user_id);
CREATE INDEX idx_pomodoro_sessions_start_time ON pomodoro_sessions(start_time);
CREATE INDEX idx_pomodoro_stats_user_date ON pomodoro_stats(user_id, date);

-- 主题表索引
CREATE INDEX idx_user_themes_user_id ON user_themes(user_id);

-- 语录表索引
CREATE INDEX idx_daily_quotes_user_date ON daily_quotes(user_id, quote_date);
CREATE INDEX idx_custom_quotes_user_id ON custom_quotes(user_id);

-- ============================================
-- 8. 初始化数据
-- ============================================

-- 插入主题颜色配置
INSERT INTO theme_colors (color_scheme, name, primary_color, secondary_color, accent_color, background_color, surface_color, description) VALUES
('pink', '粉色', '#FF6B9D', '#FFB3D1', '#FF8FA3', '#FFF5F8', '#FFFFFF', '温柔浪漫的粉色主题'),
('blue', '蓝色', '#2196F3', '#64B5F6', '#42A5F5', '#F3F9FF', '#FFFFFF', '专业稳重的蓝色主题'),
('purple', '紫色', '#9C27B0', '#BA68C8', '#AB47BC', '#F8F5FF', '#FFFFFF', '神秘优雅的紫色主题'),
('green', '绿色', '#4CAF50', '#81C784', '#66BB6A', '#F5FFF5', '#FFFFFF', '清新自然的绿色主题'),
('yellow', '黄色', '#FF9800', '#FFB74D', '#FFA726', '#FFFBF0', '#FFFFFF', '活力阳光的黄色主题');

-- ============================================
-- 9. 创建触发器（自动更新updated_at字段）
-- ============================================

-- 创建更新时间戳函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为需要的表创建触发器
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_chat_sessions_updated_at BEFORE UPDATE ON chat_sessions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_pomodoro_settings_updated_at BEFORE UPDATE ON pomodoro_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_pomodoro_stats_updated_at BEFORE UPDATE ON pomodoro_stats FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_themes_updated_at BEFORE UPDATE ON user_themes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_theme_colors_updated_at BEFORE UPDATE ON theme_colors FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_daily_quotes_updated_at BEFORE UPDATE ON daily_quotes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_custom_quotes_updated_at BEFORE UPDATE ON custom_quotes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 完成！
-- ============================================

-- 显示创建的表
SELECT 
    schemaname,
    tablename,
    tableowner
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;
