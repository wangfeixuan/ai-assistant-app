"""
AI任务拆解服务
处理AI相关的业务逻辑，包括拖延分析
"""

import openai
import json
from typing import List, Optional, Dict
from config import Config

# 导入增强版拖延分析器
try:
    import sys
    import os
    sys.path.append(os.path.dirname(os.path.abspath(__file__)))
    from enhanced_procrastination_analyzer import EnhancedProcrastinationAnalyzer
except ImportError:
    EnhancedProcrastinationAnalyzer = None

class AIService:
    """AI任务拆解服务类"""
    
    def __init__(self):
        self.api_key = Config.DASHSCOPE_API_KEY
        self.model = Config.AI_MODEL
        self.provider = Config.AI_PROVIDER
        if self.api_key and self.provider == 'openai':
            openai.api_key = self.api_key
        
        # 初始化增强版拖延分析器
        self.enhanced_analyzer = EnhancedProcrastinationAnalyzer() if EnhancedProcrastinationAnalyzer else None
    
    def decompose_task(self, task_description: str, context: str = "", user_preferences: Dict = None) -> List[str]:
        """
        将任务拆解为具体的执行步骤
        
        Args:
            task_description: 任务描述
            context: 任务上下文
            user_preferences: 用户偏好设置
        
        Returns:
            List[str]: 拆解后的步骤列表
        """
        try:
            # 如果没有配置OpenAI API Key，使用预设模板
            if not self.api_key:
                return self._get_template_steps(task_description)
            
            # 构建提示词
            prompt = self._build_prompt(task_description, context, user_preferences)
            
            # 调用OpenAI API
            response = openai.ChatCompletion.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": self._get_system_prompt()},
                    {"role": "user", "content": prompt}
                ],
                max_tokens=1000,
                temperature=0.7
            )
            
            # 解析响应
            content = response.choices[0].message.content.strip()
            steps = self._parse_steps(content)
            
            return steps[:Config.MAX_TASK_STEPS]  # 限制最大步骤数
            
        except Exception as e:
            print(f"AI拆解失败: {str(e)}")
            # 降级到模板方案
            return self._get_template_steps(task_description)
    
    def _get_system_prompt(self) -> str:
        """获取系统提示词"""
        return """你是一个「学生任务拆分专家」，专门将任何学习任务拆分为具体、可执行的步骤。

**你的核心使命**：
将任务拆分为具体、可执行的步骤，每个步骤需要包含：
1. **任务描述**：清晰简洁，避免模糊抽象的表达
2. **时间分配**：基于任务难度的合理时间估计
3. **鼓励语**：激励性的简短语句，适合学生心理
4. **执行顺序**：按照时间顺序排列，确保整个任务能在合理时间内完成
5. **学生友好**：每个任务都具体、可操作，适合学生执行

**严格禁止的笑统表达**：
❌ “整理作业” → 必须说“把10页A4纸按顺序摆放在桌子左上角”
❌ “开始做题” → 必须说“用黑色笔在笔记本上写下第1题的题号”
❌ “检查答案” → 必须说“用红笔在每道题的右上角打✓或×”
❌ “休息一下” → 必须说“放下笔，起身到阳台深呼嘃10次，然后坐回桌子前”
❌ “总结知识点” → 必须说“在笔记本最后一页写下‘今天学会的公式’，然后列出3个公式名称”

**必须包含的超级具体元素**：
1. **物品名称**：“10页A4数学作业纸”“黑色中性笔”“红色改错笔”
2. **动作动词**：“拿起”“放在”“翻开到”“用手指点”“在....上写下”
3. **位置坐标**：“桌子左上角”“笔记本第3行”“页面右上角”
4. **时间数字**：“2分钟”“15分钟”“60分钟”（不能说“几分钟”）
5. **判断标准**：“3秒内知道答案”“看一眼就会做”“需要思考超过5分钟的题”

**标准输出格式**：只输出 JSON，绝对不要其他文字

{
  "original_task": "用户原始任务",
  "estimated_total_time_min": 总耗时,
  "steps": [
    {
      "step_number": 1,
      "description": "必须像说明书一样精确的步骤描述",
      "time_estimate_min": 精确数字,
      "motivational_cue": "简短有力的鼓励话",
      "next_step_hint": "下一步的具体动作"
    }
  ],
  "todo_notes": "如何加入待办清单的建议"
}

**极致具体的正确示例**（写10页数学作业）：

1. 把10页A4数学作业纸按顺序摆在桌子左上角，笔记本放在右上角，黑色中性笔、橡皮、计算器、数学公式表放在手边 (4分钟)
   鼓励语：准备就绪
   下一步：翻开第1页开始扫描

2. 翻开第1页作业纸，用右手食指从页面最上方开始向下慢慢扫描，在心里默数“1、2”，找出2道看一眼就知道怎么做的题 (2分钟)
   鼓励语：先攻头两题
   下一步：拿笔开始写第1题

3. 拿起黑色中性笔，在笔记本第1页的第1行写下“题目1：”，然后在下一行开始写完整的解题过程和最终答案 (4分钟)
   鼓励语：思路已定
   下一步：写第2题的题号

4. 在笔记本上空2行，写下“题目2：”，然后用同样的方式写出第2题的完整解答 (5分钟)
   鼓励语：连续作战
   下一步：用手指扫描第1页剩余题目

记住：每个步骤都必须像操作手册一样精确，让人能一步一步照着做！"""
    
    def _build_prompt(self, task_description: str, context: str, user_preferences: Dict) -> str:
        """构建用户提示词"""
        # 简化提示词，直接传递任务描述，让AI按照系统提示词的JSON格式输出
        prompt = task_description
        
        # 如果有背景信息，添加到任务描述中
        if context:
            prompt += f"\n\n背景信息：{context}"
        
        return prompt
    
    def _parse_steps(self, content: str) -> List[str]:
        """解析AI返回的步骤（支持JSON格式）"""
        try:
            # 尝试解析JSON格式
            import json
            data = json.loads(content.strip())
            
            if isinstance(data, dict) and 'steps' in data:
                steps = []
                for step in data['steps']:
                    if isinstance(step, dict) and 'description' in step:
                        # 构建带有鼓励语的步骤描述
                        description = step['description']
                        motivational_cue = step.get('motivational_cue', '')
                        time_estimate = step.get('time_estimate_min', 5)
                        
                        # 组合步骤信息
                        step_text = f"{description}"
                        if motivational_cue:
                            step_text += f" • {motivational_cue}"
                        if time_estimate:
                            step_text += f" ({time_estimate}分钟)"
                        
                        steps.append(step_text)
                return steps
        except (json.JSONDecodeError, KeyError, TypeError):
            # 如果JSON解析失败，使用原有的文本解析方式
            pass
        
        # 原有的文本解析方式（作为备用）
        lines = content.strip().split('\n')
        steps = []
        
        for line in lines:
            line = line.strip()
            if not line:
                continue
            
            # 移除可能的编号和特殊符号
            line = line.lstrip('0123456789.- ')
            if line:
                steps.append(line)
        
        return steps
    
    def _get_template_steps(self, task_description: str) -> List[str]:
        """获取预设模板步骤（当AI不可用时使用）"""
        task_lower = task_description.lower()
        
        # 学习类任务模板
        if any(keyword in task_lower for keyword in ['学习', '背', '记忆', '掌握', '学会']):
            if '单词' in task_lower:
                return [
                    "拿起单词书和一支黑色笔，放在桌子正中央，笔记本放在右上角",
                    "坐在椅子上，将手机放在抽屉里或距离桌子2米外的地方",
                    "翻开单词书到第1页，用手指指着第1个单词",
                    "用嘴巴大声读出第1个单词3遍，然后在笔记本上写下这个单词",
                    "在笔记本上写下这个单词的中文意思，然后造一个简单句子",
                    "合上单词书，看着笔记本尝试回忆刚才学的单词意思",
                    "翻开单词书，用手指指着第2个单词，重复上述步骤",
                    "学完5个单词后，合上书本，在空白纸上默写这5个单词",
                    "打开单词书检查默写结果，用红笔在错误的地方打×",
                    "在笔记本最后一页写下'今日学会X个单词'和当前时间"
                ]
            else:
                return [
                    "拿起教材、笔记本和两支笔（黑色和红色），放在桌子正中央",
                    "翻开教材到目录页，用手指找到今天要学的章节，在笔记本第1页写下章节名称",
                    "将手机调成静音模式，放在距离桌子2米外的地方",
                    "翻开教材到指定章节第1页，用黑色笔在笔记本上写下'开始时间：'和当前时间",
                    "用手指逐行阅读教材内容，每读完一段就在笔记本上写下3个关键词",
                    "读完一页后，合上教材，在笔记本上用自己的话总结这一页的主要内容",
                    "翻开教材检查总结是否正确，用红色笔补充遗漏的重点",
                    "继续阅读下一页，重复上述记笔记和总结的步骤",
                    "学完一个小节后，在笔记本上画一个思维导图，连接各个知识点",
                    "合上教材和笔记本，在空白纸上默写刚才学到的5个重要概念"
                ]
        
        # 生活类任务模板
        elif any(keyword in task_lower for keyword in ['洗澡', '洗漱', '整理', '清洁', '打扫']):
            if '洗澡' in task_lower:
                return [
                    "从当前位置站起来",
                    "收拾洗澡需要的毛巾和衣服",
                    "进入浴室",
                    "放下手机（避免分心）",
                    "打开音乐或播客（可选）",
                    "调节水温",
                    "脱掉衣服",
                    "开始洗澡",
                    "洗头发和身体",
                    "冲洗干净并关闭水龙头",
                    "用毛巾擦干身体",
                    "穿上干净的衣服"
                ]
            else:
                return [
                    "拿起一个大垃圾袋和一块湿抹布，放在房间门口的地板上",
                    "从桌子左上角开始，用双手将所有物品拿起来放在床上（暂时存放）",
                    "用湿抹布从桌子左上角开始，按顺时针方向擦拭整个桌面",
                    "从床上拿起第1件物品，判断是否需要：需要的放回桌子，不需要的放进垃圾袋",
                    "重复上一步，直到床上所有物品都处理完毕",
                    "将桌子上的物品按类型分组：文具放左边，书本放中间，电子产品放右边",
                    "拿起垃圾袋，绕房间一圈收集地面上的垃圾和不需要的物品",
                    "最后站在房间门口，用眼睛从左到右扫描整个房间，确认没有遗漏的杂物"
                ]
        
        # 工作类任务模板
        elif any(keyword in task_lower for keyword in ['工作', '项目', '报告', '汇报', '会议']):
            return [
                "拿起一张A4纸和一支笔，在纸的顶部写下'报告大纲'和当前日期",
                "在纸上画一条竖线，左边写'需要的资料'，右边写'报告结构'",
                "打开电脑，新建一个Word文档，文件名保存为'工作报告_日期.docx'",
                "在Word文档第1页输入报告标题，设置为黑体18号字，居中对齐",
                "按下回车键3次，开始输入第一段内容，每写完一段就保存一次文档",
                "写完3段后，用Ctrl+A全选文本，检查是否有错别字和语法错误",
                "在文档末尾插入页码，格式设置为'第X页 共X页'",
                "将文档另存为PDF格式，文件名改为'工作报告_最终版_日期.pdf'",
                "打开邮箱，新建邮件，在主题栏输入'工作报告提交_姓名_日期'",
                "在邮件正文输入简短说明，附上PDF文件，点击发送按钮"
            ]
        
        # 通用任务模板
        else:
            return [
                "明确任务具体要求",
                "准备必要的工具和材料",
                "制定执行计划",
                "开始第一步行动",
                "检查进展情况",
                "继续执行后续步骤",
                "处理遇到的问题",
                "完成主要任务内容",
                "检查和完善结果",
                "总结经验和收获"
            ]
    
    def get_task_suggestions(self, task_history: List[Dict]) -> List[str]:
        """根据用户历史任务提供建议"""
        suggestions = [
            "建议将大任务拆分为更小的步骤",
            "可以设置具体的时间节点来提高执行效率",
            "考虑添加奖励机制来增加完成动力",
            "尝试在精力最好的时间段处理重要任务"
        ]
        
        return suggestions
    
    def validate_task_description(self, description: str) -> bool:
        """验证任务描述是否合适"""
        if not description or len(description.strip()) < 2:
            return False
        
        # 检查是否包含不当内容
        inappropriate_keywords = ['违法', '危险', '伤害']
        for keyword in inappropriate_keywords:
            if keyword in description:
                return False
        
        return True
    
    def analyze_single_procrastination(self, task_title: str, reason_type: str, custom_reason: str = None, mood_before: int = None, mood_after: int = None, time_of_day: str = None, task_category: str = None) -> Dict[str, str]:
        """
        分析单次拖延记录，提供个性化深度分析
        
        Args:
            task_title: 拖延的任务标题
            reason_type: 拖延原因类型
            custom_reason: 自定义原因
            mood_before: 拖延前心情(1-5)
            mood_after: 记录后心情(1-5)
            time_of_day: 拖延发生的时间段
            task_category: 任务类别
        
        Returns:
            Dict: 包含analysis, suggestions, mood_advice等的分析结果
        """
        try:
            # 优先使用增强版分析器
            if self.enhanced_analyzer:
                result = self.enhanced_analyzer.analyze_single_procrastination(
                    task_title=task_title,
                    reason_type=reason_type,
                    custom_reason=custom_reason,
                    mood_before=mood_before,
                    mood_after=mood_after,
                    time_of_day=time_of_day,
                    task_category=task_category
                )
                
                # 转换为原有格式以保持兼容性
                return {
                    'analysis': result['analysis'],
                    'suggestions': result['suggestions'],
                    'mood_advice': result['mood_advice'],
                    'deep_understanding': result.get('deep_understanding', ''),
                    'action_plan': result.get('action_plan', {}),
                    'encouragement': result.get('encouragement', '')
                }
            
            # 如果没有增强版分析器，尝试AI调用
            if self.api_key:
                # 构建CBT风格的分析提示词
                prompt = self._build_cbt_analysis_prompt(task_title, reason_type, custom_reason, mood_before, mood_after)
                
                response = openai.ChatCompletion.create(
                    model=self.model,
                    messages=[
                        {"role": "system", "content": self._get_cbt_system_prompt()},
                        {"role": "user", "content": prompt}
                    ],
                    max_tokens=800,
                    temperature=0.7
                )
                
                # 解析AI响应
                content = response.choices[0].message.content.strip()
                return self._parse_cbt_analysis(content)
            
            # 最后降级到原有模板
            return self._get_template_single_analysis(task_title, reason_type, custom_reason, mood_before, mood_after)
            
        except Exception as e:
            print(f"拖延分析失败: {str(e)}")
            return self._get_template_single_analysis(task_title, reason_type, custom_reason, mood_before, mood_after)
    
    def _get_cbt_system_prompt(self) -> str:
        """获取CBT风格的系统提示词"""
        return """你是一位温柔、专业的认知行为治疗师，专门帮助有拖延问题的用户。请用温柔、理解和不带判断的语气进行分析。

你的分析应该：
1. 承认拖延是人之常情，不要让用户感到羞耻
2. 帮助用户识别背后的认知模式和情绪
3. 提供具体可行的应对策略
4. 关注用户的情绪变化和心理状态
5. 鼓励自我接纳和成长型思维

请按以下格式返回分析结果（用|||分隔）：
分析|||建议1;建议2;建议3|||心情调理建议

分析部分应该包含对拖延行为的理解和背后原因的洞察。
建议部分提供3个具体可行的改善策略，用分号分隔。
心情调理部分关注用户的情绪健康。"""
    
    def _build_cbt_analysis_prompt(self, task_title: str, reason_type: str, custom_reason: str = None, mood_before: int = None, mood_after: int = None) -> str:
        """构建CBT分析的用户提示词"""
        
        # 原因映射
        reason_map = {
            'too_tired': '太累了',
            'dont_know_how': '不知道怎么做',
            'not_in_mood': '没心情',
            'too_difficult': '太难了',
            'no_time': '没时间',
            'distracted': '被打断了',
            'not_important': '不重要',
            'perfectionism': '想做到完美',
            'fear_of_failure': '害怕失败',
            'procrastination_habit': '习惯性拖延',
            'custom': '其他原因'
        }
        
        reason_text = reason_map.get(reason_type, reason_type)
        if reason_type == 'custom' and custom_reason:
            reason_text = custom_reason
        
        mood_desc_before = ""
        mood_desc_after = ""
        
        if mood_before:
            mood_map = {1: "很沮丧😢", 2: "有点低落😕", 3: "一般😐", 4: "还不错🙂", 5: "很开心😊"}
            mood_desc_before = f"拖延前心情：{mood_map.get(mood_before, '未知')}"
        
        if mood_after:
            mood_map = {1: "很沮丧😢", 2: "有点低落😕", 3: "一般😐", 4: "还不错🙂", 5: "很开心😊"}
            mood_desc_after = f"记录后心情：{mood_map.get(mood_after, '未知')}"
        
        prompt = f"""用户刚刚记录了一次拖延行为，需要你提供温柔的CBT风格分析：

拖延的任务：{task_title}
拖延原因：{reason_text}
{mood_desc_before}
{mood_desc_after}

请从认知行为治疗的角度，温柔地分析这次拖延行为，帮助用户理解自己的行为模式，并提供具体的改善建议。请特别关注用户的情绪变化。"""
        
        return prompt
    
    def _parse_cbt_analysis(self, content: str) -> Dict[str, str]:
        """解析CBT分析结果"""
        try:
            parts = content.split('|||')
            if len(parts) >= 3:
                analysis = parts[0].strip()
                suggestions_text = parts[1].strip()
                mood_advice = parts[2].strip()
                
                suggestions = [s.strip() for s in suggestions_text.split(';') if s.strip()]
                
                return {
                    'analysis': analysis,
                    'suggestions': suggestions,
                    'mood_advice': mood_advice
                }
        except:
            pass
        
        # 如果解析失败，返回整体内容
        return {
            'analysis': content,
            'suggestions': ['继续记录拖延行为，培养自我觉察', '将任务分解为更小的步骤', '建立合适的奖励机制'],
            'mood_advice': '请对自己温柔一些，拖延是很正常的现象。'
        }
    
    def _get_template_single_analysis(self, task_title: str, reason_type: str, custom_reason: str = None, mood_before: int = None, mood_after: int = None) -> Dict[str, str]:
        """获取单次拖延的模板分析"""
        
        reason_map = {
            'too_tired': '太累了',
            'dont_know_how': '不知道怎么做', 
            'not_in_mood': '没心情',
            'too_difficult': '太难了',
            'no_time': '没时间',
            'distracted': '被打断了',
            'not_important': '不重要',
            'perfectionism': '想做到完美',
            'fear_of_failure': '害怕失败',
            'procrastination_habit': '习惯性拖延',
            'custom': '其他原因'
        }
        
        reason_text = reason_map.get(reason_type, reason_type)
        if reason_type == 'custom' and custom_reason:
            reason_text = custom_reason
        
        # 根据原因类型提供针对性分析
        analysis_templates = {
            'too_tired': {
                'analysis': f'你因为"{reason_text}"而拖延了"{task_title}"，这很可能反映了你的能量管理需要调整。疲劳是身体发出的信号，告诉我们需要休息或调整节奏。拖延有时候是我们保护自己不过度消耗的本能反应。',
                'suggestions': [
                    '先给自己5分钟的休息时间，做几个深呼吸',
                    '将任务分解成更小的部分，只专注于第一步',
                    '考虑在精力最好的时间段重新安排这个任务'
                ],
                'mood_advice': '疲劳时拖延是很自然的反应，不要因此责备自己。重要的是学会倾听身体的声音，合理安排休息和工作。'
            },
            'not_in_mood': {
                'analysis': f'你因为"{reason_text}"而拖延了"{task_title}"，情绪对我们的行动力影响很大。心情不好时，大脑会自然地想要避开需要消耗精力的事情。这是一种自我保护机制，说明你需要先照顾好自己的情绪状态。',
                'suggestions': [
                    '先做一些能提升心情的小事，比如听音乐或看看搞笑视频',
                    '尝试"2分钟规则"：告诉自己只做2分钟，通常开始后就会继续下去',
                    '找一个安静舒适的环境，让自己感觉更放松'
                ],
                'mood_advice': '情绪起伏是人之常情，不要因为心情影响了行动而自责。接纳当下的感受，给自己一些温柔的关怀。'
            },
            'too_difficult': {
                'analysis': f'你因为觉得"{task_title}""{reason_text}"而拖延了，这种感受很常见。大脑天生倾向于避开看起来困难的任务，这是一种节约认知资源的本能。重要的是认识到"困难"往往被我们的想象放大了。',
                'suggestions': [
                    '将任务分解成最小的行动步骤，专注于第一个简单步骤',
                    '寻找相关的教程、资料或询问他人的建议',
                    '给自己设定一个小目标，比如先研究15分钟'
                ],
                'mood_advice': '面对困难是勇敢的表现，即使暂时拖延也不代表你能力不足。相信自己的学习能力，一步一步来。'
            },
            'perfectionism': {
                'analysis': f'你因为"{reason_text}"而拖延了"{task_title}"，完美主义是一种很常见的拖延原因。我们害怕做不够好，所以干脆不开始。但完美主义其实是恐惧的一种表现，害怕被批评或失败。',
                'suggestions': [
                    '设定一个"足够好"的标准，而不是完美的标准',
                    '提醒自己"进步胜过完美"，先完成再完善',
                    '给自己设定时间限制，避免过度琢磨细节'
                ],
                'mood_advice': '追求完美的心情可以理解，但记住你本身就已经足够好了。允许自己犯错和学习，这才是真正的成长。'
            }
        }
        
        template = analysis_templates.get(reason_type, {
            'analysis': f'你因为"{reason_text}"而拖延了"{task_title}"，每个人都会遇到拖延的情况，这是很正常的。拖延往往是我们内心某种需求或担忧的表现，比如需要休息、害怕失败或者觉得任务太复杂。',
            'suggestions': [
                '给自己一些理解和耐心，拖延不代表你懒惰',
                '尝试找出拖延背后的真正原因',
                '将任务分解成更容易开始的小步骤'
            ],
            'mood_advice': '对自己温柔一些，每个人都有拖延的时候。重要的是学会理解自己，找到适合的应对方式。'
        })
        
        # 如果有心情数据，添加心情相关的建议
        if mood_before and mood_after:
            mood_change = mood_after - mood_before
            if mood_change > 0:
                template['mood_advice'] += ' 很高兴看到记录后你的心情有所改善，这说明面对和接纳拖延行为本身就是治愈的开始。'
            elif mood_change < 0:
                template['mood_advice'] += ' 记录后心情有些低落是正常的，说明你在认真反思。这种自省的态度很珍贵，会帮助你更好地了解自己。'
            else:
                template['mood_advice'] += ' 记录前后心情的稳定显示了你的情绪调节能力，继续保持这种平和的心态。'
        
        return template
    
    def analyze_procrastination_patterns(self, recent_records: List[Dict], task_repetition_data: Dict) -> Dict[str, str]:
        """
        分析最近7天的拖延模式，包括任务重复性分析
        
        Args:
            recent_records: 最近的拖延记录列表
            task_repetition_data: 任务重复性数据，格式如 {"背单词": 3, "写作业": 2}
        
        Returns:
            Dict: 包含深度分析和建议的结果
        """
        try:
            if not self.api_key:
                return self._get_template_pattern_analysis(recent_records, task_repetition_data)
            
            prompt = self._build_pattern_analysis_prompt(recent_records, task_repetition_data)
            
            response = openai.ChatCompletion.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": self._get_pattern_analysis_system_prompt()},
                    {"role": "user", "content": prompt}
                ],
                max_tokens=1000,
                temperature=0.7
            )
            
            content = response.choices[0].message.content.strip()
            return self._parse_pattern_analysis(content)
            
        except Exception as e:
            print(f"模式分析失败: {str(e)}")
            return self._get_template_pattern_analysis(recent_records, task_repetition_data)
    
    def _get_pattern_analysis_system_prompt(self) -> str:
        """获取模式分析的系统提示词"""
        return """你是一位专业的认知行为治疗师，专门分析用户的拖延模式。请关注：

1. 任务重复性：如果某个任务反复被拖延，这通常暗示更深层的问题
2. 拖延原因的模式：用户是否经常用相同的理由拖延
3. 情绪模式：拖延前后的心情变化趋势
4. 提供深刻但温柔的洞察
5. 给出切实可行的改善方案

请按以下格式返回分析结果（用|||分隔）：
深度分析|||实用建议1;实用建议2;实用建议3|||情绪关怀建议

深度分析要揭示拖延背后的认知和情绪模式。
实用建议要针对重复拖延的任务提供具体解决方案。
情绪关怀建议要关注用户的心理健康。"""
    
    def _build_pattern_analysis_prompt(self, recent_records: List[Dict], task_repetition_data: Dict) -> str:
        """构建模式分析提示词"""
        
        # 整理拖延记录信息
        records_summary = []
        for record in recent_records[:10]:  # 最多分析10条记录
            records_summary.append(f"任务：{record.get('task_title', '未知')}，原因：{record.get('reason_display', '未知')}")
        
        # 整理重复任务信息
        repetition_summary = []
        for task, count in task_repetition_data.items():
            if count > 1:
                repetition_summary.append(f"{task}（拖延{count}次）")
        
        prompt = f"""请分析用户最近7天的拖延模式：

最近的拖延记录：
{chr(10).join(records_summary)}

重复拖延的任务：
{chr(10).join(repetition_summary) if repetition_summary else '无重复拖延任务'}

请从认知行为治疗的角度深度分析用户的拖延模式，特别关注：
1. 是否存在某些特定任务的重复拖延
2. 拖延原因是否有规律性
3. 可能的认知偏差和情绪模式
4. 针对重复拖延任务的根本性解决方案"""
        
        return prompt
    
    def _parse_pattern_analysis(self, content: str) -> Dict[str, str]:
        """解析模式分析结果"""
        try:
            parts = content.split('|||')
            if len(parts) >= 3:
                analysis = parts[0].strip()
                suggestions_text = parts[1].strip()
                mood_advice = parts[2].strip()
                
                suggestions = [s.strip() for s in suggestions_text.split(';') if s.strip()]
                
                return {
                    'analysis': analysis,
                    'suggestions': suggestions,
                    'mood_advice': mood_advice
                }
        except:
            pass
        
        return {
            'analysis': content,
            'suggestions': ['识别并接受自己的拖延模式', '制定针对重复任务的特定策略', '建立更有效的自我奖励系统'],
            'mood_advice': '理解自己的行为模式是改变的第一步，你已经做得很好了。'
        }
    
    def _get_template_pattern_analysis(self, recent_records: List[Dict], task_repetition_data: Dict) -> Dict[str, str]:
        """获取模式分析的模板结果"""
        
        # 分析重复任务
        repeated_tasks = {task: count for task, count in task_repetition_data.items() if count > 1}
        most_repeated_task = max(repeated_tasks.items(), key=lambda x: x[1]) if repeated_tasks else None
        
        # 分析拖延原因模式
        reason_counts = {}
        for record in recent_records:
            reason = record.get('reason_display', '未知')
            reason_counts[reason] = reason_counts.get(reason, 0) + 1
        
        most_common_reason = max(reason_counts.items(), key=lambda x: x[1]) if reason_counts else None
        
        # 基于分析生成建议
        analysis_parts = []
        suggestions = []
        
        if most_repeated_task:
            task_name, repeat_count = most_repeated_task
            analysis_parts.append(f'你在7天内对"{task_name}"拖延了{repeat_count}次，这表明这个任务可能触发了某种特定的心理阻抗。')
            
            if '背单词' in task_name or '学习' in task_name:
                suggestions.extend([
                    f'将"{task_name}"分解为更小的单元，比如每次只学5个单词',
                    '建立学习环境的仪式感，比如准备专用的学习角落',
                    '使用番茄工作法，每学习25分钟休息5分钟'
                ])
            elif '运动' in task_name or '锻炼' in task_name:
                suggestions.extend([
                    '降低运动强度，从每天10分钟开始',
                    '选择自己真正喜欢的运动方式',
                    '找一个运动伙伴增加动力'
                ])
            else:
                suggestions.extend([
                    f'重新审视"{task_name}"的必要性和紧急程度',
                    '考虑是否可以将任务委派给别人或者简化',
                    '为这个任务设定更现实的期望和标准'
                ])
        
        if most_common_reason:
            reason, reason_count = most_common_reason
            analysis_parts.append(f'你最常使用的拖延理由是"{reason}"（{reason_count}次），这可能反映了某种固定的思维模式或应对策略。')
            
            if '累' in reason:
                suggestions.append('关注精力管理，考虑调整作息时间和任务安排')
            elif '没心情' in reason or '心情' in reason:
                suggestions.append('开发情绪调节技巧，比如深呼吸、短暂散步或听音乐')
            elif '难' in reason:
                suggestions.append('练习将困难任务分解的技能，寻找学习资源和帮助')
        
        if not analysis_parts:
            analysis_parts.append('从你最近的记录来看，拖延行为还没有形成明显的固定模式，这是一个好现象。')
        
        # 默认建议
        if not suggestions:
            suggestions = [
                '继续记录拖延行为，提高自我觉察能力',
                '实验不同的任务执行策略，找到适合自己的方法',
                '建立适合自己的奖励机制，庆祝每一个小进步'
            ]
        
        return {
            'analysis': ' '.join(analysis_parts),
            'suggestions': suggestions[:3],  # 限制为3个建议
            'mood_advice': '通过记录和反思，你已经在改善的路上了。记住，改变需要时间，对自己耐心一些。每一次的自我觉察都是宝贵的进步。'
        }
