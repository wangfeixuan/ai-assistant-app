# 🚀 拖延症AI助手 - 生产环境部署指南

## 📋 部署概览

将Flutter应用上架App Store需要将后端API部署到云服务器，确保用户可以从任何地方访问。

## 🛠 部署架构

```
Flutter App (iOS) → API Gateway → 云服务器 → 数据库
                                    ↓
                              AI服务(OpenAI)
```

## 💰 成本预估

### 方案一：阿里云（推荐国内用户）
- **ECS云服务器** (2核4G): ¥150/月
- **RDS PostgreSQL** (1核2G): ¥80/月  
- **域名注册**: ¥50/年
- **SSL证书**: 免费
- **总计**: 约¥230/月 + ¥50/年

### 方案二：腾讯云
- 价格类似阿里云
- 新用户首年优惠约50%

### 方案三：Vercel + Supabase（简化部署）
- **Vercel部署**: 免费（够用）
- **Supabase数据库**: 免费额度 + $25/月
- **域名**: 免费子域名或自购
- **总计**: $0-25/月

## 🔧 部署步骤

### 阶段1：准备工作
1. **购买云服务器**
   - 选择操作系统：Ubuntu 20.04 LTS
   - 配置：2核4G内存，40G硬盘
   - 开放端口：80, 443, 5432

2. **域名和SSL**
   - 注册域名（如：yourapp.com）
   - 申请免费SSL证书
   - 配置DNS解析

### 阶段2：服务器配置
```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装Python和依赖
sudo apt install python3 python3-pip python3-venv nginx postgresql -y

# 安装Node.js（用于前端构建）
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### 阶段3：数据库设置
```bash
# 配置PostgreSQL
sudo -u postgres createuser --interactive
sudo -u postgres createdb procrastination_ai
```

### 阶段4：部署后端
```bash
# 创建应用目录
sudo mkdir /var/www/procrastination-ai
cd /var/www/procrastination-ai

# 克隆代码（或上传）
git clone your-repo.git .

# 创建虚拟环境
python3 -m venv venv
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt

# 配置环境变量
cp backend/.env.example backend/.env
# 编辑.env文件，填入生产环境配置
```

### 阶段5：Nginx配置
```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 阶段6：进程管理
使用Gunicorn + Supervisor确保服务稳定运行：

```bash
# 安装Gunicorn
pip install gunicorn

# 创建启动脚本
gunicorn --bind 0.0.0.0:5000 app:app
```

## 🔐 安全配置

1. **防火墙设置**
   ```bash
   sudo ufw enable
   sudo ufw allow ssh
   sudo ufw allow 'Nginx Full'
   ```

2. **SSL证书**
   ```bash
   sudo apt install certbot python3-certbot-nginx
   sudo certbot --nginx -d your-domain.com
   ```

3. **数据库安全**
   - 修改默认密码
   - 限制访问IP
   - 定期备份

## 📱 Flutter配置更新

部署完成后，需要更新Flutter应用中的API地址：

```dart
// lib/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'https://your-domain.com/api';
  // 替换为你的实际域名
}
```

## 🧪 测试验证

1. **API测试**
   ```bash
   curl https://your-domain.com/health
   ```

2. **数据库连接测试**
3. **SSL证书验证**
4. **性能测试**

## 📊 监控和维护

1. **日志监控**
   - 设置日志轮转
   - 监控错误日志

2. **性能监控**
   - CPU、内存使用率
   - 数据库性能

3. **备份策略**
   - 数据库定期备份
   - 代码版本管理

## 💡 成本优化建议

1. **开发阶段**：使用Vercel免费额度
2. **测试阶段**：选择最低配置云服务器
3. **生产阶段**：根据用户量扩容
4. **长期运营**：考虑包年优惠

## 🚨 注意事项

1. **App Store审核**
   - 确保API稳定可访问
   - 准备隐私政策和用户协议
   - 测试所有功能正常

2. **数据合规**
   - 用户数据加密存储
   - 遵守GDPR等法规
   - 实现数据删除功能

## 📞 技术支持

如果在部署过程中遇到问题，可以：
1. 查看服务器日志
2. 检查网络连接
3. 验证配置文件
4. 联系云服务商技术支持

---

**建议**：先使用Vercel + Supabase方案进行测试部署，成本低且配置简单。等应用稳定后再考虑迁移到专用服务器。
