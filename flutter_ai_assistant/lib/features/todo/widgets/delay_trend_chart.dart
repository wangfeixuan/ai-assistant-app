import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/delay_diary.dart';

/// 拖延趋势图表组件
class DelayTrendChart extends StatelessWidget {
  final DelayAnalytics analytics;
  final String chartType; // 'daily', 'weekly', 'hourly'
  
  const DelayTrendChart({
    super.key,
    required this.analytics,
    this.chartType = 'daily',
  });

  @override
  Widget build(BuildContext context) {
    switch (chartType) {
      case 'daily':
        return _buildDailyTrendChart();
      case 'weekly':
        return _buildWeeklyTrendChart();
      case 'hourly':
        return _buildHourlyTrendChart();
      default:
        return _buildDailyTrendChart();
    }
  }

  /// 每日拖延趋势图
  Widget _buildDailyTrendChart() {
    if (analytics.delayTrendData.isEmpty) {
      return _buildEmptyChart('暂无每日趋势数据');
    }

    final spots = <FlSpot>[];
    final sortedDates = analytics.delayTrendData.keys.toList()..sort();
    
    for (int i = 0; i < sortedDates.length && i < 30; i++) {
      final dateStr = sortedDates[i];
      final count = analytics.delayTrendData[dateStr] ?? 0;
      spots.add(FlSpot(i.toDouble(), count.toDouble()));
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 0.5,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (spots.length / 7).ceil().toDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < sortedDates.length) {
                    final date = DateTime.parse(sortedDates[index]);
                    return Text(
                      '${date.month}/${date.day}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: LinearGradient(
                colors: [
                  Colors.red[400]!,
                  Colors.orange[400]!,
                ],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.red[400]!,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.red[100]!.withOpacity(0.3),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: 0,
          maxY: (spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 1),
        ),
      ),
    );
  }

  /// 每周拖延模式图
  Widget _buildWeeklyTrendChart() {
    if (analytics.weeklyDelayPattern.isEmpty) {
      return _buildEmptyChart('暂无每周趋势数据');
    }

    final spots = <FlSpot>[];
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    
    for (int i = 1; i <= 7; i++) {
      final count = analytics.weeklyDelayPattern[i] ?? 0;
      spots.add(FlSpot(i.toDouble(), count.toDouble()));
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 1),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.black87,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${weekdays[group.x.toInt() - 1]}\n${rod.toY.toInt()}次',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt() - 1;
                  if (index >= 0 && index < weekdays.length) {
                    return Text(
                      weekdays[index],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: spots.map((spot) {
            return BarChartGroupData(
              x: spot.x.toInt(),
              barRods: [
                BarChartRodData(
                  toY: spot.y,
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange[300]!,
                      Colors.red[400]!,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 每小时拖延模式图
  Widget _buildHourlyTrendChart() {
    if (analytics.hourlyDelayPattern.isEmpty) {
      return _buildEmptyChart('暂无每小时趋势数据');
    }

    final spots = <FlSpot>[];
    final productivitySpots = <FlSpot>[];
    
    for (int i = 0; i < 24; i++) {
      final delayCount = analytics.hourlyDelayPattern[i] ?? 0;
      final productivity = analytics.bestProductiveTime.hourlyProductivity[i] ?? 1.0;
      spots.add(FlSpot(i.toDouble(), delayCount.toDouble()));
      productivitySpots.add(FlSpot(i.toDouble(), productivity * 10)); // 放大10倍便于显示
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 0.5,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${(value / 10).toStringAsFixed(1)}',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Colors.red[600],
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 3,
                getTitlesWidget: (value, meta) {
                  final hour = value.toInt();
                  if (hour >= 0 && hour < 24) {
                    return Text(
                      '${hour.toString().padLeft(2, '0')}:00',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            // 拖延次数线
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.red[400],
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: false,
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.red[100]!.withOpacity(0.2),
              ),
            ),
            // 生产力指数线
            LineChartBarData(
              spots: productivitySpots,
              isCurved: true,
              color: Colors.green[400],
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: false,
              ),
              dashArray: [5, 5], // 虚线
            ),
          ],
          minX: 0,
          maxX: 23,
          minY: 0,
          maxY: (spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 2).clamp(10, double.infinity),
        ),
      ),
    );
  }

  /// 空状态图表
  Widget _buildEmptyChart(String message) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 拖延趋势图表页面
class DelayTrendChartPage extends StatefulWidget {
  final DelayAnalytics analytics;
  
  const DelayTrendChartPage({
    super.key,
    required this.analytics,
  });

  @override
  State<DelayTrendChartPage> createState() => _DelayTrendChartPageState();
}

class _DelayTrendChartPageState extends State<DelayTrendChartPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('拖延趋势分析'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.orange[600],
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.orange[600],
          tabs: const [
            Tab(text: '每日趋势'),
            Tab(text: '每周模式'),
            Tab(text: '小时分析'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyTrendPage(),
          _buildWeeklyTrendPage(),
          _buildHourlyTrendPage(),
        ],
      ),
    );
  }

  Widget _buildDailyTrendPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('每日拖延趋势', '过去30天的拖延情况'),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: DelayTrendChart(
              analytics: widget.analytics,
              chartType: 'daily',
            ),
          ),
          const SizedBox(height: 24),
          _buildTrendInsights(),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrendPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('每周拖延模式', '一周内各天的拖延分布'),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: DelayTrendChart(
              analytics: widget.analytics,
              chartType: 'weekly',
            ),
          ),
          const SizedBox(height: 24),
          _buildWeeklyInsights(),
        ],
      ),
    );
  }

  Widget _buildHourlyTrendPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('小时拖延分析', '24小时内的拖延模式和生产力对比'),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: DelayTrendChart(
              analytics: widget.analytics,
              chartType: 'hourly',
            ),
          ),
          const SizedBox(height: 16),
          _buildChartLegend(),
          const SizedBox(height: 24),
          _buildHourlyInsights(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildChartLegend() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLegendItem('拖延次数', Colors.red[400]!, false),
            _buildLegendItem('生产力指数', Colors.green[400]!, true),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDashed) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
          child: isDashed
              ? CustomPaint(
                  painter: DashLinePainter(color: color),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendInsights() {
    final insights = <String>[];
    
    // 分析趋势
    final totalDays = widget.analytics.delayTrendData.length;
    if (totalDays > 0) {
      final avgDelay = widget.analytics.totalDelayTasks / totalDays;
      insights.add('平均每天拖延 ${avgDelay.toStringAsFixed(1)} 个任务');
      
      if (widget.analytics.averageDelayDays > 3) {
        insights.add('平均拖延时长较长，建议加强时间管理');
      }
    }

    return _buildInsightCard('趋势洞察', insights);
  }

  Widget _buildWeeklyInsights() {
    final insights = <String>[];
    final pattern = widget.analytics.weeklyDelayPattern;
    
    if (pattern.isNotEmpty) {
      final bestDay = pattern.entries.reduce((a, b) => a.value < b.value ? a : b);
      final worstDay = pattern.entries.reduce((a, b) => a.value > b.value ? a : b);
      
      final weekdays = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      insights.add('${weekdays[bestDay.key]} 是你拖延最少的一天');
      insights.add('${weekdays[worstDay.key]} 是你最容易拖延的一天');
      
      if (worstDay.key == 1) {
        insights.add('周一拖延较多，可能是周末综合症的影响');
      }
      if (worstDay.key == 5) {
        insights.add('周五拖延较多，可能受到周末期待的影响');
      }
    }

    return _buildInsightCard('每周模式洞察', insights);
  }

  Widget _buildHourlyInsights() {
    final insights = <String>[];
    final bestTime = widget.analytics.bestProductiveTime;
    
    insights.add('${bestTime.bestHour}:00 是你效率最高的时间');
    insights.add('${bestTime.worstHour}:00 是你最容易拖延的时间');
    
    if (bestTime.bestHour >= 6 && bestTime.bestHour <= 10) {
      insights.add('你是典型的早晨型人格，建议将重要任务安排在上午');
    } else if (bestTime.bestHour >= 14 && bestTime.bestHour <= 18) {
      insights.add('你在下午效率较高，可以在此时处理核心工作');
    } else if (bestTime.bestHour >= 20) {
      insights.add('你是夜猫子类型，但要注意不要过度熬夜');
    }

    return _buildInsightCard('时间模式洞察', insights);
  }

  Widget _buildInsightCard(String title, List<String> insights) {
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
                Icon(Icons.lightbulb, color: Colors.amber[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...insights.map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: Colors.amber[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      insight,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                      ),
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

/// 自定义虚线绘制器
class DashLinePainter extends CustomPainter {
  final Color color;
  
  const DashLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 3.0;
    const dashSpace = 2.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}