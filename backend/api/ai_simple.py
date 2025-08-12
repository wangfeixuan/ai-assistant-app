"""
简单的AI测试接口 - 不需要JWT认证
用于开发和测试AI任务拆分功能
"""
import dashscope
import json
import os
from flask import Blueprint, request, jsonify
from datetime import datetime

# 创建蓝图
ai_simple_bp = Blueprint('ai_simple', __name__)

# 设置API Key - 从环境变量读取
dashscope.api_key = os.getenv('DASHSCOPE_API_KEY')

# 不当内容关键词列表
INAPPROPRIATE_KEYWORDS = [
    # 犯罪相关
    '犯罪', '偷盗', '抢劫', '诈骗', '贩毒', '走私', '洗钱', '杀人', '暴力', '恐怖', '爆炸', '枪支', '毒品',
    # 自伤相关
    '自杀', '自残', '轻生', '结束生命', '不想活', '想死', '自伤', '割腕', '跳楼',
    # 不当内容
    '上床', '做爱', '性行为', '色情', '黄色', '裸体', '性交', '约炮', '一夜情',
    # 其他不当内容
    '赌博', '吸毒', '酗酒', '暴食', '厌食', '报复', '仇恨', '歧视', '霸凌'
]

def check_content_appropriateness(text):
    """检查内容是否合适"""
    text_lower = text.lower().strip()
    
    # 检查是否包含不当关键词
    for keyword in INAPPROPRIATE_KEYWORDS:
        if keyword in text_lower:
            return False, keyword
    
    # 检查是否为空或过短
    if len(text_lower) < 2:
        return False, "内容过短"
    
    return True, None

def generate_positive_guidance(inappropriate_keyword, user_input):
    """生成积极的引导建议"""
    guidance_messages = {
        '自杀': "💙 我注意到你可能遇到了困难。生活中的挫折是暂时的，每个人都值得被关爱和帮助。建议你：\n\n🤗 与信任的朋友或家人聊聊\n📞 拨打心理援助热线：400-161-9995\n🏥 寻求专业心理咨询师的帮助\n\n让我们一起制定一些积极的日常目标，比如：学习新技能、锻炼身体、培养兴趣爱好等。你想从哪个方面开始呢？",
        '自残': "💙 我关心你的身心健康。自我伤害不能解决问题，反而会带来更多痛苦。建议你：\n\n🤗 寻找健康的情绪释放方式（运动、音乐、绘画）\n📞 与专业心理咨询师交流\n💪 制定积极的自我关爱计划\n\n让我帮你规划一些有益的活动，比如：制定学习计划、健身目标、兴趣培养等。你希望从哪里开始？",
        '犯罪': "⚖️ 我不能协助任何违法活动的规划。合法合规是我们行为的基本准则。\n\n✨ 让我们把注意力转向积极正面的目标：\n📚 学习新知识和技能\n💼 职业发展和规划\n🏃‍♂️ 健康生活方式\n🎯 个人兴趣爱好\n\n请告诉我你想在哪个正面领域制定计划？",
        '上床': "😊 我是专注于学习、工作和生活管理的AI助手。\n\n🎯 让我们聚焦于更有意义的目标：\n📖 学习计划和技能提升\n💼 工作效率和职业发展\n🏃‍♂️ 健康生活和运动计划\n🎨 兴趣爱好和创意项目\n\n你希望在哪个方面制定具体的行动计划？"
    }
    
    # 根据关键词类型返回相应的引导
    for key, message in guidance_messages.items():
        if key in inappropriate_keyword:
            return message
    
    # 默认引导消息
    return f"😊 让我们把注意力转向更积极正面的目标吧！\n\n✨ 我可以帮你制定以下类型的计划：\n📚 学习和技能提升\n💼 工作和职业发展\n🏃‍♂️ 健康和运动计划\n🎨 兴趣爱好培养\n🏠 生活管理和整理\n\n请告诉我你想在哪个领域制定具体的行动计划？"

