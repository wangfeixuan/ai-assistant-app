import 'package:flutter/material.dart';
import '../../models/procrastination_diary.dart';
import '../../services/procrastination_service.dart';

class ProcrastinationStatsScreen extends StatefulWidget {
  const ProcrastinationStatsScreen({Key? key}) : super(key: key);

  @override
  State<ProcrastinationStatsScreen> createState() => _ProcrastinationStatsScreenState();
}

class _ProcrastinationStatsScreenState extends State<ProcrastinationStatsScreen> {
  final ProcrastinationService _service = ProcrastinationService();
  ProcrastinationStatsResponse? _statsData;
  ProcrastinationAnalysis? _aiAnalysis;
  bool _isLoading = false;
  bool _isLoadingAnalysis = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _service.getStats();
      setState(() {
        _statsData = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载统计数据失败: $e')),
        );
      }
    }
  }

  Future<void> _loadAIAnalysis() async {
    setState(() => _isLoadingAnalysis = true);
    try {
      final analysis = await _service.getAIAnalysis();
      setState(() {
        _aiAnalysis = analysis;
        _isLoadingAnalysis = false;
      });
    } catch (e) {
      setState(() => _isLoadingAnalysis = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取AI分析失败: $e')),
        );
      }
    }
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
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTopReasonsSection() {
    if (_statsData?.topReasons.isEmpty ?? true) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '拖延借口排行榜 🏆',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._statsData!.topReasons.asMap().entries.map((entry) {
          final index = entry.key;
          final reason = entry.value;
          final rankNumbers = ['1', '2', '3'];
          final colors = [Colors.amber, Colors.grey, Colors.brown];
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors[index].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors[index].withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors[index],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      rankNumbers[index],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reason.reasonDisplay,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '使用了 ${reason.count} 次',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors[index],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '第${index + 1}名',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAIAnalysisSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'AI 智能分析 🤖',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (_aiAnalysis == null)
              TextButton.icon(
                onPressed: _isLoadingAnalysis ? null : _loadAIAnalysis,
                icon: _isLoadingAnalysis 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.psychology, size: 16),
                label: Text(_isLoadingAnalysis ? '分析中...' : '获取分析'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_aiAnalysis != null) ...[
          // 分析结果
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '深度分析',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _aiAnalysis!.analysis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 改善建议
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tips_and_updates, color: Colors.green[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '改善建议',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._aiAnalysis!.suggestions.map((suggestion) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
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
                )).toList(),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 心情调理
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite_outline, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '心情调理',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _aiAnalysis!.moodAdvice,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.book,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  '点击获取AI分析',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI将分析你的拖延模式并提供个性化建议',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('拖延统计'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _loadStats();
                if (_aiAnalysis != null) {
                  await _loadAIAnalysis();
                }
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_statsData != null) ...[
                      // 基础统计卡片
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.2,
                        children: [
                          _buildStatCard(
                            '总拖延次数',
                            _statsData!.basicStats.totalProcrastinations.toString(),
                            Icons.schedule,
                            Colors.red,
                          ),
                          _buildStatCard(
                            '当前连续天数',
                            _statsData!.basicStats.currentStreak.toString(),
                            Icons.local_fire_department,
                            Colors.orange,
                          ),
                          _buildStatCard(
                            '最长连续天数',
                            _statsData!.basicStats.longestStreak.toString(),
                            Icons.trending_up,
                            Colors.purple,
                          ),
                          _buildStatCard(
                            '本周拖延',
                            _getWeeklyCount().toString(),
                            Icons.date_range,
                            Colors.blue,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // 拖延借口排行榜
                      _buildTopReasonsSection(),
                      
                      const SizedBox(height: 32),
                      
                      // AI智能分析
                      _buildAIAnalysisSection(),
                      
                      // 底部留白，改善美观性
                      const SizedBox(height: 32),
                    ] else ...[
                      const Center(
                        child: Text('暂无统计数据'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  int _getWeeklyCount() {
    if (_statsData?.dailyTrend == null) return 0;
    
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    int count = 0;
    
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      count += _statsData!.dailyTrend[dateStr] ?? 0;
    }
    
    return count;
  }
}
