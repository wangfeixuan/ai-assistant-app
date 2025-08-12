import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/themes/theme_manager.dart';

/// 主题色选择器组件
class ThemeSelector extends StatelessWidget {
  final bool showTitle;
  final bool isCompact;

  const ThemeSelector({
    super.key,
    this.showTitle = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle) ...[
              Text(
                '主题色',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
            ],
            _buildThemeOptions(context, themeManager),
          ],
        );
      },
    );
  }

  /// 构建主题选项
  Widget _buildThemeOptions(BuildContext context, ThemeManager themeManager) {
    if (isCompact) {
      return _buildCompactThemeOptions(context, themeManager);
    } else {
      return _buildFullThemeOptions(context, themeManager);
    }
  }

  /// 构建完整的主题选项（用于设置页面）
  Widget _buildFullThemeOptions(BuildContext context, ThemeManager themeManager) {
    return Column(
      children: themeManager.availableThemes.map((themeName) {
        final isSelected = themeManager.currentThemeName == themeName;
        final themeColor = themeManager.getThemeColor(themeName);
        final displayName = themeManager.getThemeDisplayName(themeName);
        final icon = themeManager.getThemeIcon(themeName);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _selectTheme(context, themeManager, themeName),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? themeColor.withOpacity(0.1)
                      : Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color: isSelected 
                        ? themeColor
                        : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // 主题色圆圈
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: themeColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: themeColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // 主题名称和描述
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected 
                                      ? themeColor
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getThemeDescription(themeName),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    
                    // 选中指示器
                    if (isSelected)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: themeColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建紧凑的主题选项（用于快速切换）- 极简版本
  Widget _buildCompactThemeOptions(BuildContext context, ThemeManager themeManager) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: themeManager.availableThemes.map((themeName) {
          final isSelected = themeManager.currentThemeName == themeName;
          final themeColor = themeManager.getThemeColor(themeName);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  debugPrint('🎨 点击主题切换: $themeName (当前: ${themeManager.currentThemeName})');
                  _selectTheme(context, themeManager, themeName);
                },
                child: Container(
                  padding: const EdgeInsets.all(4), // 增加点击区域
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: themeColor,
                      shape: BoxShape.circle,
                      border: isSelected 
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: themeColor.withOpacity(0.3),
                          blurRadius: isSelected ? 8 : 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    transform: isSelected
                        ? (Matrix4.identity()..scale(1.1))
                        : Matrix4.identity(),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 选择主题
  Future<void> _selectTheme(
    BuildContext context,
    ThemeManager themeManager,
    String themeName,
  ) async {
    debugPrint('🎨 开始切换主题: $themeName');
    
    // 添加触觉反馈
    // HapticFeedback.lightImpact();
    
    try {
      debugPrint('🎨 调用 ThemeManager.switchTheme: $themeName');
      // 切换主题
      await themeManager.switchTheme(themeName);
      debugPrint('🎨 主题切换完成: $themeName');
      
      // 显示成功提示
      if (context.mounted) {
        try {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已切换到${themeManager.getThemeDisplayName(themeName)}主题'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          debugPrint('🎨 显示成功提示');
        } catch (e) {
          debugPrint('❌ 显示 SnackBar 失败: $e');
          // 降级处理：输出到控制台
          debugPrint('✅ 主题已切换到: ${themeManager.getThemeDisplayName(themeName)}');
        }
      } else {
        debugPrint('⚠️ Context 未挂载，跳过 SnackBar 显示');
      }
    } catch (e) {
      debugPrint('❌ 主题切换出错: $e');
      // 显示错误提示
      if (context.mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('主题切换失败，请重试'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.red,
            ),
          );
        } catch (snackError) {
          debugPrint('❌ 显示错误 SnackBar 失败: $snackError');
        }
      }
    }
  }

  /// 获取主题描述
  String _getThemeDescription(String themeName) {
    const descriptions = {
      'blue': '专业稳重，适合商务场景',
      'pink': '温馨可爱，充满活力',
      'purple': '神秘优雅，激发创意',
      'green': '自然清新，护眼舒适',
      'yellow': '阳光活泼，提升心情',
    };
    return descriptions[themeName] ?? '经典配色';
  }
}

/// 主题色快速切换按钮
class ThemeQuickSwitcher extends StatelessWidget {
  const ThemeQuickSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return PopupMenuButton<String>(
          icon: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: themeManager.getThemeColor(themeManager.currentThemeName),
              shape: BoxShape.circle,
            ),
            child: Icon(
              themeManager.getThemeIcon(themeManager.currentThemeName),
              color: Colors.white,
              size: 16,
            ),
          ),
          tooltip: '切换主题',
          onSelected: (themeName) async {
            await themeManager.switchTheme(themeName);
          },
          itemBuilder: (context) {
            return themeManager.availableThemes.map((themeName) {
              final isSelected = themeManager.currentThemeName == themeName;
              final themeColor = themeManager.getThemeColor(themeName);
              final displayName = themeManager.getThemeDisplayName(themeName);
              final icon = themeManager.getThemeIcon(themeName);

              return PopupMenuItem<String>(
                value: themeName,
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: themeColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(displayName),
                    if (isSelected) ...[
                      const Spacer(),
                      Icon(
                        Icons.check,
                        color: themeColor,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              );
            }).toList();
          },
        );
      },
    );
  }
}

/// 主题色预览卡片
class ThemePreviewCard extends StatelessWidget {
  final String themeName;
  final bool isSelected;
  final VoidCallback? onTap;

  const ThemePreviewCard({
    super.key,
    required this.themeName,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final themeColor = themeManager.getThemeColor(themeName);
    final displayName = themeManager.getThemeDisplayName(themeName);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? themeColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                themeColor,
                themeColor.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                themeManager.getThemeIcon(themeName),
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
