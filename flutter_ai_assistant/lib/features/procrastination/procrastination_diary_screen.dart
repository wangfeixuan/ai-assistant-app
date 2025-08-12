import 'package:flutter/material.dart';
import '../../models/procrastination_diary.dart';
import '../../services/procrastination_service.dart';
import 'procrastination_stats_screen.dart';

class ProcrastinationDiaryScreen extends StatefulWidget {
  const ProcrastinationDiaryScreen({Key? key}) : super(key: key);

  @override
  State<ProcrastinationDiaryScreen> createState() => _ProcrastinationDiaryScreenState();
}

class _ProcrastinationDiaryScreenState extends State<ProcrastinationDiaryScreen> {
  final ProcrastinationService _service = ProcrastinationService();
  List<ProcrastinationDiary> _diaries = [];
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadDiaries();
  }

  Future<void> _loadDiaries({bool refresh = false}) async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final page = refresh ? 1 : _currentPage;
      final diaries = await _service.getDiary(page: page, perPage: 20);
      
      setState(() {
        if (refresh) {
          _diaries = diaries;
          _currentPage = 1;
        } else {
          _diaries.addAll(diaries);
        }
        _hasMore = diaries.length == 20;
        _currentPage = page + 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  Future<void> _refresh() async {
    await _loadDiaries(refresh: true);
  }

  Widget _buildDiaryCard(ProcrastinationDiary diary) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日期和任务标题
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatDate(diary.procrastinationDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    diary.taskTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 拖延原因
            Row(
              children: [
                Icon(
                  Icons.book,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  '原因：',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Text(
                    diary.reasonDisplay,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            // 自定义原因
            if (diary.customReason != null && diary.customReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  diary.customReason!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            
            // 心情变化
            if (diary.moodBefore != null || diary.moodAfter != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (diary.moodBefore != null) ...[
                    Icon(
                      Icons.sentiment_very_dissatisfied,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '拖延前: ${_getMoodEmoji(diary.moodBefore!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  if (diary.moodBefore != null && diary.moodAfter != null)
                    const SizedBox(width: 16),
                  if (diary.moodAfter != null) ...[
                    Icon(
                      Icons.sentiment_satisfied,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '记录后: ${_getMoodEmoji(diary.moodAfter!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ],
            
            // 记录时间
            const SizedBox(height: 8),
            Text(
              '记录于 ${_formatDateTime(diary.createdAt)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);
    
    if (targetDate == today) {
      return '今天';
    } else if (targetDate == yesterday) {
      return '昨天';
    } else {
      return '${date.month}月${date.day}日';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}月${dateTime.day}日 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getMoodEmoji(int mood) {
    switch (mood) {
      case 1: return '😢';
      case 2: return '😕';
      case 3: return '😐';
      case 4: return '🙂';
      case 5: return '😊';
      default: return '😐';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '拖延日记',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        shadowColor: Colors.black12,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProcrastinationStatsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _diaries.isEmpty && !_isLoading
            ? _buildEmptyState()
            : NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (!_isLoading && 
                      _hasMore && 
                      scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                    _loadDiaries();
                  }
                  return false;
                },
                child: ListView.builder(
                  itemCount: _diaries.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _diaries.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return _buildDiaryCard(_diaries[index]);
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
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
            '保持良好的习惯，继续加油！',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
