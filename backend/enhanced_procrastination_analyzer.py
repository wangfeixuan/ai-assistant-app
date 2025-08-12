#!/usr/bin/env python3
"""
增强版拖延分析器
提供个性化、深度、实用的拖延行为分析
"""

import json
import re
from typing import Dict, List, Optional, Tuple
from datetime import datetime, timedelta
from collections import Counter

class EnhancedProcrastinationAnalyzer:
    """增强版拖延分析器"""
    
    def __init__(self):
        self.task_patterns = self._initialize_task_patterns()
        self.reason_insights = self._initialize_reason_insights()
        self.contextual_factors = self._initialize_contextual_factors()
    
    def analyze_single_procrastination(self, 
                                     task_title: str, 
                                     reason_type: str, 
                                     custom_reason: str = None,
                                     mood_before: int = None, 
                                     mood_after: int = None,
                                     time_of_day: str = None,
                                     task_category: str = None) -> Dict:
        """
        深度分析单次拖延行为
        
        Args:
            task_title: 任务标题
            reason_type: 拖延原因类型
            custom_reason: 自定义原因
            mood_before: 拖延前心情(1-5)
            mood_after: 记录后心情(1-5)
            time_of_day: 拖延发生的时间段
            task_category: 任务类别
        
        Returns:
            Dict: 包含深度分析、个性化建议和行动计划
        """
        
        # 分析任务特征
        task_analysis = self._analyze_task_characteristics(task_title, task_category)
        
        # 分析拖延原因的深层含义
        reason_analysis = self._analyze_reason_depth(reason_type, custom_reason, task_analysis)
        
        # 分析情绪模式
        mood_analysis = self._analyze_mood_pattern(mood_before, mood_after)
        
        # 生成个性化洞察
        insights = self._generate_personalized_insights(
            task_analysis, reason_analysis, mood_analysis, time_of_day
        )
        
        # 生成具体可行的建议
        actionable_suggestions = self._generate_actionable_suggestions(
            task_title, reason_type, task_analysis, reason_analysis
        )
        
        # 生成行动计划
        action_plan = self._generate_action_plan(task_title, reason_analysis, task_analysis)
        
        return {
            'analysis': insights['main_insight'],
            'deep_understanding': insights['deep_understanding'],
            'suggestions': actionable_suggestions,
            'action_plan': action_plan,
            'mood_advice': mood_analysis['advice'],
            'pattern_warning': insights.get('pattern_warning', ''),
            'encouragement': self._generate_personalized_encouragement(reason_analysis, mood_analysis)
        }
    
    def _analyze_task_characteristics(self, task_title: str, task_category: str = None) -> Dict:
        """分析任务特征"""
        title_lower = task_title.lower()
        
        # 任务复杂度分析
        complexity_indicators = {
            'high': ['项目', '报告', '研究', '分析', '设计', '开发', '学习', '准备考试'],
            'medium': ['整理', '计划', '总结', '复习', '练习', '写作'],
            'low': ['打电话', '发邮件', '买', '洗', '收拾', '查看']
        }
        
        complexity = 'medium'  # 默认
        for level, indicators in complexity_indicators.items():
            if any(indicator in title_lower for indicator in indicators):
                complexity = level
                break
        
        # 任务类型分析
        task_types = {
            'creative': ['写', '设计', '创作', '画', '拍摄'],
            'analytical': ['分析', '研究', '计算', '统计', '评估'],
            'routine': ['整理', '清洁', '购买', '缴费', '预约'],
            'learning': ['学习', '背', '记忆', '复习', '练习'],
            'social': ['联系', '会议', '聚会', '拜访', '电话']
        }
        
        task_type = 'general'
        for t_type, keywords in task_types.items():
            if any(keyword in title_lower for keyword in keywords):
                task_type = t_type
                break
        
        # 时间估计
        time_indicators = {
            'long': ['项目', '学习', '研究', '准备', '开发'],
            'medium': ['写', '整理', '计划', '复习'],
            'short': ['打电话', '发邮件', '买', '查看']
        }
        
        estimated_time = 'medium'
        for duration, indicators in time_indicators.items():
            if any(indicator in title_lower for indicator in indicators):
                estimated_time = duration
                break
        
        return {
            'complexity': complexity,
            'type': task_type,
            'estimated_time': estimated_time,
            'title_keywords': self._extract_keywords(task_title)
        }
    
    def _analyze_reason_depth(self, reason_type: str, custom_reason: str, task_analysis: Dict) -> Dict:
        """深度分析拖延原因"""
        reason_insights = {
            'too_tired': {
                'surface': '身体疲劳',
                'deeper': '可能是精力管理不当，或者任务安排在了错误的时间',
                'root_causes': ['睡眠不足', '精力分配不合理', '任务过载', '缺乏休息'],
                'task_specific': {
                    'high': '复杂任务需要更多精力，疲劳时大脑会本能拒绝',
                    'creative': '创造性工作需要大量认知资源，疲劳时创意枯竭',
                    'learning': '学习需要专注力，疲劳时记忆和理解能力下降'
                }
            },
            'not_in_mood': {
                'surface': '情绪不佳',
                'deeper': '情绪状态与任务需求不匹配，或者内心对任务有抗拒',
                'root_causes': ['情绪调节困难', '任务缺乏意义感', '压力过大', '期望过高'],
                'task_specific': {
                    'creative': '创作需要积极情绪，心情不好时难以产生灵感',
                    'social': '社交任务需要良好心境，情绪低落时会回避人际接触',
                    'routine': '日常任务在情绪不佳时显得更加乏味'
                }
            },
            'too_difficult': {
                'surface': '任务困难',
                'deeper': '能力与任务要求之间存在感知差距，或者缺乏分解任务的技能',
                'root_causes': ['技能不足', '经验缺乏', '任务分解能力弱', '完美主义倾向'],
                'task_specific': {
                    'analytical': '分析任务需要逻辑思维，感觉困难可能是方法问题',
                    'learning': '学习困难往往是方法不当或基础不牢',
                    'creative': '创作困难可能是灵感缺乏或技巧不熟练'
                }
            },
            'perfectionism': {
                'surface': '追求完美',
                'deeper': '害怕失败或被批评，用完美主义掩盖内心的不安全感',
                'root_causes': ['自我价值感与成果绑定', '害怕批评', '控制欲强', '自信心不足'],
                'task_specific': {
                    'creative': '创作中的完美主义会扼杀创意和自然表达',
                    'analytical': '分析工作中过度追求完美会陷入细节无法自拔',
                    'routine': '日常任务也要求完美说明内心焦虑程度较高'
                }
            },
            'dont_know_how': {
                'surface': '不知道方法',
                'deeper': '缺乏规划能力或害怕开始后发现更多困难',
                'root_causes': ['规划技能不足', '信息收集能力弱', '害怕未知', '缺乏指导'],
                'task_specific': {
                    'learning': '学习方法不当是最常见的原因',
                    'analytical': '分析任务需要系统性思维',
                    'creative': '创作需要灵感和技巧的结合'
                }
            }
        }
        
        base_insight = reason_insights.get(reason_type, {
            'surface': custom_reason or '其他原因',
            'deeper': '每个人的拖延都有其独特的心理机制',
            'root_causes': ['个人习惯', '环境因素', '心理状态'],
            'task_specific': {}
        })
        
        # 结合任务特征提供更深入的分析
        task_specific_insight = base_insight['task_specific'].get(
            task_analysis['type'], 
            base_insight['task_specific'].get(task_analysis['complexity'], '')
        )
        
        return {
            'surface_reason': base_insight['surface'],
            'deeper_meaning': base_insight['deeper'],
            'root_causes': base_insight['root_causes'],
            'task_specific_insight': task_specific_insight,
            'custom_reason': custom_reason
        }
    
    def _analyze_mood_pattern(self, mood_before: int, mood_after: int) -> Dict:
        """分析情绪模式"""
        if mood_before is None or mood_after is None:
            return {
                'pattern': 'unknown',
                'advice': '记录情绪变化有助于更好地了解自己的拖延模式。'
            }
        
        mood_change = mood_after - mood_before
        
        patterns = {
            'significant_improvement': {
                'condition': mood_change >= 2,
                'meaning': '记录拖延行为显著改善了你的心情，说明面对问题本身就是解决问题的开始',
                'advice': '你有很好的自我调节能力。继续保持这种诚实面对自己的态度，它是成长的基础。'
            },
            'slight_improvement': {
                'condition': mood_change == 1,
                'meaning': '记录后心情有所好转，说明你正在学会接纳自己的不完美',
                'advice': '小的进步也值得庆祝。每一次的自我觉察都在为更好的自己积累能量。'
            },
            'stable': {
                'condition': mood_change == 0,
                'meaning': '情绪保持稳定，显示了良好的情绪调节能力',
                'advice': '情绪的稳定是一种珍贵的能力。在这种平和的状态下，更容易找到解决问题的方法。'
            },
            'slight_decline': {
                'condition': mood_change == -1,
                'meaning': '记录后心情略有下降，可能是在认真反思自己的行为',
                'advice': '适度的自省是健康的，但不要让它变成自我批评。记住，拖延是可以改善的行为模式。'
            },
            'significant_decline': {
                'condition': mood_change <= -2,
                'meaning': '心情明显下降，可能对自己过于严苛',
                'advice': '请对自己温柔一些。拖延不代表你是个失败者，它只是一个需要调整的习惯。每个人都在学习如何更好地管理自己。'
            }
        }
        
        for pattern_name, pattern_info in patterns.items():
            if pattern_info['condition']:
                return {
                    'pattern': pattern_name,
                    'meaning': pattern_info['meaning'],
                    'advice': pattern_info['advice'],
                    'mood_before': mood_before,
                    'mood_after': mood_after,
                    'change': mood_change
                }
        
        return {
            'pattern': 'unknown',
            'advice': '每一次记录都是对自己的关爱，继续保持这种自我觉察的习惯。'
        }
    
    def _generate_personalized_insights(self, task_analysis: Dict, reason_analysis: Dict, 
                                       mood_analysis: Dict, time_of_day: str = None) -> Dict:
        """生成个性化洞察"""
        
        # 主要洞察
        main_insight = f"你对「{task_analysis['title_keywords'][0] if task_analysis['title_keywords'] else '这个任务'}」的拖延，表面原因是{reason_analysis['surface_reason']}，但更深层的原因可能是{reason_analysis['deeper_meaning']}。"
        
        # 深度理解
        deep_understanding = []
        
        # 任务特征相关的理解
        if task_analysis['complexity'] == 'high':
            deep_understanding.append("这是一个复杂度较高的任务，大脑天然会对复杂任务产生回避反应，这是正常的自我保护机制。")
        
        if task_analysis['type'] == 'creative':
            deep_understanding.append("创造性任务需要特定的心理状态和环境，拖延可能是在等待合适的创作时机。")
        elif task_analysis['type'] == 'learning':
            deep_understanding.append("学习任务的拖延往往与我们对「不知道」状态的不适感有关，这种不确定性会让人焦虑。")
        
        # 原因特定的理解
        if reason_analysis['task_specific_insight']:
            deep_understanding.append(reason_analysis['task_specific_insight'])
        
        # 情绪相关的理解
        if mood_analysis['pattern'] != 'unknown':
            deep_understanding.append(mood_analysis['meaning'])
        
        # 时间相关的理解
        if time_of_day:
            time_insights = {
                'morning': '早晨拖延可能与起床状态或一天的能量分配有关',
                'afternoon': '下午拖延常常是因为上午的任务消耗了太多精力',
                'evening': '晚上拖延可能是白天积累的疲劳或对休息的渴望',
                'night': '深夜拖延往往与焦虑或对第二天的担忧有关'
            }
            if time_of_day in time_insights:
                deep_understanding.append(time_insights[time_of_day])
        
        return {
            'main_insight': main_insight,
            'deep_understanding': ' '.join(deep_understanding) if deep_understanding else '每个人的拖延都有其独特的心理机制，理解这些机制是改变的第一步。'
        }
    
    def _generate_actionable_suggestions(self, task_title: str, reason_type: str, 
                                       task_analysis: Dict, reason_analysis: Dict) -> List[str]:
        """生成具体可行的建议"""
        suggestions = []
        
        # 基于拖延原因的建议
        reason_suggestions = {
            'too_tired': [
                f"将「{task_title}」安排在你精力最好的时间段（通常是上午）",
                "在开始前做5分钟的轻度运动或深呼吸来提升状态",
                f"如果「{task_title}」预计需要很长时间，先设定一个15分钟的小目标"
            ],
            'not_in_mood': [
                f"创造一个专门用于「{task_title}」的仪式感环境（特定音乐、地点、工具）",
                "先做一件能快速提升心情的小事，比如整理桌面或喝杯喜欢的茶",
                f"将「{task_title}」与你喜欢的活动结合，比如在咖啡厅完成或听着音乐做"
            ],
            'too_difficult': [
                f"将「{task_title}」分解成5个具体的小步骤，只专注于第一步",
                f"为「{task_title}」寻找一个教程、模板或成功案例作为参考",
                f"找一个在「{task_title}」方面有经验的人请教，或者在网上搜索相关经验分享"
            ],
            'perfectionism': [
                f"为「{task_title}」设定一个「足够好」的标准，写下来贴在显眼位置",
                f"给「{task_title}」设定严格的时间限制，比如只允许自己花2小时完成",
                f"提醒自己「{task_title}」的目的是完成而不是完美，先有再好"
            ],
            'dont_know_how': [
                f"花15分钟专门研究「{task_title}」的方法和步骤，制作一个简单的行动清单",
                f"将「{task_title}」类比到你曾经成功完成的类似任务，借鉴经验",
                f"在网上搜索「如何{task_title}」或「{task_title}教程」，找到最简单的入门方法"
            ]
        }
        
        base_suggestions = reason_suggestions.get(reason_type, [
            f"尝试将「{task_title}」与你的日常习惯绑定，比如在固定时间完成",
            f"为完成「{task_title}」设定一个小奖励，增加动机",
            f"找一个朋友分享你要完成「{task_title}」的计划，增加外部监督"
        ])
        
        suggestions.extend(base_suggestions)
        
        # 基于任务特征的建议
        if task_analysis['complexity'] == 'high':
            suggestions.append(f"将「{task_title}」拆分成多个独立的子任务，每天只专注于一个子任务")
        
        if task_analysis['type'] == 'creative':
            suggestions.append("为创作准备一个灵感收集本，随时记录想法，降低创作时的压力")
        elif task_analysis['type'] == 'learning':
            suggestions.append("使用番茄工作法：学习25分钟，休息5分钟，让大脑有消化时间")
        elif task_analysis['type'] == 'routine':
            suggestions.append("将日常任务与播客、音乐或有声书结合，增加趣味性")
        
        return suggestions[:4]  # 返回最相关的4个建议
    
    def _generate_action_plan(self, task_title: str, reason_analysis: Dict, task_analysis: Dict) -> Dict:
        """生成具体的行动计划"""
        
        # 立即行动（5分钟内）
        immediate_actions = [
            f"拿出纸笔，写下「{task_title}」的第一个具体步骤",
            "设置一个5分钟的计时器，只专注于开始",
            "清理工作区域，为任务创造一个干净的环境"
        ]
        
        # 短期计划（今天内）
        today_plan = [
            f"为「{task_title}」安排一个具体的时间段（比如下午2-3点）",
            "准备完成任务所需的所有工具和资料",
            f"完成「{task_title}」的第一个小步骤，不求完美"
        ]
        
        # 长期策略（本周内）
        weekly_strategy = [
            f"观察自己在什么时间、地点、状态下最容易开始「{task_title}」类型的任务",
            "建立一个专门用于此类任务的工作流程",
            "记录完成类似任务的成功经验，形成个人方法库"
        ]
        
        return {
            'immediate': immediate_actions[0],  # 最重要的立即行动
            'today': today_plan,
            'this_week': weekly_strategy
        }
    
    def _generate_personalized_encouragement(self, reason_analysis: Dict, mood_analysis: Dict) -> str:
        """生成个性化鼓励"""
        
        encouragements = {
            'too_tired': "疲劳时选择休息而不是强迫自己，这说明你懂得倾听身体的声音。这种自我关怀的能力很珍贵。",
            'not_in_mood': "情绪会影响行动，这是人之常情。你能够觉察到自己的情绪状态，这已经是很大的进步了。",
            'too_difficult': "面对困难时感到退缩是正常的反应。重要的是你没有放弃，而是在寻找解决方法。",
            'perfectionism': "追求完美的心可以理解，这说明你对自己有要求。学会在完美和完成之间找到平衡，你会更快乐。",
            'dont_know_how': "承认不知道需要勇气，这是学习的开始。每个专家都曾经是初学者。"
        }
        
        base_encouragement = encouragements.get(reason_analysis['surface_reason'], 
                                               "每个人都会遇到拖延，重要的是你正在积极面对和改善。")
        
        # 根据情绪变化调整鼓励语
        if mood_analysis['pattern'] in ['significant_improvement', 'slight_improvement']:
            base_encouragement += " 看到你记录后心情有所改善，这说明你有很好的自我调节能力。"
        elif mood_analysis['pattern'] in ['significant_decline']:
            base_encouragement += " 请记住，拖延不定义你是谁。你正在成长的路上，每一步都值得肯定。"
        
        return base_encouragement
    
    def _extract_keywords(self, text: str) -> List[str]:
        """提取关键词"""
        # 简单的关键词提取
        words = re.findall(r'\b\w+\b', text)
        # 过滤掉常见的停用词
        stop_words = {'的', '了', '在', '是', '我', '你', '他', '她', '它', '们', '这', '那', '和', '或', '但', '因为', '所以'}
        keywords = [word for word in words if word not in stop_words and len(word) > 1]
        return keywords[:3]  # 返回前3个关键词
    
    def _initialize_task_patterns(self) -> Dict:
        """初始化任务模式"""
        return {}
    
    def _initialize_reason_insights(self) -> Dict:
        """初始化原因洞察"""
        return {}
    
    def _initialize_contextual_factors(self) -> Dict:
        """初始化上下文因素"""
        return {}

