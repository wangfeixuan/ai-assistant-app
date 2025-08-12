import 'package:flutter/material.dart';

/// 美观的手动时间输入对话框
class ManualTimeInputDialog extends StatefulWidget {
  final TimeOfDay initialTime;

  const ManualTimeInputDialog({
    super.key,
    required this.initialTime,
  });

  @override
  State<ManualTimeInputDialog> createState() => _ManualTimeInputDialogState();
}

class _ManualTimeInputDialogState extends State<ManualTimeInputDialog> {
  late TextEditingController _hourController;
  late TextEditingController _minuteController;
  late FocusNode _hourFocusNode;
  late FocusNode _minuteFocusNode;
  bool _isValid = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _hourController = TextEditingController(
      text: widget.initialTime.hour.toString().padLeft(2, '0'),
    );
    _minuteController = TextEditingController(
      text: widget.initialTime.minute.toString().padLeft(2, '0'),
    );
    _hourFocusNode = FocusNode();
    _minuteFocusNode = FocusNode();
    
    // 监听输入变化
    _hourController.addListener(_validateInput);
    _minuteController.addListener(_validateInput);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _hourFocusNode.dispose();
    _minuteFocusNode.dispose();
    super.dispose();
  }

  void _validateInput() {
    final hour = int.tryParse(_hourController.text);
    final minute = int.tryParse(_minuteController.text);
    
    setState(() {
      if (hour == null || hour < 0 || hour > 23) {
        _isValid = false;
        _errorMessage = '小时必须在 0-23 之间';
      } else if (minute == null || minute < 0 || minute > 59) {
        _isValid = false;
        _errorMessage = '分钟必须在 0-59 之间';
      } else {
        _isValid = true;
        _errorMessage = '';
      }
    });
  }

  void _onConfirm() {
    if (_isValid) {
      final hour = int.parse(_hourController.text);
      final minute = int.parse(_minuteController.text);
      Navigator.of(context).pop(TimeOfDay(hour: hour, minute: minute));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 10,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withOpacity(0.95),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // 标题
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.access_time_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '设置时间',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // 时间输入区域
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 小时输入
                    Flexible(
                      child: _buildTimeInput(
                        controller: _hourController,
                        focusNode: _hourFocusNode,
                        label: '小时',
                        hint: '0-23',
                        onSubmitted: (_) => _minuteFocusNode.requestFocus(),
                      ),
                    ),
                    
                    // 分隔符
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // 分钟输入
                    Flexible(
                      child: _buildTimeInput(
                        controller: _minuteController,
                        focusNode: _minuteFocusNode,
                        label: '分钟',
                        hint: '0-59',
                        onSubmitted: (_) => _onConfirm(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 错误提示
            if (!_isValid) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _errorMessage,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isValid ? _onConfirm : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: _isValid ? 2 : 0,
                    ),
                    child: const Text('确定'),
                  ),
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required Function(String) onSubmitted,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 60,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 2,
            onSubmitted: onSubmitted,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
                fontWeight: FontWeight.w600,
              ),
              border: InputBorder.none,
              counterText: '',
              contentPadding: const EdgeInsets.all(0),
            ),
          ),
        ),
      ],
    );
  }
}
