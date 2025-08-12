"""
AI助手相关API接口
"""
import dashscope
import json
import os
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity

# 创建蓝图
ai_bp = Blueprint('ai', __name__)

# 设置API Key - 从环境变量读取
dashscope.api_key = os.getenv('DASHSCOPE_API_KEY')

# 检查API Key是否配置
if not dashscope.api_key:
    print("⚠️  警告: 未配置DASHSCOPE_API_KEY环境变量")

def create_task_breakdown_prompt(user_task):
    """创建任务拆分的提示词"""
    return f"""
你是一个专业的任务管理助手，请将用户输入的任务智能拆分成具体可执行的子任务。

用户任务：{user_task}

请严格按照以下JSON格式返回，不要包含任何其他文字：
{{
  "analysis": "简要分析这个任务的特点和执行要点",
  "subtasks": [
    {{
      "title": "子任务标题",
      "description": "具体执行步骤和要求",
      "priority": "high",
      "estimated_time": "预估完成时间",
      "category": "任务类别"
    }}
  ],
  "tips": ["执行建议1", "执行建议2", "执行建议3"]
}}

拆分要求：
1. 子任务要具体可执行，避免抽象描述
2. 按重要性和逻辑顺序排列
3. 每个子任务都要有明确的完成标准
4. 优先级分为：high（紧急重要）、medium（重要不紧急）、low（不紧急不重要）
5. 预估时间如：15分钟、30分钟、1小时、2小时、半天、1天等
6. 类别如：学习、工作、生活、健康、社交等
7. 子任务数量控制在3-8个之间
8. 提供3-5个实用的执行建议
"""

@ai_bp.route('/breakdown-task', methods=['POST'])
@jwt_required()
def breakdown_task():
    """AI任务拆分接口"""
    try:
        # 获取当前用户ID
        current_user_id = get_jwt_identity()
        
        # 获取请求数据
        data = request.get_json()
        user_task = data.get('task', '').strip()
        
        if not user_task:
            return jsonify({
                'success': False,
                'error': '任务内容不能为空'
            }), 400
        
        if len(user_task) > 500:
            return jsonify({
                'success': False,
                'error': '任务描述过长，请控制在500字以内'
            }), 400
        
        print(f"🤖 用户{current_user_id}请求AI拆分任务: {user_task}")
        
        # 调用通义千问API
        response = dashscope.Generation.call(
            model='qwen-max',
            prompt=create_task_breakdown_prompt(user_task),
            temperature=0.3,  # 降低随机性，保证结果稳定
            max_tokens=2000,
            top_p=0.8
        )
        
        print(f"📡 API响应状态: {response.status_code}")
        
        if response.status_code == 200:
            ai_response = response.output.text.strip()
            print(f"🎯 AI原始响应: {ai_response}")
            
            # 尝试解析AI返回的JSON
            try:
                # 清理可能的markdown代码块标记
                if ai_response.startswith('```json'):
                    ai_response = ai_response.replace('```json', '').replace('```', '').strip()
                elif ai_response.startswith('```'):
                    ai_response = ai_response.replace('```', '').strip()
                
                result = json.loads(ai_response)
                
                # 验证返回数据结构
                if not all(key in result for key in ['analysis', 'subtasks', 'tips']):
                    raise ValueError("AI返回数据结构不完整")
                
                # 为每个子任务添加ID
                for i, subtask in enumerate(result['subtasks']):
                    subtask['id'] = i + 1
                    # 确保必要字段存在
                    subtask.setdefault('priority', 'medium')
                    subtask.setdefault('estimated_time', '1小时')
                    subtask.setdefault('category', '其他')
                
                print(f"✅ 任务拆分成功，生成{len(result['subtasks'])}个子任务")
                
                from datetime import datetime
                
                return jsonify({
                    'success': True,
                    'data': {
                        'original_task': user_task,
                        'user_id': current_user_id,
                        'breakdown': result,
                        'created_at': datetime.now().isoformat()
                    }
                })
                
            except json.JSONDecodeError as e:
                print(f"❌ JSON解析错误: {e}")
                print(f"原始响应: {ai_response}")
                return jsonify({
                    'success': False,
                    'error': 'AI返回格式错误，请重试',
                    'debug_info': ai_response[:200] if ai_response else 'Empty response'
                }), 500
                
            except ValueError as e:
                print(f"❌ 数据验证错误: {e}")
                return jsonify({
                    'success': False,
                    'error': 'AI返回数据不完整，请重试'
                }), 500
                
        else:
            error_msg = f"AI服务调用失败，状态码: {response.status_code}"
            if hasattr(response, 'message'):
                error_msg += f", 错误信息: {response.message}"
            
            print(f"❌ {error_msg}")
            return jsonify({
                'success': False,
                'error': 'AI服务暂时不可用，请稍后重试'
            }), 500
            
    except Exception as e:
        print(f"❌ 服务器错误: {str(e)}")
        return jsonify({
            'success': False,
            'error': f'服务器内部错误: {str(e)}'
        }), 500

