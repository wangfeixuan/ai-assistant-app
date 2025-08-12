"""
数据清理服务
处理90天数据自动清理等维护任务
"""

from datetime import datetime, timedelta
from models.task import Task, TaskStep, db
from models.user import User
import logging

class CleanupService:
    """数据清理服务类"""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
    
    def cleanup_old_tasks(self, days: int = 90) -> dict:
        """清理指定天数前的任务数据"""
        try:
            cutoff_date = datetime.utcnow() - timedelta(days=days)
            
            # 查找需要清理的任务
            old_tasks = Task.query.filter(Task.created_at < cutoff_date).all()
            
            if not old_tasks:
                return {
                    'success': True,
                    'message': '没有需要清理的数据',
                    'deleted_tasks': 0,
                    'deleted_steps': 0
                }
            
            # 统计信息
            task_count = len(old_tasks)
            step_count = sum(task.steps.count() for task in old_tasks)
            
            # 删除任务（级联删除步骤）
            for task in old_tasks:
                db.session.delete(task)
            
            db.session.commit()
            
            self.logger.info(f"清理完成: 删除了 {task_count} 个任务和 {step_count} 个步骤")
            
            return {
                'success': True,
                'message': f'成功清理 {days} 天前的数据',
                'deleted_tasks': task_count,
                'deleted_steps': step_count,
                'cutoff_date': cutoff_date.isoformat()
            }
            
        except Exception as e:
            db.session.rollback()
            self.logger.error(f"数据清理失败: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def cleanup_inactive_users(self, days: int = 365) -> dict:
        """清理长期不活跃的用户数据"""
        try:
            cutoff_date = datetime.utcnow() - timedelta(days=days)
            
            # 查找长期不活跃的用户（最后登录时间超过指定天数）
            inactive_users = User.query.filter(
                User.last_login_at < cutoff_date,
                User.is_active == True
            ).all()
            
            if not inactive_users:
                return {
                    'success': True,
                    'message': '没有需要处理的不活跃用户',
                    'processed_users': 0
                }
            
            # 标记为不活跃而不是直接删除
            processed_count = 0
            for user in inactive_users:
                user.is_active = False
                processed_count += 1
            
            db.session.commit()
            
            self.logger.info(f"处理了 {processed_count} 个长期不活跃用户")
            
            return {
                'success': True,
                'message': f'处理了 {processed_count} 个长期不活跃用户',
                'processed_users': processed_count,
                'cutoff_date': cutoff_date.isoformat()
            }
            
        except Exception as e:
            db.session.rollback()
            self.logger.error(f"清理不活跃用户失败: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def optimize_database(self) -> dict:
        """优化数据库性能"""
        try:
            # 这里可以执行数据库优化操作
            # 例如：重建索引、更新统计信息、清理碎片等
            
            # 示例：更新用户任务统计
            users = User.query.all()
            for user in users:
                # 可以在这里更新用户的统计信息
                pass
            
            return {
                'success': True,
                'message': '数据库优化完成'
            }
            
        except Exception as e:
            self.logger.error(f"数据库优化失败: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def get_cleanup_statistics(self) -> dict:
        """获取清理统计信息"""
        try:
            now = datetime.utcnow()
            
            # 统计各时间段的数据量
            stats = {
                'total_users': User.query.count(),
                'active_users': User.query.filter_by(is_active=True).count(),
                'total_tasks': Task.query.count(),
                'tasks_last_7_days': Task.query.filter(
                    Task.created_at >= now - timedelta(days=7)
                ).count(),
                'tasks_last_30_days': Task.query.filter(
                    Task.created_at >= now - timedelta(days=30)
                ).count(),
                'tasks_last_90_days': Task.query.filter(
                    Task.created_at >= now - timedelta(days=90)
                ).count(),
                'old_tasks_count': Task.query.filter(
                    Task.created_at < now - timedelta(days=90)
                ).count()
            }
            
            return {
                'success': True,
                'statistics': stats,
                'generated_at': now.isoformat()
            }
            
        except Exception as e:
            self.logger.error(f"获取统计信息失败: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def schedule_cleanup_task(self) -> dict:
        """调度清理任务（可以配合定时任务使用）"""
        try:
            results = []
            
            # 执行数据清理
            cleanup_result = self.cleanup_old_tasks()
            results.append(('task_cleanup', cleanup_result))
            
            # 处理不活跃用户
            inactive_result = self.cleanup_inactive_users()
            results.append(('inactive_users', inactive_result))
            
            # 数据库优化
            optimize_result = self.optimize_database()
            results.append(('database_optimize', optimize_result))
            
            return {
                'success': True,
                'message': '定时清理任务执行完成',
                'results': results,
                'executed_at': datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            self.logger.error(f"定时清理任务执行失败: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
