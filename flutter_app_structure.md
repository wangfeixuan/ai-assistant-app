# Flutter App 项目结构规划

## 项目概览
基于现有HTML项目，重构为Flutter移动应用，集成新的颜色主题系统和番茄钟功能。

## 目录结构
```
flutter_ai_assistant/
├── lib/
│   ├── main.dart                    # 应用入口
│   ├── app.dart                     # 应用配置
│   ├── core/                        # 核心功能
│   │   ├── constants/
│   │   │   ├── app_colors.dart      # 颜色常量
│   │   │   ├── app_strings.dart     # 文本常量
│   │   │   └── app_sizes.dart       # 尺寸常量
│   │   ├── themes/
│   │   │   ├── app_theme.dart       # 主题配置
│   │   │   ├── color_themes.dart    # 5种颜色主题
│   │   │   └── theme_manager.dart   # 主题管理器
│   │   ├── utils/
│   │   │   ├── date_utils.dart      # 日期工具
│   │   │   └── storage_utils.dart   # 本地存储
│   │   └── services/
│   │       ├── theme_service.dart   # 主题服务
│   │       ├── notification_service.dart # 通知服务
│   │       └── storage_service.dart # 存储服务
│   ├── features/                    # 功能模块
│   │   ├── daily_quote/            # 每日语录
│   │   │   ├── models/
│   │   │   │   └── quote_model.dart
│   │   │   ├── widgets/
│   │   │   │   └── daily_quote_card.dart
│   │   │   └── providers/
│   │   │       └── quote_provider.dart
│   │   ├── ai_chat/                # AI助手聊天
│   │   │   ├── models/
│   │   │   │   ├── message_model.dart
│   │   │   │   └── task_model.dart
│   │   │   ├── widgets/
│   │   │   │   ├── chat_bubble.dart
│   │   │   │   ├── message_input.dart
│   │   │   │   └── task_decomposer.dart
│   │   │   ├── screens/
│   │   │   │   └── ai_chat_screen.dart
│   │   │   └── providers/
│   │   │       └── chat_provider.dart
│   │   ├── todo/                   # 待办事项
│   │   │   ├── models/
│   │   │   │   └── todo_model.dart
│   │   │   ├── widgets/
│   │   │   │   ├── todo_item.dart
│   │   │   │   └── todo_list.dart
│   │   │   ├── screens/
│   │   │   │   └── todo_screen.dart
│   │   │   └── providers/
│   │   │       └── todo_provider.dart
│   │   ├── pomodoro/               # 番茄钟功能
│   │   │   ├── models/
│   │   │   │   ├── pomodoro_mode.dart
│   │   │   │   └── pomodoro_session.dart
│   │   │   ├── widgets/
│   │   │   │   ├── timer_circle.dart
│   │   │   │   ├── mode_selector.dart
│   │   │   │   └── timer_controls.dart
│   │   │   ├── screens/
│   │   │   │   └── pomodoro_screen.dart
│   │   │   └── providers/
│   │   │       └── pomodoro_provider.dart
│   │   ├── profile/                # 个人页面
│   │   │   ├── widgets/
│   │   │   │   ├── color_theme_picker.dart
│   │   │   │   ├── user_avatar.dart
│   │   │   │   └── settings_section.dart
│   │   │   ├── screens/
│   │   │   │   └── profile_screen.dart
│   │   │   └── providers/
│   │   │       └── profile_provider.dart
│   │   └── auth/                   # 认证功能
│   │       ├── models/
│   │       │   └── user_model.dart
│   │       ├── widgets/
│   │       │   ├── login_form.dart
│   │       │   └── auth_button.dart
│   │       ├── screens/
│   │       │   └── auth_screen.dart
│   │       └── providers/
│   │           └── auth_provider.dart
│   ├── shared/                     # 共享组件
│   │   ├── widgets/
│   │   │   ├── custom_app_bar.dart
│   │   │   ├── custom_button.dart
│   │   │   ├── custom_card.dart
│   │   │   ├── loading_widget.dart
│   │   │   └── notification_widget.dart
│   │   └── layouts/
│   │       ├── main_layout.dart
│   │       └── bottom_navigation.dart
│   └── screens/                    # 主要页面
│       ├── home_screen.dart        # 主页面（包含底部导航）
│       └── splash_screen.dart      # 启动页面
├── assets/                         # 资源文件
│   ├── images/
│   ├── icons/
│   └── sounds/
│       └── notification.mp3        # 番茄钟提示音
├── test/                          # 测试文件
├── pubspec.yaml                   # 依赖配置
└── README.md                      # 项目说明
```

