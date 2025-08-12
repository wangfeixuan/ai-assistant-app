import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/pomodoro_provider.dart';
import '../models/achievement.dart';

/// 番茄钟统计和成就页面
class PomodoroStatsScreen extends StatefulWidget {
  const PomodoroStatsScreen({super.key});

  @override
  State<PomodoroStatsScreen> createState() => _PomodoroStatsScreenState();
}

class _PomodoroStatsScreenState extends State<PomodoroStatsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
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
        title: const Text('统计与成就'),
      ),
      body: Column(
        children: [
          // 自定义Tab栏
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).appBarTheme.backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildCustomTab(0, Icons.today, '今日'),
                _buildCustomTab(1, Icons.history, '历史'),
                _buildCustomTab(2, Icons.emoji_events, '成就'),
              ],
            ),
          ),
          // Tab内容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTodayTab(),
                _buildHistoryTab(),
                _buildAchievementsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTab(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
        },
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected 
                    ? Theme.of(context).primaryColor 
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected 
                    ? Colors.white  // 选中时使用白色图标
                    : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected 
                      ? Colors.white  // 选中时使用白色文字
                      : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 今日标签页
  Widget _buildTodayTab() {
    return Consumer<PomodoroProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 今日统计卡片
              Text(
                '今日专注',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      '完成番茄钟',
                      provider.getTodayCompletedCount().toString(),
                      Icons.timer,
                      const Color(0xFF90EE90), // 抹茶绿
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      '专注时长',
                      provider.getTodayActualFocusTimeFormatted(),
                      Icons.access_time,
                      const Color(0xFF87CEEB), // 天空蓝
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      '连续打卡',
                      '${provider.streakDays}天',
                      Icons.local_fire_department,
                      const Color(0xFFF8BBD9), // 荔枝粉
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      '今日目标',
                      '${provider.getTodayCompletedCount()}/8',
                      Icons.flag,
                      const Color(0xFFF0E68C), // 柠檬黄
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 今日时间分布
              Text(
                '今日时间分布',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildTodayTimeChart(provider),

              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  /// 历史标签页
  Widget _buildHistoryTab() {
    return Consumer<PomodoroProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 历史统计概览
              Text(
                '历史统计',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      '总计番茄钟',
                      provider.completedPomodoros.toString(),
                      Icons.check_circle,
                      const Color(0xFF87CEEB), // 天空蓝
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      '本周完成',
                      provider.getWeekCompletedCount().toString(),
                      Icons.date_range,
                      const Color(0xFF90EE90), // 抹茶绿
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      '最长连续',
                      '${provider.getMaxStreakDays()}天',
                      Icons.trending_up,
                      const Color(0xFFF8BBD9), // 荔枝粉
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      '平均每日',
                      '${provider.getAverageDailyCount().toStringAsFixed(1)}个',
                      Icons.analytics,
                      const Color(0xFFF0E68C), // 柠檬黄
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 本周趋势图表
              Text(
                '本周趋势',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildWeeklyTrendChart(provider),

              const SizedBox(height: 24),

              // 月度统计
              Text(
                '月度统计',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildMonthlyChart(provider),

              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  /// 报表标签页
  Widget _buildReportsTab() {
    return Consumer<PomodoroProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 时间段效率热力图
              Text(
                '24小时效率热力图',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildHourlyHeatmap(provider),

              const SizedBox(height: 24),

              // 月度趋势
              Text(
                '月度趋势',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildMonthlyChart(provider),
            ],
          ),
        );
      },
    );
  }

  /// 成就标签页
  Widget _buildAchievementsTab() {
    return Consumer<PomodoroProvider>(
      builder: (context, provider, child) {
        final achievements = provider.getAllAchievements();
        final unlockedAchievements = achievements.where((a) => a.isUnlocked).toList();
        final lockedAchievements = achievements.where((a) => !a.isUnlocked).toList();
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 成就统计概览
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.1),
                      Theme.of(context).primaryColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 48,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '成就进度',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${unlockedAchievements.length}/${achievements.length} 已解锁',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: achievements.isEmpty ? 0 : unlockedAchievements.length / achievements.length,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 已解锁成就
              if (unlockedAchievements.isNotEmpty) ...[
                Text(
                  '已解锁成就 (${unlockedAchievements.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...unlockedAchievements.map((achievement) => 
                  _buildAchievementCard(achievement, isUnlocked: true)
                ).toList(),
              ],
              
              const SizedBox(height: 16),
              
              // 未解锁成就
              if (lockedAchievements.isNotEmpty) ...[
                Text(
                  '待解锁成就 (${lockedAchievements.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 12),
                ...lockedAchievements.map((achievement) => 
                  _buildAchievementCard(achievement, isUnlocked: false)
                ).toList(),
              ],
              
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  /// 构建统计卡片 - 美化版本
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建本周趋势图表 - 美化版本
  Widget _buildWeeklyTrendChart(PomodoroProvider provider) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Container(
      height: 200, // 增加总体容器高度，为图表留更多空间
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.08),
            primaryColor.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '本周趋势',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildWeeklyBarChart(provider.getWeeklyTrendData(), primaryColor),
          ),
        ],
      ),
    );
  }
  
  /// 构建本周柱状图
  Widget _buildWeeklyBarChart(List<int> weeklyData, Color primaryColor) {
    final weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final maxValue = weeklyData.isNotEmpty ? weeklyData.reduce((a, b) => a > b ? a : b) : 1;
    
    return Container(
      height: 140, // 增加容器高度，给所有内容留够空间
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final count = weeklyData[index];
          final height = maxValue > 0 ? (count / maxValue * 50).clamp(8.0, 50.0) : 8.0; // 进一步减小柱状图高度
          
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 数值显示 - 预留更多空间
                  Container(
                    height: 18, // 增加数值显示区域高度
                    alignment: Alignment.center,
                    child: Text(
                      count > 0 ? count.toString() : '',
                      style: TextStyle(
                        fontSize: 10, // 稍微增大字体以保证可读性
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4), // 适当间距
                  // 柱状图 - 减小高度
                  Container(
                    width: 18, // 稍微减小宽度
                    height: height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          primaryColor.withOpacity(0.8),
                          primaryColor.withOpacity(0.4),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  ),
                  const SizedBox(height: 6), // 适当间距
                  // 星期标签 - 预留更多空间
                  Container(
                    height: 16, // 增加标签区域高度
                    alignment: Alignment.center,
                    child: Text(
                      weekDays[index],
                      style: TextStyle(
                        fontSize: 10, // 稍微增大字体以保证可读性
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  /// 构建24小时效率热力图
  Widget _buildHourlyHeatmap(PomodoroProvider provider) {
    final hourlyData = provider.getHourlyEfficiencyData();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // 热力图标题
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0时',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                '12时',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                '24时',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // 热力图网格
          Wrap(
            spacing: 2,
            runSpacing: 2,
            children: List.generate(24, (hour) {
              final count = hourlyData[hour] ?? 0;
              final intensity = count > 0 ? (count / 10).clamp(0.1, 1.0) : 0.0;
              
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: intensity > 0 
                      ? Theme.of(context).colorScheme.primary.withOpacity(intensity)
                      : Theme.of(context).colorScheme.outline.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 8),
          
          // 图例
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              const Text('低', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 12),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              const Text('中', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 12),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              const Text('高', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建月度图表
  Widget _buildMonthlyChart(PomodoroProvider provider) {
    final monthlyData = provider.getMonthlyData();
    final now = DateTime.now();
    final monthName = '${now.year}年${now.month}月';
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // 标题和统计信息
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${provider.getMonthCompletedCount()}个番茄钟',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 月度统计卡片
          Expanded(
            child: Row(
              children: [
                // 本月完成数
                Expanded(
                  child: _buildMonthlyStatCard(
                    '本月完成',
                    provider.getMonthCompletedCount().toString(),
                    Icons.calendar_today,
                    const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 12),
                // 专注时长
                Expanded(
                  child: _buildMonthlyStatCard(
                    '专注时长',
                    _formatDuration(provider.getMonthActualFocusTime()),
                    Icons.access_time,
                    const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 12),
                // 活跃天数
                Expanded(
                  child: _buildMonthlyStatCard(
                    '活跃天数',
                    '${monthlyData.values.where((count) => count > 0).length}天',
                    Icons.event_available,
                    const Color(0xFFFF9800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建月度统计小卡片
  Widget _buildMonthlyStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// 格式化时长显示
  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}秒';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '${minutes}分钟';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      if (minutes > 0) {
        return '${hours}小时${minutes}分';
      } else {
        return '${hours}小时';
      }
    }
  }

  /// 构建快速操作
  Widget _buildQuickActions(PomodoroProvider provider) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => provider.resetStats(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重置数据'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.red,
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建成就卡片 - 美观设计版本
  Widget _buildAchievementCard(Achievement achievement, {required bool isUnlocked}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isUnlocked 
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.amber.withOpacity(0.1),
                    Colors.orange.withOpacity(0.05),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey.withOpacity(0.05),
                    Colors.grey.withOpacity(0.02),
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked 
                ? Colors.amber.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // 成就图标
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isUnlocked 
                    ? Colors.amber.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                achievement.icon,
                color: isUnlocked 
                    ? Colors.amber[700]
                    : Colors.grey[400],
                size: 28,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // 成就信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isUnlocked 
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUnlocked 
                          ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  if (isUnlocked && achievement.unlockedAt.year > 1970) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '解锁于 ${_formatUnlockTime(achievement.unlockedAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // 解锁状态指示器
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isUnlocked 
                    ? Colors.green.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUnlocked ? Icons.check_circle : Icons.lock_outline,
                color: isUnlocked ? Colors.green : Colors.grey[400],
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 格式化解锁时间
  String _formatUnlockTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
  
  /// 构建今日时间分布图
  Widget _buildTodayTimeChart(PomodoroProvider provider) {
    return Container(
      height: 240, // 增加容器高度
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            '今日专注时间分布',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8), // 添加水平内边距
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 改为均匀分布
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildTimeBar('上午', provider.getMorningCount(), const Color(0xFF87CEEB)),
                  _buildTimeBar('下午', provider.getAfternoonCount(), const Color(0xFF90EE90)),
                  _buildTimeBar('晚上', provider.getEveningCount(), const Color(0xFFF8BBD9)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建时间条
  Widget _buildTimeBar(String label, int count, Color color) {
    // 调整最大高度，留出空间给数字和标签
    final maxHeight = 100.0;
    final height = count > 0 ? (count / 10 * maxHeight).clamp(15.0, maxHeight) : 15.0;
    
    return Flexible(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 数字显示
          Container(
            height: 20, // 固定高度
            alignment: Alignment.center,
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // 柱状图
          Container(
            width: 45,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  color.withOpacity(0.9),
                  color.withOpacity(0.6),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 标签
          Container(
            height: 20, // 固定高度
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
  

}

/// 显示统计页面的辅助函数
void showPomodoroStats(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => const PomodoroStatsScreen(),
    ),
  );
}