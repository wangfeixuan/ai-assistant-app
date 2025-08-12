# 拖延症AI助手 API规范文档

## 概述

本文档定义了拖延症AI助手项目的完整API接口规范，基于RESTful架构设计，支持前后端分离开发。

## 基础信息

- **Base URL**: `https://api.procrastination-helper.com/v1`
- **认证方式**: JWT Token
- **数据格式**: JSON
- **字符编码**: UTF-8

## 通用响应格式

```json
{
  "success": true,
  "code": 200,
  "message": "操作成功",
  "data": {},
  "timestamp": "2024-01-01T12:00:00Z"
}
```

### 错误响应格式

```json
{
  "success": false,
  "code": 400,
  "message": "请求参数错误",
  "error": "详细错误信息",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

## 1. 用户认证模块

### 1.1 用户注册

```http
POST /auth/register
```

**请求体**:
```json
{
  "username": "string",
  "email": "string",
  "password": "string",
  "confirmPassword": "string"
}
```

**响应**:
```json
{
  "success": true,
  "data": {
    "userId": "uuid",
    "username": "string",
    "email": "string",
    "token": "jwt_token",
    "refreshToken": "refresh_token"
  }
}
```

### 1.2 用户登录

```http
POST /auth/login
```

**请求体**:
```json
{
  "email": "string",
  "password": "string"
}
```

**响应**:
```json
{
  "success": true,
  "data": {
    "userId": "uuid",
    "username": "string",
    "email": "string",
    "token": "jwt_token",
    "refreshToken": "refresh_token",
    "theme": "business|cute"
  }
}
```

### 1.3 刷新Token

```http
POST /auth/refresh
```

**请求体**:
```json
{
  "refreshToken": "string"
}
```

### 1.4 用户登出

```http
POST /auth/logout
```

**请求头**:
```
Authorization: Bearer {token}
```

## 2. AI任务拆解模块

### 2.1 任务拆解

```http
POST /ai/decompose
```

**请求头**:
```
Authorization: Bearer {token}
```

**请求体**:
```json
{
  "taskDescription": "string",
  "taskType": "study|work|life|exercise|other",
  "difficulty": "easy|medium|hard",
  "timeLimit": "number" // 可选，预期完成时间（分钟）
}
```

**响应**:
```json
{
  "success": true,
  "data": {
    "taskId": "uuid",
    "originalTask": "string",
    "steps": [
      {
        "stepId": "uuid",
        "order": 1,
        "description": "string",
        "estimatedTime": 5, // 预估时间（分钟）
        "difficulty": "easy",
        "tips": "string" // 可选的执行建议
      }
    ],
    "totalSteps": 6,
    "estimatedTotalTime": 30,
    "createdAt": "2024-01-01T12:00:00Z"
  }
}
```

### 2.2 获取任务拆解历史

```http
GET /ai/history?page=1&limit=10&type=all
```

**查询参数**:
- `page`: 页码（默认1）
- `limit`: 每页数量（默认10，最大50）
- `type`: 任务类型过滤（可选）

**响应**:
```json
{
  "success": true,
  "data": {
    "tasks": [
      {
        "taskId": "uuid",
        "originalTask": "string",
        "taskType": "string",
        "totalSteps": 6,
        "createdAt": "2024-01-01T12:00:00Z",
        "isAddedToTodo": true
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalItems": 50,
      "hasNext": true,
      "hasPrev": false
    }
  }
}
```

## 3. 待办事项模块

### 3.1 添加待办事项

```http
POST /todos
```

**请求体**:
```json
{
  "title": "string",
  "description": "string", // 可选
  "steps": [
    {
      "description": "string",
      "estimatedTime": 5,
      "order": 1
    }
  ],
  "priority": "low|medium|high",
  "dueDate": "2024-01-01", // 可选
  "fromAiTask": "uuid" // 可选，来源AI任务ID
}
```

**响应**:
```json
{
  "success": true,
  "data": {
    "todoId": "uuid",
    "title": "string",
    "description": "string",
    "steps": [
      {
        "stepId": "uuid",
        "description": "string",
        "completed": false,
        "completedAt": null,
        "estimatedTime": 5,
        "order": 1
      }
    ],
    "priority": "medium",
    "status": "pending",
    "progress": 0,
    "createdAt": "2024-01-01T12:00:00Z",
    "dueDate": "2024-01-01"
  }
}
```

### 3.2 获取待办事项列表

```http
GET /todos?status=all&page=1&limit=20&date=2024-01-01
```

**查询参数**:
- `status`: 状态过滤（all|pending|completed|overdue）
- `page`: 页码
- `limit`: 每页数量
- `date`: 日期过滤（可选）

**响应**:
```json
{
  "success": true,
  "data": {
    "todos": [
      {
        "todoId": "uuid",
        "title": "string",
        "description": "string",
        "priority": "medium",
        "status": "pending",
        "progress": 30,
        "totalSteps": 6,
        "completedSteps": 2,
        "createdAt": "2024-01-01T12:00:00Z",
        "dueDate": "2024-01-01",
        "isOverdue": false
      }
    ],
    "summary": {
      "total": 10,
      "pending": 6,
      "completed": 3,
      "overdue": 1
    }
  }
}
```

### 3.3 更新待办事项

```http
PUT /todos/{todoId}
```

**请求体**:
```json
{
  "title": "string", // 可选
  "description": "string", // 可选
  "priority": "low|medium|high", // 可选
  "dueDate": "2024-01-01", // 可选
  "status": "pending|completed|cancelled" // 可选
}
```

### 3.4 标记步骤完成

```http
PUT /todos/{todoId}/steps/{stepId}
```

**请求体**:
```json
{
  "completed": true
}
```

**响应**:
```json
{
  "success": true,
  "data": {
    "stepId": "uuid",
    "completed": true,
    "completedAt": "2024-01-01T12:00:00Z",
    "todoProgress": 50 // 整个任务的完成进度
  }
}
```

### 3.5 删除待办事项

```http
DELETE /todos/{todoId}
```

## 4. 用户设置模块

### 4.1 获取用户设置

```http
GET /user/settings
```

**响应**:
```json
{
  "success": true,
  "data": {
    "userId": "uuid",
    "username": "string",
    "email": "string",
    "theme": "business|cute",
    "preferences": {
      "defaultTaskType": "work",
      "notifications": {
        "email": true,
        "push": false,
        "reminders": true
      },
      "privacy": {
        "dataSync": true,
        "analytics": false
      }
    },
    "subscription": {
      "plan": "free|premium",
      "expiresAt": "2024-12-31T23:59:59Z",
      "features": ["ai_decompose", "unlimited_todos"]
    }
  }
}
```

### 4.2 更新用户设置

```http
PUT /user/settings
```

**请求体**:
```json
{
  "theme": "business|cute", // 可选
  "preferences": {
    "defaultTaskType": "work",
    "notifications": {
      "email": true,
      "push": false,
      "reminders": true
    }
  }
}
```

### 4.3 更新用户信息

```http
PUT /user/profile
```

**请求体**:
```json
{
  "username": "string", // 可选
  "email": "string", // 可选
  "currentPassword": "string", // 修改密码时必需
  "newPassword": "string" // 可选
}
```

## 5. 统计分析模块

### 5.1 获取用户统计

```http
GET /stats/overview?period=week
```

**查询参数**:
- `period`: 统计周期（day|week|month|year）

**响应**:
```json
{
  "success": true,
  "data": {
    "period": "week",
    "dateRange": {
      "start": "2024-01-01",
      "end": "2024-01-07"
    },
    "tasks": {
      "totalDecomposed": 15,
      "totalCompleted": 12,
      "completionRate": 80
    },
    "todos": {
      "totalCreated": 25,
      "totalCompleted": 20,
      "completionRate": 80,
      "averageCompletionTime": 45 // 分钟
    },
    "productivity": {
      "mostProductiveDay": "Monday",
      "mostProductiveHour": 14,
      "streakDays": 5
    },
    "categories": [
      {
        "type": "work",
        "count": 8,
        "completionRate": 85
      }
    ]
  }
}
```

## 6. 反馈建议模块

### 6.1 提交反馈

```http
POST /feedback
```

**请求体**:
```json
{
  "type": "功能建议|界面优化|问题反馈|其他建议",
  "content": "string",
  "contact": "string", // 可选
  "priority": "low|medium|high",
  "attachments": ["url1", "url2"] // 可选
}
```

**响应**:
```json
{
  "success": true,
  "data": {
    "feedbackId": "uuid",
    "status": "submitted",
    "createdAt": "2024-01-01T12:00:00Z"
  }
}
```

### 6.2 获取常见问题

```http
GET /faq?category=all
```

**响应**:
```json
{
  "success": true,
  "data": {
    "categories": [
      {
        "name": "使用指南",
        "faqs": [
          {
            "question": "如何使用AI任务拆解？",
            "answer": "在AI助手页面输入你的任务描述...",
            "order": 1
          }
        ]
      }
    ]
  }
}
```

## 7. 数据同步模块

### 7.1 同步本地数据

```http
POST /sync/upload
```

**请求体**:
```json
{
  "todos": [
    {
      "localId": "string",
      "title": "string",
      "steps": [],
      "createdAt": "2024-01-01T12:00:00Z",
      "lastModified": "2024-01-01T12:00:00Z"
    }
  ],
  "settings": {
    "theme": "business",
    "lastModified": "2024-01-01T12:00:00Z"
  }
}
```

### 7.2 下载云端数据

```http
GET /sync/download?lastSync=2024-01-01T12:00:00Z
```

## 状态码说明

| 状态码 | 说明 |
|--------|------|
| 200 | 请求成功 |
| 201 | 创建成功 |
| 400 | 请求参数错误 |
| 401 | 未授权/Token无效 |
| 403 | 权限不足 |
| 404 | 资源不存在 |
| 429 | 请求频率限制 |
| 500 | 服务器内部错误 |

## 安全考虑

1. **认证**: 所有需要用户身份的接口都需要JWT Token
2. **HTTPS**: 生产环境强制使用HTTPS
3. **频率限制**: 防止API滥用
4. **数据验证**: 严格的输入验证和过滤
5. **敏感信息**: 密码等敏感信息加密存储

## 版本控制

- 当前版本: v1
- 版本策略: 语义化版本控制
- 向后兼容: 保证同一大版本内的向后兼容性

---

**注意**: 此API规范为初版，在开发过程中可能会根据实际需求进行调整和完善。
