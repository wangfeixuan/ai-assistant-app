#!/usr/bin/env python3
"""
AI提示词配置管理
提供提示词的版本管理和A/B测试功能
"""

import json
from typing import Dict, List, Optional
from datetime import datetime

class AIPromptConfig:
    """AI提示词配置管理类"""
    
    def __init__(self):
        self.current_version = "v2.0"
        self.prompt_versions = {
            "v1.0": self._get_v1_system_prompt(),
            "v2.0": self._get_v2_system_prompt(),
        }
        
    def get_system_prompt(self, version: Optional[str] = None) -> str:
        """获取指定版本的系统提示词"""
        version = version or self.current_version
        return self.prompt_versions.get(version, self.prompt_versions[self.current_version])
    
    def _get_v1_system_prompt(self) -> str:
        """获取v1.0版本的系统提示词（原始版本）"""
        return """你是一个专业的任务拆解助手，帮助用户将复杂任务分解为可执行的步骤。

请将用户的任务拆解为具体的执行步骤，每个步骤应该：
1. 清晰明确，避免模糊表达
2. 可在短时间内完成（建议5-15分钟）
3. 按逻辑顺序排列

请以列表形式返回步骤。"""

    def _get_v2_system_prompt(self) -> str:
        """获取v2.0版本的系统提示词（当前优化版本）"""
        return """你是一个「学生任务拆分专家」，专门将任何学习任务拆分为具体、可执行的步骤。

**你的核心使命**：
将任务拆分为具体、可执行的步骤，每个步骤需要包含：
1. **任务描述**：清晰简洁，避免模糊抽象的表达
2. **时间分配**：基于任务难度的合理时间估计
3. **鼓励语**：激励性的简短语句，适合学生心理
4. **执行顺序**：按照时间顺序排列，确保整个任务能在合理时间内完成
5. **学生友好**：每个任务都具体、可操作，适合学生执行

**严格禁止的笼统表达**：
❌ "整理作业" → 必须说"把10页A4纸按顺序摆放在桌子左上角"
❌ "开始做题" → 必须说"用黑色笔在笔记本上写下第1题的题号"
❌ "检查答案" → 必须说"用红笔在每道题的右上角打✓或×"
❌ "休息一下" → 必须说"放下笔，起身到阳台深呼吸10次，然后坐回桌子前"
❌ "总结知识点" → 必须说"在笔记本最后一页写下'今天学会的公式'，然后列出3个公式名称"

**必须包含的超级具体元素**：
1. **物品名称**："10页A4数学作业纸""黑色中性笔""红色改错笔"
2. **动作动词**："拿起""放在""翻开到""用手指点""在....上写下"
3. **位置坐标**："桌子左上角""笔记本第3行""页面右上角"
4. **时间数字**："2分钟""15分钟""60分钟"（不能说"几分钟"）
5. **判断标准**："3秒内知道答案""看一眼就会做""需要思考超过5分钟的题"

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

2. 翻开第1页作业纸，用右手食指从页面最上方开始向下慢慢扫描，在心里默数"1、2"，找出2道看一眼就知道怎么做的题 (2分钟)
   鼓励语：先攻简题
   下一步：拿笔开始写第1题

3. 拿起黑色中性笔，在笔记本第1页的第1行写下"题目1："，然后在下一行开始写完整的解题过程和最终答案 (4分钟)
   鼓励语：思路已定
   下一步：写第2题的题号

4. 在笔记本上空2行，写下"题目2："，然后用同样的方式写出第2题的完整解答 (5分钟)
   鼓励语：连续作战
   下一步：用手指扫描第1页剩余题目

记住：每个步骤都必须像操作手册一样精确，让人能一步一步照着做！"""

    def get_prompt_comparison(self) -> Dict:
        """获取不同版本提示词的对比信息"""
        return {
            "versions": list(self.prompt_versions.keys()),
            "current": self.current_version,
            "comparison": {
                "v1.0": {
                    "length": len(self.prompt_versions["v1.0"]),
                    "features": ["基础任务拆解", "简单列表输出", "通用性强"],
                    "limitations": ["步骤不够具体", "缺少时间估计", "无鼓励语"]
                },
                "v2.0": {
                    "length": len(self.prompt_versions["v2.0"]),
                    "features": ["超级具体化", "JSON结构化输出", "时间估计", "鼓励语", "学生友好"],
                    "improvements": ["操作手册级精确度", "完整字段支持", "防止笼统表达"]
                }
            }
        }

    def validate_prompt_output(self, output: str, version: str = None) -> Dict:
        """验证AI输出是否符合提示词要求"""
        version = version or self.current_version
        validation_result = {
            "version": version,
            "is_valid": False,
            "issues": [],
            "score": 0
        }
        
        if version == "v2.0":
            # JSON格式验证
            try:
                data = json.loads(output)
                validation_result["is_json"] = True
                validation_result["score"] += 20
                
                # 检查必需字段
                required_fields = ["original_task", "estimated_total_time_min", "steps", "todo_notes"]
                for field in required_fields:
                    if field in data:
                        validation_result["score"] += 15
                    else:
                        validation_result["issues"].append(f"缺少字段: {field}")
                
                # 检查步骤结构
                if "steps" in data and isinstance(data["steps"], list):
                    step_fields = ["step_number", "description", "time_estimate_min", "motivational_cue", "next_step_hint"]
                    for i, step in enumerate(data["steps"][:3]):  # 检查前3个步骤
                        if isinstance(step, dict):
                            for field in step_fields:
                                if field in step:
                                    validation_result["score"] += 2
                                else:
                                    validation_result["issues"].append(f"步骤{i+1}缺少字段: {field}")
                
                # 检查具体性
                if "steps" in data:
                    concrete_words = ["拿起", "放在", "写下", "翻开", "用", "在", "按", "点击"]
                    concrete_count = 0
                    for step in data["steps"]:
                        if isinstance(step, dict) and "description" in step:
                            desc = step["description"]
                            concrete_count += sum(1 for word in concrete_words if word in desc)
                    
                    if concrete_count >= len(data["steps"]) * 0.7:  # 70%的步骤包含具体操作
                        validation_result["score"] += 20
                        validation_result["concrete_score"] = concrete_count
                    else:
                        validation_result["issues"].append(f"具体操作词汇不足: {concrete_count}/{len(data['steps'])}")
                
            except json.JSONDecodeError:
                validation_result["is_json"] = False
                validation_result["issues"].append("输出不是有效的JSON格式")
        
        validation_result["is_valid"] = validation_result["score"] >= 80 and len(validation_result["issues"]) == 0
        return validation_result

if __name__ == "__main__":
    # 测试配置管理
    config = AIPromptConfig()
    print("🔧 AI提示词配置管理测试")
    print("=" * 50)
    
    comparison = config.get_prompt_comparison()
    print(f"当前版本: {comparison['current']}")
    print(f"可用版本: {comparison['versions']}")
    
    for version, info in comparison["comparison"].items():
        print(f"\n📋 {version} 版本信息:")
        print(f"  长度: {info['length']} 字符")
        print(f"  特性: {', '.join(info['features'])}")
        if 'improvements' in info:
            print(f"  改进: {', '.join(info['improvements'])}")
