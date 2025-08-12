import 'package:flutter/material.dart';
import '../../models/user.dart';

/// 登录方式选择器组件
class LoginTypeSelector extends StatelessWidget {
  final LoginType selectedType;
  final ValueChanged<LoginType> onChanged;

  const LoginTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: LoginType.values.map((type) {
          final isSelected = selectedType == type;
          
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected 
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type == LoginType.email ? Icons.email_outlined : Icons.phone_outlined,
                      color: isSelected 
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      type.displayName.replaceAll('登录', ''),
                      style: TextStyle(
                        color: isSelected 
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isSelected 
                          ? FontWeight.w600
                          : FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}