## 核心功能映射

### 1. 颜色主题系统
**HTML → Flutter**
- `css/color-themes.css` → `lib/core/themes/color_themes.dart`
- `js/color-themes.js` → `lib/core/themes/theme_manager.dart`
- 颜色选择器 → `lib/features/profile/widgets/color_theme_picker.dart`

### 2. 番茄钟功能
**HTML → Flutter**
- `js/pomodoro-timer.js` → `lib/features/pomodoro/providers/pomodoro_provider.dart`
- `css/pomodoro-timer.css` → `lib/features/pomodoro/widgets/timer_circle.dart`
- 模态框 → `lib/features/pomodoro/screens/pomodoro_screen.dart`

### 3. AI助手聊天
**HTML → Flutter**
- 聊天界面 → `lib/features/ai_chat/screens/ai_chat_screen.dart`
- 任务分解 → `lib/features/ai_chat/widgets/task_decomposer.dart`
- 消息气泡 → `lib/features/ai_chat/widgets/chat_bubble.dart`

### 4. 每日语录
**HTML → Flutter**
- 语录卡片 → `lib/features/daily_quote/widgets/daily_quote_card.dart`
- 自动更新逻辑 → `lib/features/daily_quote/providers/quote_provider.dart`

### 5. 待办事项
**HTML → Flutter**
- 待办列表 → `lib/features/todo/widgets/todo_list.dart`
- 待办项目 → `lib/features/todo/widgets/todo_item.dart`

## 技术栈选择

### 状态管理
- **Provider** - 轻量级，适合中小型应用
- 替代方案：Riverpod（更现代）或 Bloc（大型应用）

### 本地存储
- **SharedPreferences** - 简单键值对存储（主题设置、用户偏好）
- **Hive** - 轻量级数据库（待办事项、聊天记录）

### UI组件
- **Material Design 3** - 现代化的UI设计
- **自定义主题** - 支持5种颜色主题

### 动画
- **Flutter内置动画** - 页面切换、主题切换动画
- **Lottie** - 复杂动画效果（可选）

## 开发阶段规划

### 阶段1：基础框架（1-2天）
1. 创建Flutter项目
2. 设置项目结构
3. 配置依赖
4. 实现基础导航

### 阶段2：主题系统（1天）
1. 实现5种颜色主题
2. 主题管理器
3. 颜色选择器组件
4. 主题持久化

### 阶段3：核心功能（2-3天）
1. 每日语录组件
2. AI聊天界面
3. 待办事项管理
4. 番茄钟功能

### 阶段4：完善优化（1天）
1. 用户认证
2. 数据持久化
3. 性能优化
4. 测试和调试

## 依赖包清单

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # 状态管理
  provider: ^6.1.1
  
  # 本地存储
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # UI组件
  cupertino_icons: ^1.0.6
  # 工具类
  intl: ^0.18.1          # 国际化和日期格式化
  
  # 网络请求（如果需要）
  http: ^1.1.0
  
  # 音频播放（番茄钟提示音）
  audioplayers: ^5.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  hive_generator: ^2.0.1
  build_runner: ^2.4.7
```

## 下一步行动
1. 等待Flutter安装完成
2. 创建Flutter项目
3. 实现基础项目结构
4. 开始核心功能开发