def create_task_breakdown_prompt(user_task):
    """创建带有内容审核的任务拆分提示词"""
    return f"""你是一个专业的任务管理助手，你的使命是帮助用户制定积极正面的生活、学习和工作计划。

**禁忌内容检查**：
如果用户输入的任务包含以下任何不当内容，请直接返回勝诫引导，不要进行任务拆分：
- 犯罪、暴力、违法行为
- 自伤、自杀、轻生等内容
- 色情、不当性内容
- 赌博、吸毒、酗酒等恶习
- 仇恨、歧视、霸凌等负面情绪

用户任务：{user_task}

**请先判断任务内容是否合适**：

1. 如果任务内容不合适，请返回：
```json
{{
  "content_inappropriate": true,
  "guidance": "温暖的勝诫和引导内容，帮助用户转向积极正面的目标"
}}
```

2. 如果任务内容合适，请进行任务拆分，返回：
```json
{{
  "content_inappropriate": false,
  "subtasks": [
    {{
      "title": "简短清晰的步骤名称",
      "priority": "high",
      "estimated_time": "15分钟"
    }}
  ]
}}
```

要求：
- 3-5个具体步骤
- 每步骤都可立即行动
- 优先级：high/medium/low
- 时间：15分钟/30分钟/1小时

请严格按照JSON格式返回，不要包含其他文字。"""

