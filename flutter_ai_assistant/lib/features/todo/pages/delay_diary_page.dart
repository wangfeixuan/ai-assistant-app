import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/delay_diary.dart';
import '../providers/todo_provider.dart';

/// 拖延日记页面
class DelayDiaryPage extends StatefulWidget {
  const DelayDiaryPage({super.key});

  @override
  State<DelayDiaryPage> createState() => _DelayDiaryPageState();
}

class _DelayDiaryPageState extends State<DelayDiaryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('拖延日记'),
        backgroundColor: Colors.deepPurple.shade50,
        foregroundColor: Colors.deepPurple.shade700,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepPurple.shade700,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.deepPurple.shade400,
          tabs: const [
            Tab(icon: Icon(Icons.book), text: '日记记录'),
            Tab(icon: Icon(Icons.analytics), text: '分析统计'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _DiaryListTab(),
          _AnalyticsTab(),
        ],
      ),
    );
  }
}

/// 日记记录标签页
class _DiaryListTab extends StatelessWidget {
  const _DiaryListTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        final diaryEntries = todoProvider.delayDiaryEntries;
        
        if (diaryEntries.isEmpty) {
          return _buildEmptyState();
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: diaryEntries.length,
          itemBuilder: (context, index) {
            final entry = diaryEntries[index];
            return _DiaryEntryCard(entry: entry);
          },
        );
      },
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sentiment_satisfied_alt,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无拖延记录',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '保持良好的习惯！',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

/// 日记条目卡片
class _DiaryEntryCard extends StatelessWidget {
  final DelayDiaryEntry entry;
  
  const _DiaryEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 任务名称和日期
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    entry.taskName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildDelayLevelChip(entry.delayLevel),
              ],
            ),
            const SizedBox(height: 8),
            
            // 日期和拖延天数
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  _formatDate(entry.delayDate),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.schedule, size: 16, color: Colors.orange.shade600),
                const SizedBox(width: 4),
                Text(
                  '拖延 ${entry.delayDays} 天',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            if (entry.primaryReason.isNotEmpty || entry.secondaryReason.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildReasonSection(entry),
            ],
            
            if (entry.reflection.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildReflectionSection(entry),
            ],
            
            if (entry.isResolved) ...[
              const SizedBox(height: 12),
              _buildResolvedSection(entry),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildDelayLevelChip(DelayLevel level) {
    Color color;
    String text;
    
    switch (level) {
      case DelayLevel.light:
        color = Colors.green;
        text = '轻度';
        break;
      case DelayLevel.moderate:
        color = Colors.orange;
        text = '中度';
        break;
      case DelayLevel.severe:
        color = Colors.red;
        text = '严重';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  Widget _buildReasonSection(DelayDiaryEntry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.psychology, size: 16, color: Colors.blue.shade600),
            const SizedBox(width: 4),
            Text(
              '拖延原因',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.blue.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (entry.primaryReason.isNotEmpty)
          Text('主要原因：${entry.primaryReason}', style: const TextStyle(fontSize: 14)),
        if (entry.secondaryReason.isNotEmpty)
          Text('次要原因：${entry.secondaryReason}', style: const TextStyle(fontSize: 14)),
        if (entry.customReason.isNotEmpty)
          Text('其他：${entry.customReason}', style: const TextStyle(fontSize: 14)),
      ],
    );
  }
  
  Widget _buildReflectionSection(DelayDiaryEntry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb, size: 16, color: Colors.amber.shade600),
            const SizedBox(width: 4),
            Text(
              '反思总结',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.amber.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          entry.reflection,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
  
  Widget _buildResolvedSection(DelayDiaryEntry entry) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '已解决',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.green.shade700,
                  ),
                ),
                if (entry.resolvedAt != null)
                  Text(
                    '解决时间：${_formatDate(entry.resolvedAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// 分析统计标签页
class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        final analytics = todoProvider.getDelayAnalytics();
        
        if (analytics.totalDelayDays == 0) {
          return _buildEmptyAnalytics();
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewCard(analytics),
              const SizedBox(height: 16),
              _buildReasonAnalysisCard(analytics),
              const SizedBox(height: 16),
              _buildSuggestionsCard(analytics),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildEmptyAnalytics() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无分析数据',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOverviewCard(DelayAnalytics analytics) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  '总体概览',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '总拖延天数',
                    '${analytics.totalDelayDays}',
                    Colors.orange,
                    Icons.schedule,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '拖延任务数',
                    '${analytics.totalTasks}',
                    Colors.red,
                    Icons.task_alt,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '平均拖延',
                    '${(analytics.totalDelayDays / analytics.totalTasks).toStringAsFixed(1)} 天',
                    Colors.purple,
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '最常拖延',
                    analytics.mostDelayedTaskType.isEmpty ? '无' : analytics.mostDelayedTaskType,
                    Colors.indigo,
                    Icons.category,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color.shade600, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildReasonAnalysisCard(DelayAnalytics analytics) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(
                  '原因分析',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...analytics.reasonFrequency.entries.map((entry) {
              final percentage = (entry.value / analytics.totalTasks * 100).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(entry.key, style: const TextStyle(fontSize: 14)),
                    ),
                    Expanded(
                      flex: 2,
                      child: LinearProgressIndicator(
                        value: entry.value / analytics.totalTasks,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(Colors.green.shade400),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$percentage%', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSuggestionsCard(DelayAnalytics analytics) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber.shade600),
                const SizedBox(width: 8),
                Text(
                  '改进建议',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...analytics.suggestions.map((suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.arrow_right,
                    color: Colors.amber.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}
