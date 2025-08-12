import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 每日鼓励语录功能提供者
class QuoteProvider extends ChangeNotifier {
  static const String _lastQuoteDateKey = 'last_quote_date';
  static const String _currentQuoteIndexKey = 'current_quote_index';
  
  String _currentQuote = '';
  String _currentDate = '';
  int _currentQuoteIndex = 0;

  // 鼓励语录库
  final List<String> _quotes = [
    '今天是全新的开始，让我们一起专注前行！',
    '每一个小步骤都是向目标迈进的重要一步。',
    '专注当下，你比想象中更强大！',
    '拖延是梦想的敌人，行动是成功的朋友。',
    '番茄钟滴答声中，专注力正在成长。',
    '完成比完美更重要，开始比等待更有意义。',
    '今天的努力，是明天成功的基石。',
    '专注25分钟，给自己一个小小的胜利！',
    '每完成一个任务，都是对自己的一次肯定。',
    '时间管理就是生活管理，你值得更好的自己。',
    '不要害怕开始，害怕的应该是从未行动。',
    '专注力是现代人最珍贵的超能力。',
    '小目标累积成大成就，坚持就是胜利。',
    '今天的你，比昨天更进步一点点。',
    '用番茄钟丈量时间，用专注创造价值。',
    '拖延症不可怕，可怕的是放弃治疗它。',
    '每一次专注，都是对未来自己的投资。',
    '行动起来，让今天比昨天更有意义！',
    '专注的力量，可以移山填海。',
    '相信自己，你有能力完成任何目标！'
  ];

  String get currentQuote => _currentQuote;
  String get currentDate => _currentDate;

  QuoteProvider() {
    _initializeQuote();
  }

  /// 初始化每日语录
  Future<void> _initializeQuote() async {
    await _updateDailyQuote();
  }

  /// 更新每日语录
  Future<void> _updateDailyQuote() async {
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastQuoteDate = prefs.getString(_lastQuoteDateKey);
      
      // 检查是否需要更新语录（每天零点更新）
      if (lastQuoteDate != today) {
        // 获取新的语录索引
        _currentQuoteIndex = (prefs.getInt(_currentQuoteIndexKey) ?? 0);
        _currentQuoteIndex = (_currentQuoteIndex + 1) % _quotes.length;
        
        // 保存新的日期和索引
        await prefs.setString(_lastQuoteDateKey, today);
        await prefs.setInt(_currentQuoteIndexKey, _currentQuoteIndex);
      } else {
        // 使用已保存的索引
        _currentQuoteIndex = prefs.getInt(_currentQuoteIndexKey) ?? 0;
      }
      
      _currentQuote = _quotes[_currentQuoteIndex];
      _currentDate = _formatDate(now);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating daily quote: $e');
      // 使用默认语录
      _currentQuote = _quotes[0];
      _currentDate = _formatDate(now);
      notifyListeners();
    }
  }

  /// 手动刷新语录（用于测试）
  Future<void> refreshQuote() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentQuoteIndex = (_currentQuoteIndex + 1) % _quotes.length;
      await prefs.setInt(_currentQuoteIndexKey, _currentQuoteIndex);
      
      _currentQuote = _quotes[_currentQuoteIndex];
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing quote: $e');
    }
  }

  /// 获取随机语录
  String getRandomQuote() {
    final randomIndex = DateTime.now().millisecondsSinceEpoch % _quotes.length;
    return _quotes[randomIndex];
  }

  /// 添加自定义语录
  void addCustomQuote(String quote) {
    if (quote.trim().isNotEmpty) {
      _quotes.add(quote.trim());
      notifyListeners();
    }
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    const months = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];
    
    final weekday = weekdays[date.weekday % 7];
    final month = months[date.month - 1];
    
    return '$month${date.day}日 $weekday';
  }

  /// 检查并更新语录（可以在应用启动时调用）
  Future<void> checkAndUpdateQuote() async {
    await _updateDailyQuote();
  }
}
