class AppConfig {
  // 🌐 网络配置选项 - 生产环境使用Railway部署的后端
  
  // 🚀 生产环境: Railway部署的后端 (推荐用于移动端独立使用)
  static const String baseUrl = 'https://ai-assistant-app-production.up.railway.app';
  
  // 📱 开发选项1: iPhone热点模式 (本地开发时使用) 
  // 使用步骤: 1.开启iPhone热点 2.Mac连接热点 3.取消下面这行注释
  // static const String baseUrl = 'http://172.20.10.6:5001';
  
  // 🏠 开发选项2: 同一WiFi模式 (本地开发时使用)
  // 确保iPhone和Mac连接同一WiFi，然后取消下面这行注释
  // static const String baseUrl = 'http://192.168.21.153:5001';
  
  // 💻 开发选项3: 模拟器模式 (仅用于iOS模拟器)
  // static const String baseUrl = 'http://localhost:5001';
  
  // 🔧 如果需要本地开发，Mac连接热点后运行: ifconfig | grep 'inet ' | grep -v 127.0.0.1
  
  // API端点
  static const String authEndpoint = '/api/auth';
  static const String tasksEndpoint = '/api/tasks';
  static const String aiEndpoint = '/api/ai';
  static const String aiSimpleEndpoint = '/api/ai-simple';
  
  // JWT配置
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  
  // AI配置
  static const String aiModel = 'qwen-max';
  static const String aiProvider = 'dashscope';
  
  // 应用信息
  static const String appName = '拖延症助手';
  static const String appVersion = '1.0.0';
}