@ai_simple_bp.route('/breakdown', methods=['POST'])
def simple_breakdown_task():
    """简单的AI任务拆分接口 - 无需认证"""
    try:
        data = request.get_json()
        user_task = data.get('task', '').strip()
        
        if not user_task:
            return jsonify({
                'success': False,
                'error': '任务内容不能为空'
            })
        
        # 不再使用简单的关键词过滤，改为AI模型智能判断
        
        if len(user_task) > 500:
            return jsonify({
                'success': False,
                'error': '任务描述过长，请控制在500字以内'
            }), 400
        
        print(f"🤖 AI拆分任务: {user_task}")
        
        # 检查API Key是否配置
        if not dashscope.api_key:
            return jsonify({
                'success': False,
                'error': '未配置DASHSCOPE_API_KEY，请检查环境变量'
            }), 500
        
        # 调用通义千问API - 优化参数提升速度
        response = dashscope.Generation.call(
            model='qwen-turbo',  # 使用更快的模型
            prompt=create_task_breakdown_prompt(user_task),
            temperature=0.1,     # 降低随机性，提升速度
            max_tokens=800,      # 减少输出长度
            top_p=0.9           # 优化参数
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
                
                # 检查是否为内容不合适的情况
                if result.get('content_inappropriate', False):
                    # AI模型判断内容不合适，返回引导信息
                    return jsonify({
                        'success': False,
                        'error': '请输入积极正面的任务内容',
                        'guidance': result.get('guidance', '请输入合适的任务内容'),
                        'content_filtered': True
                    })
                
                # 验证返回数据结构（简化版）
                if 'subtasks' not in result or not isinstance(result['subtasks'], list):
                    raise ValueError("AI返回数据结构不完整")
                
                # 为每个子任务添加ID和默认值
                for i, subtask in enumerate(result['subtasks']):
                    subtask['id'] = i + 1
                    subtask.setdefault('priority', 'medium')
                    subtask.setdefault('estimated_time', '30分钟')
                    subtask.setdefault('category', '其他')
                    subtask.setdefault('description', subtask.get('title', ''))
                
                # 添加简化的默认分析和建议
                result.setdefault('analysis', '任务已拆分为具体步骤，可逐步执行')
                result.setdefault('tips', ['一次专注一个步骤', '完成后及时打勾', '遇到困难可继续拆分'])
                
                print(f"✅ 任务拆分成功，生成{len(result['subtasks'])}个子任务")
                
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

@ai_simple_bp.route('/chat', methods=['POST'])
def simple_chat():
    """简单的AI聊天接口"""
    try:
        data = request.get_json()
        user_message = data.get('message', '').strip()
        
        if not user_message:
            return jsonify({
                'success': False,
                'error': '消息内容不能为空'
            })
        
        # 不再使用简单的关键词过滤，改为AI模型智能判断和处理
        
        # 检查API Key是否配置
        if not dashscope.api_key:
            return jsonify({
                'success': False,
                'error': '未配置DASHSCOPE_API_KEY，使用本地回复',
                'response': f'你好！我是你的AI助手。关于"{user_message}"，我建议你可以：\n\n1. 🍅 使用番茄钟专注工作\n2. 📝 记录待办事项\n3. 🎯 设定明确目标\n\n有什么具体问题可以继续问我！'
            })
        
        # 创建带有内容审核的聊天提示词
        chat_prompt = f"""你是一个专业的拖延症治疗和时间管理助手，名字叫"小AI"。你的使命是帮助用户制定积极正面的生活目标。

**禁忌内容检查**：
如果用户的消息包含以下任何不当内容，请提供温暖的关怀和积极引导：
- 犯罪、暴力、违法行为
- 自伤、自杀、轻生等内容
- 色情、不当性内容
- 赌博、吸毒、酗酒等恶习
- 仇恨、歧视、霸凌等负面情绪

用户消息：{user_message}

请用温暖、鼓励的语气回复。如果内容不合适，请提供关怀和积极引导。如果内容合适，请提供实用的建议，包含具体可行的步骤。可以推荐使用番茄钟技术或任务分解方法。"""
        
        # 调用通义千问API
        response = dashscope.Generation.call(
            model='qwen-turbo',
            prompt=chat_prompt,
            max_tokens=500,
            temperature=0.7
        )
        
        if response.status_code == 200:
            ai_response = response.output.text.strip()
            return jsonify({
                'success': True,
                'response': ai_response,
                'timestamp': datetime.now().isoformat()
            })
        else:
            # API调用失败时的备用回复
            fallback_response = f'关于"{user_message}"，我建议你：\n\n1. 🍅 使用番茄钟专注25分钟\n2. 📝 把任务分解成小步骤\n3. 🎯 设定明确的完成目标\n4. ⏰ 合理安排休息时间\n\n记住，克服拖延需要坚持，你一定可以做到的！💪'
            
            return jsonify({
                'success': True,
                'response': fallback_response,
                'note': 'API调用失败，使用备用回复'
            })
            
    except Exception as e:
        print(f'AI聊天API异常: {e}')
        # 异常时的备用回复
        fallback_response = f'我明白了！作为你的专注助手，我建议你可以：\n\n1. 🍅 使用番茄钟专注工作\n2. 📝 记录待办事项\n3. 🎯 设定明确目标\n4. ⏰ 合理安排休息\n\n有什么具体问题可以继续问我哦！'
        
        return jsonify({
            'success': True,
            'response': fallback_response,
            'note': f'系统异常，使用备用回复: {str(e)}'
        })

@ai_simple_bp.route('/test', methods=['GET'])
def test_connection():
    """测试AI连接状态"""
    try:
        # 检查API Key是否配置
        if not dashscope.api_key:
            return jsonify({
                'success': False,
                'error': '未配置DASHSCOPE_API_KEY环境变量',
                'status': 'api_key_missing'
            })
        
        # 测试简单的API调用
        response = dashscope.Generation.call(
            model='qwen-turbo',
            prompt='你好',
            max_tokens=10
        )
        
        if response.status_code == 200:
            return jsonify({
                'success': True,
                'message': 'AI连接正常',
                'status': 'connected',
                'model': 'qwen-turbo',
                'test_response': response.output.text.strip()
            })
        else:
            return jsonify({
                'success': False,
                'error': f'API调用失败: {response.message}',
                'status': 'api_error'
            })
            
    except Exception as e:
        return jsonify({
            'success': False,
            'error': f'连接测试失败: {str(e)}',
            'status': 'connection_error'
        }), 500
