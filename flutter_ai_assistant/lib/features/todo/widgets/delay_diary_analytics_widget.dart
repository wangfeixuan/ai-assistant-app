import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/delay_diary.dart';
import '../providers/todo_provider.dart';
import 'delay_trend_chart.dart';

/// 拖延分析主界面组件
class DelayDiaryAnalyticsWidget extends StatefulWidget {
  const DelayDiaryAnalyticsWidget({super.key});

  @override
  State<DelayDiaryAnalyticsWidget> createState() => _DelayDiaryAnalyticsWidgetState();
}

class _DelayDiaryAnalyticsWidgetState extends State<DelayDiaryAnalyticsWidget> {
  DelayAnalytics? _analytics;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      final todoProvider = Provider.of<TodoProvider>(context, listen: false);
      final entries = await todoProvider.getDelayDiaryEntries();
      
      setState(() {
        _analytics = DelayAnalytics.fromEntries(entries);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载分析数据失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_analytics == null || _analytics!.totalDelayTasks == 0) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCards(),
          const SizedBox(height: 24),
          _buildQuickChart(),
          const SizedBox(height: 24),
          _buildTaskTypeAnalysis(),
          const SizedBox(height: 24),
          _buildTimeAnalysis(),
          const SizedBox(height: 24),
          _buildImprovementSuggestions(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '还没有拖延记录',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '完成一些任务后，这里将显示详细的拖延分析',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '拖延概况',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '总拖延任务',
                _analytics!.totalDelayTasks.toString(),
                Icons.task_alt,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '总拖延天数',
                _analytics!.totalDelayDays.toString(),
                Icons.calendar_today,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '平均拖延',
                '${_analytics!.averageDelayDays.toStringAsFixed(1)} 天',
                Icons.schedule,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '最佳时段',
                '${_analytics!.bestProductiveTime.bestHour}:00',
                Icons.access_time,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '拖延趋势',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DelayTrendChartPage(
                      analytics: _analytics!,
                    ),
                  ),
                );
              },
              child: const Text('查看详细'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: DelayTrendChart(
            analytics: _analytics!,
            chartType: 'daily',
          ),
        ),
      ],
    );
  }

  Widget _buildTaskTypeAnalysis() {
    if (_analytics!.taskTypeAnalysis.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '任务类型分析',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._analytics!.taskTypeAnalysis.take(3).map((analysis) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getTaskTypeColor(analysis.taskType).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          analysis.taskType,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getTaskTypeColor(analysis.taskType),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '拖延 ${analysis.delayCount} 次',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '平均拖延 ${analysis.averageDelayDays.toStringAsFixed(1)} 天',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: analysis.commonReasons.take(2).map((reason) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          DelayDiaryEntry._getReasonDescription(reason),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Color _getTaskTypeColor(String taskType) {
    switch (taskType) {
      case '学习类': return Colors.blue;
      case '工作类': return Colors.green;
      case '运动类': return Colors.orange;
      case '生活类': return Colors.purple;
      case '创作类': return Colors.teal;
      default: return Colors.grey;
    }
  }

  Widget _buildTimeAnalysis() {
    final bestTime = _analytics!.bestProductiveTime;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '时间模式分析',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTimeInfoRow(
                  '最佳工作时间',
                  '${bestTime.bestHour}:00',
                  Icons.wb_sunny,
                  Colors.green,
                ),
                const Divider(),
                _buildTimeInfoRow(
                  '易拖延时间',
                  '${bestTime.worstHour}:00',
                  Icons.nights_stay,
                  Colors.red,
                ),
                const Divider(),
                _buildTimeInfoRow(
                  '最佳工作日',
                  _getWeekdayName(bestTime.bestWeekday),
                  Icons.calendar_today,
                  Colors.blue,
                ),
                const Divider(),
                _buildTimeInfoRow(
                  '易拖延工作日',
                  _getWeekdayName(bestTime.worstWeekday),
                  Icons.event_busy,
                  Colors.orange,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInfoRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getWeekdayName(int weekday) {
    const weekdays = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[weekday];
  }

  Widget _buildImprovementSuggestions() {
    if (_analytics!.improvementSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '改进建议',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.amber[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '智能建议',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._analytics!.improvementSuggestions.take(5).map((suggestion) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '💡 ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.amber[600],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DelayTrendChartPage(
                    analytics: _analytics!,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.analytics),
            label: const Text('查看详细图表'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loadAnalytics,
                icon: const Icon(Icons.refresh),
                label: const Text('刷新数据'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _showExportDialog(context);
                },
                icon: const Icon(Icons.download),
                label: const Text('导出报告'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出分析报告'),
        content: const Text('此功能将在未来版本中实现，敬请期待！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

/// 拖延分析页面
class DelayAnalyticsPage extends StatelessWidget {
  const DelayAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('拖延分析'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: const DelayDiaryAnalyticsWidget(),
    );
  }
}