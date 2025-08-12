"""
推送通知服务
支持iOS APNs和Android FCM推送
"""

import json
import requests
from datetime import datetime
from typing import List, Dict, Optional
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from models.push_token import UserPushToken
from models import db
from config import Config

class NotificationService:
    """推送通知服务类"""
    
    def __init__(self):
        # 使用配置文件中的Firebase配置
        self.fcm_server_key = Config.FCM_SERVER_KEY
        self.fcm_url = Config.FCM_URL
        
    def send_evening_reminder(self, user_id: int, task_count: int) -> bool:
        """
        发送晚上提醒通知
        
        Args:
            user_id: 用户ID
            task_count: 未完成任务数量
            
        Returns:
            bool: 发送是否成功
        """
        try:
            user = User.query.get(user_id)
            if not user:
                print(f"用户 {user_id} 不存在")
                return False
            
            # 构建通知内容
            title = "📝 任务提醒"
            body = f"你还有{task_count}个任务未完成，记得及时处理哦！"
            
            # 获取用户的推送token（需要在用户表中添加字段）
            push_tokens = self._get_user_push_tokens(user_id)
            
            success_count = 0
            for token_info in push_tokens:
                if token_info['platform'] == 'ios':
                    success = self._send_apns_notification(token_info['token'], title, body)
                elif token_info['platform'] == 'android':
                    success = self._send_fcm_notification(token_info['token'], title, body)
                else:
                    continue
                    
                if success:
                    success_count += 1
            
            print(f"用户 {user_id} 推送通知发送完成: {success_count}/{len(push_tokens)} 成功")
            return success_count > 0
            
        except Exception as e:
            print(f"发送晚上提醒失败: {str(e)}")
            return False
    
    def _get_user_push_tokens(self, user_id: int) -> List[Dict]:
        """
        获取用户的推送token列表
        """
        try:
            push_tokens = UserPushToken.query.filter_by(
                user_id=user_id, 
                is_active=True
            ).all()
            return [{
                'token': token.token, 
                'platform': token.platform.value
            } for token in push_tokens]
        except Exception as e:
            print(f"获取用户推送token失败: {str(e)}")
            return []
    
    def _send_fcm_notification(self, token: str, title: str, body: str) -> bool:
        """
        发送FCM推送通知（Android）
        
        Args:
            token: FCM设备token
            title: 通知标题
            body: 通知内容
            
        Returns:
            bool: 发送是否成功
        """
        try:
            headers = {
                'Authorization': f'key={self.fcm_server_key}',
                'Content-Type': 'application/json',
            }
            
            payload = {
                'to': token,
                'notification': {
                    'title': title,
                    'body': body,
                    'icon': 'ic_notification',  # 应用图标
                    'sound': 'default',
                    'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                },
                'data': {
                    'type': 'evening_reminder',
                    'timestamp': datetime.now().isoformat(),
                    'route': '/todo',  # 点击通知后跳转的页面
                }
            }
            
            response = requests.post(
                self.fcm_url,
                headers=headers,
                data=json.dumps(payload),
                timeout=10
            )
            
            if response.status_code == 200:
                result = response.json()
                if result.get('success', 0) > 0:
                    print(f"FCM推送发送成功: {token[:20]}...")
                    return True
                else:
                    print(f"FCM推送发送失败: {result}")
                    return False
            else:
                print(f"FCM请求失败: {response.status_code} - {response.text}")
                return False
                
        except Exception as e:
            print(f"FCM推送异常: {str(e)}")
            return False
    
    def send_fcm_notification(self, tokens: List[str], title: str, body: str, 
                            notification_type: str = 'default', data: Dict = None) -> Dict:
        """发送FCM推送通知"""
        if not tokens:
            return {'success': False, 'error': 'No tokens provided'}
            
        if not Config.is_firebase_configured():
            return {'success': False, 'error': 'Firebase not configured properly'}
            
        headers = {
            'Authorization': f'key={self.fcm_server_key}',
            'Content-Type': 'application/json'
        }
        
        # 获取通知模板
        template = Config.get_notification_template(notification_type)
        
        payload = {
            'registration_ids': tokens,
            'notification': {
                'title': title,
                'body': body,
                'icon': template.get('icon', 'ic_notification'),
                'sound': template.get('sound', 'default'),
                'click_action': template.get('click_action', 'FLUTTER_NOTIFICATION_CLICK')
            },
            'data': {
                **(data or {}),
                'route': template.get('route', '/'),
                'notification_type': notification_type,
                'timestamp': datetime.utcnow().isoformat()
            }
        }
        
        try:
            response = requests.post(self.fcm_url, headers=headers, json=payload)
            result = {
                'success': response.status_code == 200,
                'status_code': response.status_code
            }
            
            if response.status_code == 200:
                result['response'] = response.json()
                # 记录成功发送的统计
                result['sent_count'] = len(tokens)
            else:
                result['error'] = response.text
                
            return result
        except Exception as e:
            return {'success': False, 'error': str(e)}
    
    def _send_apns_notification(self, token: str, title: str, body: str) -> bool:
        """
        发送APNs推送通知（iOS）
        注意：需要配置APNs证书和密钥
        
        Args:
            token: APNs设备token
            title: 通知标题
            body: 通知内容
            
        Returns:
            bool: 发送是否成功
        """
        try:
            # APNs推送需要使用JWT token或证书认证
            # 这里提供基础框架，实际使用需要配置证书
            
            # 使用第三方库如pyjwt生成JWT token
            # 或使用证书进行HTTP/2连接
            
            print(f"APNs推送模拟发送: {title} - {body}")
            # 实际实现需要：
            # 1. 生成JWT token或配置证书
            # 2. 建立HTTP/2连接到APNs服务器
            # 3. 发送推送请求
            
            return True  # 模拟成功
            
        except Exception as e:
            print(f"APNs推送异常: {str(e)}")
            return False
    
    def send_procrastination_reminder(self, user_id: int, task_title: str) -> Dict:
        """发送拖延提醒"""
        # 获取用户的推送token
        tokens = self.get_user_active_tokens(user_id)
        if not tokens:
            return {'success': False, 'error': 'No active tokens found'}
            
        template = Config.get_notification_template('procrastination_reminder')
        title = template['title']
        body = template['body_template'].format(task_title=task_title)
        
        # 准备数据
        data = {
            'type': 'procrastination_reminder',
            'task_title': task_title
        }
        
        return self.send_fcm_notification(tokens, title, body, 'procrastination_reminder', data)
    
    def get_user_active_tokens(self, user_id: int) -> List[str]:
        """获取用户的活跃推送token"""
        try:
            push_tokens = UserPushToken.query.filter_by(
                user_id=user_id, 
                is_active=True
            ).all()
            return [token.token for token in push_tokens]
            
        except Exception as e:
            print(f"获取用户推送token失败: {str(e)}")
            return []

# 全局通知服务实例
notification_service = NotificationService()
