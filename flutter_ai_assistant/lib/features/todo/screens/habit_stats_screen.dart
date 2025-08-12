import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';

/// 习惯统计界面
class HabitStatsScreen extends StatelessWidget {
  const HabitStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('习惯统计'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<TodoProvider>(
        builder: (context, todoProvider, child) {
          final completionRates = todoProvider.getHabitCompletionRates();
          final habitDetails = todoProvider.getHabitDetails();
          
          if (completionRates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无习惯数据',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '创建重复任务后完成几次即可查看统计',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: completionRates.length,
            itemBuilder: (context, index) {
              final entry = completionRates.entries.elementAt(index);
              final habitName = entry.key;
              final completionRate = entry.value;
              final percentage = (completionRate * 100).toInt();
              
              // 获取详细信息
              final details = habitDetails[habitName] ?? {'completed': 0, 'goalDays': 7, 'total': 0};
              final completedDays = details['completed']!;
              final goalDays = details['goalDays']!;
              final totalInstances = details['total']!;
              
              // 根据完成率确定颜色
              Color rateColor = Colors.red;
              if (completionRate >= 0.8) {
                rateColor = Colors.green;
              } else if (completionRate >= 0.6) {
                rateColor = Colors.orange;
              } else if (completionRate >= 0.3) {
                rateColor = Colors.yellow[700]!;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 习惯名称和完成率
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              habitName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: rateColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$percentage%',
                              style: TextStyle(
                                color: rateColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 进度条
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '完成进度',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                  Text(
                                    '$completedDays/$goalDays 天 (共$totalInstances次任务)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _getCompletionText(completionRate),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: completionRate,
                            backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(rateColor),
                            minHeight: 8,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 评价和建议
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.onSurface.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _getStatusIcon(completionRate),
                                  size: 16,
                                  color: rateColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getStatusText(completionRate),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: rateColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getSuggestionText(completionRate),
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getCompletionText(double rate) {
    if (rate >= 0.9) return '优秀';
    if (rate >= 0.7) return '良好';
    if (rate >= 0.5) return '一般';
    return '需要改进';
  }

  IconData _getStatusIcon(double rate) {
    if (rate >= 0.8) return Icons.emoji_events;
    if (rate >= 0.6) return Icons.thumb_up;
    if (rate >= 0.3) return Icons.trending_up;
    return Icons.trending_down;
  }

  String _getStatusText(double rate) {
    if (rate >= 0.9) return '习惯养成极佳！';
    if (rate >= 0.8) return '习惯养成良好';
    if (rate >= 0.6) return '习惯正在形成';
    if (rate >= 0.3) return '需要更多坚持';
    return '习惯需要重建';
  }

  String _getSuggestionText(double rate) {
    if (rate >= 0.9) {
      return '恭喜！您已经成功养成了这个习惯，请继续保持。';
    } else if (rate >= 0.8) {
      return '您的习惯养成情况很好，再坚持一下就能完全固化。';
    } else if (rate >= 0.6) {
      return '习惯正在逐步形成，试着设置提醒来帮助坚持。';
    } else if (rate >= 0.3) {
      return '完成率偏低，建议降低任务难度或增加奖励机制。';
    } else {
      return '建议重新评估任务的可行性，或者寻找更合适的时间和方法。';
    }
  }
}