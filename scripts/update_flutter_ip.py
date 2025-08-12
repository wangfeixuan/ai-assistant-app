#!/usr/bin/env python3
"""
自动更新Flutter应用中的IP地址脚本
当Mac的IP地址变化时，自动更新Flutter代码中的API配置
"""

import subprocess
import re
import os
import sys

def get_current_ip():
    """获取当前Mac的IP地址"""
    try:
        # 获取非localhost的IP地址
        result = subprocess.run(['ifconfig'], capture_output=True, text=True)
        output = result.stdout
        
        # 查找inet地址，排除127.0.0.1
        ip_pattern = r'inet (\d+\.\d+\.\d+\.\d+)'
        matches = re.findall(ip_pattern, output)
        
        for ip in matches:
            if ip != '127.0.0.1':
                return ip
        
        return None
    except Exception as e:
        print(f"获取IP地址失败: {e}")
        return None

def update_flutter_config(new_ip):
    """更新Flutter配置文件中的IP地址"""
    flutter_dir = "/Users/wangfeixuan/小ai/flutter_ai_assistant"
    
    # 需要更新的文件列表
    files_to_update = [
        "lib/core/config.dart",
        "lib/services/procrastination_service.dart", 
        "lib/screens/push_notification_test_screen.dart",
        "lib/features/ai_chat/providers/chat_provider.dart"
    ]
    
    updated_files = []
    
    for file_path in files_to_update:
        full_path = os.path.join(flutter_dir, file_path)
        
        if not os.path.exists(full_path):
            print(f"⚠️  文件不存在: {file_path}")
            continue
            
        try:
            # 读取文件内容
            with open(full_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 替换IP地址
            # 匹配 http://xxx.xxx.xxx.xxx:5001 格式
            ip_pattern = r'http://\d+\.\d+\.\d+\.\d+:5001'
            new_url = f'http://{new_ip}:5001'
            
            if re.search(ip_pattern, content):
                updated_content = re.sub(ip_pattern, new_url, content)
                
                # 写回文件
                with open(full_path, 'w', encoding='utf-8') as f:
                    f.write(updated_content)
                
                updated_files.append(file_path)
                print(f"✅ 已更新: {file_path}")
            else:
                print(f"ℹ️  无需更新: {file_path}")
                
        except Exception as e:
            print(f"❌ 更新失败 {file_path}: {e}")
    
    return updated_files

def main():
    print("🔍 检测当前IP地址...")
    current_ip = get_current_ip()
    
    if not current_ip:
        print("❌ 无法获取当前IP地址")
        sys.exit(1)
    
    print(f"📍 当前IP地址: {current_ip}")
    
    # 检查是否需要更新
    config_file = "/Users/wangfeixuan/小ai/flutter_ai_assistant/lib/core/config.dart"
    
    if os.path.exists(config_file):
        with open(config_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        if f'http://{current_ip}:5001' in content:
            print("✅ IP地址已是最新，无需更新")
            return
    
    print("🔄 开始更新Flutter配置...")
    updated_files = update_flutter_config(current_ip)
    
    if updated_files:
        print(f"\n🎉 成功更新 {len(updated_files)} 个文件:")
        for file in updated_files:
            print(f"   - {file}")
        print(f"\n📱 新的API地址: http://{current_ip}:5001")
        print("\n💡 提示: 请重新启动Flutter应用以应用更改")
    else:
        print("⚠️  没有文件被更新")

if __name__ == "__main__":
    main()