@ai_bp.route('/test-connection', methods=['GET'])
def test_ai_connection():
    """测试AI连接状态"""
    try:
        # 简单的测试调用
        response = dashscope.Generation.call(
            model='qwen-max',
            prompt="请回复：连接测试成功",
            max_tokens=50
        )
        
        if response.status_code == 200:
            return jsonify({
                'success': True,
                'message': 'AI服务连接正常',
                'model': 'qwen-max',
                'response': response.output.text
            })
        else:
            return jsonify({
                'success': False,
                'error': f'AI服务连接失败，状态码: {response.status_code}'
            }), 500
            
    except Exception as e:
        return jsonify({
            'success': False,
            'error': f'连接测试失败: {str(e)}'
        }), 500

@ai_bp.route('/test-breakdown', methods=['POST'])
def test_task_breakdown():
    """测试AI任务拆分功能（不需要JWT认证）"""
    try:
        data = request.get_json()
        user_task = data.get('task', '').strip()
        
        if not user_task:
            return jsonify({
                'success': False,
                'error': '任务内容不能为空'
            }), 400
        
        print(f"🤖 测试AI拆分任务: {user_task}")
        
        # 调用通义千问API
        response = dashscope.Generation.call(
            model='qwen-max',
            prompt=create_task_breakdown_prompt(user_task),
            temperature=0.3,
            max_tokens=2000,
            top_p=0.8
        )
        
        print(f"📡 API响应状态: {response.status_code}")
        
        if response.status_code == 200:
            ai_response = response.output.text.strip()
            print(f"🎯 AI原始响应: {ai_response}")
            
            try:
                # 清理可能的markdown代码块标记
                if ai_response.startswith('```json'):
                    ai_response = ai_response.replace('```json', '').replace('```', '').strip()
                elif ai_response.startswith('```'):
                    ai_response = ai_response.replace('```', '').strip()
                
                result = json.loads(ai_response)
                
                # 验证返回数据结构
                if not all(key in result for key in ['analysis', 'subtasks', 'tips']):
                    raise ValueError("AI返回数据结构不完整")
                
                # 为每个子任务添加ID
                for i, subtask in enumerate(result['subtasks']):
                    subtask['id'] = i + 1
                    subtask.setdefault('priority', 'medium')
                    subtask.setdefault('estimated_time', '1小时')
                    subtask.setdefault('category', '其他')
                
                from datetime import datetime
                
                return jsonify({
                    'success': True,
                    'data': {
                        'original_task': user_task,
                        'breakdown': result,
                        'created_at': datetime.now().isoformat()
                    }
                })
                
            except json.JSONDecodeError as e:
                print(f"❌ JSON解析错误: {e}")
                return jsonify({
                    'success': False,
                    'error': 'AI返回格式错误，请重试',
                    'debug_info': ai_response[:200] if ai_response else 'Empty response'
                }), 500
                
        else:
            error_msg = f"AI服务调用失败，状态码: {response.status_code}"
            if hasattr(response, 'message'):
                error_msg += f", 错误信息: {response.message}"
            
            print(f"❌ {error_msg}")
            return jsonify({
                'success': False,
                'error': 'AI服务暂时不可用，请稍后重试'
            }), 500
            
    except Exception as e:
        print(f"❌ 服务器错误: {str(e)}")
        return jsonify({
            'success': False,
            'error': f'服务器内部错误: {str(e)}'
        }), 500
