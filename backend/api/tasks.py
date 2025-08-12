"""
任务管理API接口
处理任务的创建、查询、更新、删除等功能
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime, date, timedelta
from models.task import Task, TaskStep, TaskStatus, TaskPriority, db
from models.user import User
from services.ai_service import AIService

tasks_bp = Blueprint('tasks', __name__)

@tasks_bp.route('/', methods=['GET'])
@jwt_required()
def get_tasks():
    """获取用户任务列表"""
    try:
        current_user_id = get_jwt_identity()
        
        # 获取查询参数
        status = request.args.get('status')
        date_filter = request.args.get('date', 'today')  # today, week, month, all
        page = int(request.args.get('page', 1))
        per_page = int(request.args.get('per_page', 20))
        
        # 构建查询
        query = Task.query.filter_by(user_id=current_user_id)
        
        # 状态过滤
        if status:
            try:
                status_enum = TaskStatus(status)
                query = query.filter_by(status=status_enum)
            except ValueError:
                return jsonify({'error': '无效的任务状态'}), 400
        
        # 日期过滤
        if date_filter == 'today':
            today = date.today()
            query = query.filter(db.func.date(Task.created_at) == today)
        elif date_filter == 'week':
            week_ago = date.today() - timedelta(days=7)
            query = query.filter(Task.created_at >= week_ago)
        elif date_filter == 'month':
            month_ago = date.today() - timedelta(days=30)
            query = query.filter(Task.created_at >= month_ago)
        
        # 排序和分页
        query = query.order_by(Task.created_at.desc())
        pagination = query.paginate(page=page, per_page=per_page, error_out=False)
        
        tasks = [task.to_dict() for task in pagination.items]
        
        return jsonify({
            'tasks': tasks,
            'pagination': {
                'page': page,
                'per_page': per_page,
                'total': pagination.total,
                'pages': pagination.pages,
                'has_next': pagination.has_next,
                'has_prev': pagination.has_prev
            }
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'获取任务列表失败: {str(e)}'}), 500

@tasks_bp.route('/<int:task_id>', methods=['GET'])
@jwt_required()
def get_task(task_id):
    """获取任务详情"""
    try:
        current_user_id = get_jwt_identity()
        
        task = Task.query.filter_by(id=task_id, user_id=current_user_id).first()
        if not task:
            return jsonify({'error': '任务不存在'}), 404
        
        return jsonify({
            'task': task.to_dict(include_steps=True)
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'获取任务详情失败: {str(e)}'}), 500

@tasks_bp.route('/', methods=['POST'])
@jwt_required()
def create_task():
    """创建新任务（通过AI拆解）"""
    try:
        current_user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data or 'title' not in data:
            return jsonify({'error': '任务标题为必填项'}), 400
        
        title = data['title'].strip()
        if not title:
            return jsonify({'error': '任务标题不能为空'}), 400
        
        description = data.get('description', '').strip()
        priority = data.get('priority', 'medium')
        
        # 验证优先级
        try:
            priority_enum = TaskPriority(priority)
        except ValueError:
            return jsonify({'error': '无效的任务优先级'}), 400
        
        # 创建任务
        task = Task(user_id=current_user_id, title=title, description=description)
        task.priority = priority_enum
        
        db.session.add(task)
        db.session.commit()
        
        # 使用AI服务生成任务步骤
        ai_service = AIService()
        steps = ai_service.decompose_task(title, description)
        
        if steps:
            task.add_steps(steps)
        
        return jsonify({
            'message': '任务创建成功',
            'task': task.to_dict(include_steps=True)
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'创建任务失败: {str(e)}'}), 500

@tasks_bp.route('/<int:task_id>', methods=['PUT'])
@jwt_required()
def update_task(task_id):
    """更新任务信息"""
    try:
        current_user_id = get_jwt_identity()
        
        task = Task.query.filter_by(id=task_id, user_id=current_user_id).first()
        if not task:
            return jsonify({'error': '任务不存在'}), 404
        
        data = request.get_json()
        if not data:
            return jsonify({'error': '请提供要更新的数据'}), 400
        
        # 可更新的字段
        if 'title' in data:
            task.title = data['title'].strip()
        
        if 'description' in data:
            task.description = data['description'].strip()
        
        if 'status' in data:
            try:
                task.status = TaskStatus(data['status'])
                if task.status == TaskStatus.COMPLETED:
                    task.completed_at = datetime.utcnow()
            except ValueError:
                return jsonify({'error': '无效的任务状态'}), 400
        
        if 'priority' in data:
            try:
                task.priority = TaskPriority(data['priority'])
            except ValueError:
                return jsonify({'error': '无效的任务优先级'}), 400
        
        if 'due_date' in data:
            if data['due_date']:
                try:
                    task.due_date = datetime.strptime(data['due_date'], '%Y-%m-%d').date()
                except ValueError:
                    return jsonify({'error': '日期格式错误，请使用YYYY-MM-DD'}), 400
            else:
                task.due_date = None
        
        db.session.commit()
        
        return jsonify({
            'message': '任务更新成功',
            'task': task.to_dict(include_steps=True)
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'更新任务失败: {str(e)}'}), 500

@tasks_bp.route('/<int:task_id>', methods=['DELETE'])
@jwt_required()
def delete_task(task_id):
    """删除任务"""
    try:
        current_user_id = get_jwt_identity()
        
        task = Task.query.filter_by(id=task_id, user_id=current_user_id).first()
        if not task:
            return jsonify({'error': '任务不存在'}), 404
        
        db.session.delete(task)
        db.session.commit()
        
        return jsonify({'message': '任务删除成功'}), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'删除任务失败: {str(e)}'}), 500

@tasks_bp.route('/<int:task_id>/steps/<int:step_id>/complete', methods=['POST'])
@jwt_required()
def complete_step(task_id, step_id):
    """标记任务步骤为完成"""
    try:
        current_user_id = get_jwt_identity()
        
        task = Task.query.filter_by(id=task_id, user_id=current_user_id).first()
        if not task:
            return jsonify({'error': '任务不存在'}), 404
        
        success = task.mark_step_completed(step_id)
        if not success:
            return jsonify({'error': '步骤不存在或已完成'}), 400
        
        return jsonify({
            'message': '步骤标记完成',
            'task': task.to_dict(include_steps=True)
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'标记步骤完成失败: {str(e)}'}), 500

@tasks_bp.route('/<int:task_id>/steps/<int:step_id>/uncomplete', methods=['POST'])
@jwt_required()
def uncomplete_step(task_id, step_id):
    """取消标记任务步骤完成"""
    try:
        current_user_id = get_jwt_identity()
        
        task = Task.query.filter_by(id=task_id, user_id=current_user_id).first()
        if not task:
            return jsonify({'error': '任务不存在'}), 404
        
        step = TaskStep.query.filter_by(id=step_id, task_id=task_id).first()
        if not step:
            return jsonify({'error': '步骤不存在'}), 404
        
        if step.mark_uncompleted():
            task.completed_steps -= 1
            if task.status == TaskStatus.COMPLETED:
                task.status = TaskStatus.IN_PROGRESS
                task.completed_at = None
            
            db.session.commit()
        
        return jsonify({
            'message': '取消步骤完成标记',
            'task': task.to_dict(include_steps=True)
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'取消步骤完成标记失败: {str(e)}'}), 500

@tasks_bp.route('/stats', methods=['GET'])
@jwt_required()
def get_task_stats():
    """获取任务统计信息"""
    try:
        current_user_id = get_jwt_identity()
        
        # 总任务数
        total_tasks = Task.query.filter_by(user_id=current_user_id).count()
        
        # 各状态任务数
        pending_tasks = Task.query.filter_by(
            user_id=current_user_id, 
            status=TaskStatus.PENDING
        ).count()
        
        in_progress_tasks = Task.query.filter_by(
            user_id=current_user_id, 
            status=TaskStatus.IN_PROGRESS
        ).count()
        
        completed_tasks = Task.query.filter_by(
            user_id=current_user_id, 
            status=TaskStatus.COMPLETED
        ).count()
        
        # 今日任务数
        today = date.today()
        today_tasks = Task.query.filter(
            Task.user_id == current_user_id,
            db.func.date(Task.created_at) == today
        ).count()
        
        # 本周完成任务数
        week_ago = date.today() - timedelta(days=7)
        week_completed = Task.query.filter(
            Task.user_id == current_user_id,
            Task.status == TaskStatus.COMPLETED,
            Task.completed_at >= week_ago
        ).count()
        
        return jsonify({
            'stats': {
                'total_tasks': total_tasks,
                'pending_tasks': pending_tasks,
                'in_progress_tasks': in_progress_tasks,
                'completed_tasks': completed_tasks,
                'today_tasks': today_tasks,
                'week_completed': week_completed,
                'completion_rate': round(completed_tasks / total_tasks * 100, 1) if total_tasks > 0 else 0
            }
        }), 200
        
    except Exception as e:
        return jsonify({'error': f'获取任务统计失败: {str(e)}'}), 500
