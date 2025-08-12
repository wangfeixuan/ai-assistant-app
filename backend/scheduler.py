"""
定时任务调度器
处理拖延检测、提醒等定时任务
"""

import schedule
import time
import threading
from datetime import datetime, timedelta
from flask import current_app
from models.task import Task
from models.procrastination_diary import ProcrastinationDiary, ProcrastinationReason
from models.push_token import UserPushToken
from models import db
from sqlalchemy import func
from services.notification_service import notification_service

class TaskScheduler:
    """任务调度器类"""
    
    def __init__(self, app=None):
        self.app = app
        self.running = False
        self.scheduler_thread = None
        
    def init_app(self, app):
        """初始化应用"""
        self.app = app
        
    def start(self):
        """启动调度器"""
        if self.running:
            return
            
        self.running = True
        
        # 设置定时任务
        schedule.every().day.at("22:00").do(self.send_evening_reminder)  # 晚上10点提醒
        schedule.every().day.at("00:01").do(self.check_overdue_tasks)    # 凌晨检查拖延任务
        
        # 在单独线程中运行调度器
        self.scheduler_thread = threading.Thread(target=self._run_scheduler, daemon=True)
        self.scheduler_thread.start()
        
        print("任务调度器已启动")
        
    def stop(self):
        """停止调度器"""
        self.running = False
        schedule.clear()
        print("任务调度器已停止")
        
    def _run_scheduler(self):
        """运行调度器的内部方法"""
        while self.running:
            schedule.run_pending()
            time.sleep(60)  # 每分钟检查一次
            
    def send_evening_reminder(self):
        """发送晚上提醒（晚上10点）"""
        try:
            with self.app.app_context():
                # 查找今天未完成的任务
                today = datetime.now().date()
                
                incomplete_tasks = db.session.query(
                    Task.user_id,
                    func.count(Task.id).label('count')
                ).filter(
                    Task.completed == False,
                    func.date(Task.created_at) == today
                ).group_by(Task.user_id).all()
                
                print(f"晚上10点提醒: 发现 {len(incomplete_tasks)} 个用户有未完成任务")
                
                # 发送推送通知
                success_count = 0
                for user_id, task_count in incomplete_tasks:
                    # 检查用户是否启用了晚间提醒
                    active_tokens = UserPushToken.get_active_tokens_for_user(user_id, 'evening')
                    if active_tokens:
                        success = notification_service.send_evening_reminder(user_id, task_count)
                        if success:
                            success_count += 1
                            print(f"用户 {user_id} 晚间提醒发送成功: {task_count} 个未完成任务")
                        else:
                            print(f"用户 {user_id} 晚间提醒发送失败")
                    else:
                        print(f"用户 {user_id} 未启用晚间提醒或无有效设备")
                
                print(f"晚间提醒发送完成: {success_count}/{len(incomplete_tasks)} 成功")
                    
        except Exception as e:
            print(f"发送晚上提醒失败: {str(e)}")
            
    def check_overdue_tasks(self):
        """检查并标记超时任务（凌晨执行）"""
        try:
            with self.app.app_context():
                # 获取昨天的日期
                yesterday = (datetime.now() - timedelta(days=1)).date()
                
                # 查找昨天创建但未完成的任务
                overdue_tasks = Task.query.filter(
                    Task.completed == False,
                    func.date(Task.created_at) == yesterday
                ).all()
                
                print(f"凌晨检查: 发现 {len(overdue_tasks)} 个拖延任务")
                
                for task in overdue_tasks:
                    # 检查是否已经有拖延记录
                    existing_record = ProcrastinationDiary.query.filter(
                        ProcrastinationDiary.user_id == task.user_id,
                        ProcrastinationDiary.task_id == task.id,
                        ProcrastinationDiary.procrastination_date == yesterday
                    ).first()
                    
                    if not existing_record:
                        # 创建拖延记录，等待用户输入原因
                        diary_entry = ProcrastinationDiary(
                            user_id=task.user_id,
                            task_id=task.id,
                            task_title=task.title,
                            reason_type=ProcrastinationReason.CUSTOM,  # 临时设置，等待用户选择
                            procrastination_date=yesterday
                        )
                        
                        db.session.add(diary_entry)
                        print(f"为任务 '{task.title}' 创建拖延记录")
                
                db.session.commit()
                print("拖延任务检查完成")
                
        except Exception as e:
            db.session.rollback()
            print(f"检查拖延任务失败: {str(e)}")
            
    def send_push_notification(self, user_id, message):
        """发送推送通知（待实现）"""
        # TODO: 实现推送通知功能
        # 可以集成Firebase Cloud Messaging (FCM) 或 Apple Push Notification Service (APNs)
        pass

# 全局调度器实例
scheduler = TaskScheduler()

def init_scheduler(app):
    """初始化调度器"""
    scheduler.init_app(app)
    scheduler.start()
    return scheduler
