import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/themes/theme_manager.dart';

/// 颜色主题选择器组件 - 对应HTML版本的颜色圆圈选择器
class ColorThemePicker extends StatelessWidget {
  const ColorThemePicker({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: themeManager.availableThemes.map((themeName) {
              final isSelected = themeName == themeManager.currentThemeName;
              final themeColor = themeManager.getThemeColor(themeName);
              final displayName = themeManager.getThemeDisplayName(themeName);
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () {
                    themeManager.switchTheme(themeName);
                    
                    // 显示切换成功提示
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('主题已切换为 $displayName'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          themeColor,
                          themeColor.withOpacity(0.8),
                        ],
                      ),
                      border: isSelected
                          ? Border.all(
                              color: Colors.white,
                              width: 2,
                            )
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
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