# 测试函数
def test_enhanced_analyzer():
    """测试增强版分析器"""
    analyzer = EnhancedProcrastinationAnalyzer()
    
    test_cases = [
        {
            'task_title': '准备明天的数学考试',
            'reason_type': 'too_difficult',
            'mood_before': 2,
            'mood_after': 3,
            'time_of_day': 'evening',
            'task_category': 'learning'
        },
        {
            'task_title': '写项目总结报告',
            'reason_type': 'perfectionism',
            'mood_before': 3,
            'mood_after': 2,
            'time_of_day': 'afternoon',
            'task_category': 'work'
        },
        {
            'task_title': '整理房间',
            'reason_type': 'not_in_mood',
            'mood_before': 2,
            'mood_after': 4,
            'time_of_day': 'morning',
            'task_category': 'routine'
        }
    ]
    
    print("🧠 增强版拖延分析器测试")
    print("=" * 60)
    
    for i, case in enumerate(test_cases, 1):
        print(f"\n📝 测试案例 {i}: {case['task_title']}")
        print(f"原因: {case['reason_type']} | 心情变化: {case['mood_before']}→{case['mood_after']}")
        print("-" * 50)
        
        result = analyzer.analyze_single_procrastination(**case)
        
        print(f"💡 主要洞察: {result['analysis']}")
        print(f"🔍 深度理解: {result['deep_understanding']}")
        print(f"💪 鼓励话语: {result['encouragement']}")
        print(f"📋 建议数量: {len(result['suggestions'])}")
        print(f"   • {result['suggestions'][0]}")
        if len(result['suggestions']) > 1:
            print(f"   • {result['suggestions'][1]}")
        print(f"🎯 立即行动: {result['action_plan']['immediate']}")

if __name__ == "__main__":
    test_enhanced_analyzer()
