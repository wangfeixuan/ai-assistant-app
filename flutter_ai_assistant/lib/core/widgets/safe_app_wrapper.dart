import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../utils/overlay_manager.dart';

/// 安全的应用包装器
/// 用于在应用级别统一管理Overlay相关的GlobalKey问题
class SafeAppWrapper extends StatefulWidget {
  final Widget child;

  const SafeAppWrapper({
    super.key,
    required this.child,
  });

  @override
  State<SafeAppWrapper> createState() => _SafeAppWrapperState();
}

class _SafeAppWrapperState extends State<SafeAppWrapper> {
  final OverlayManager _overlayManager = OverlayManager();
  late GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;

  @override
  void initState() {
    super.initState();
    // 生成唯一的ScaffoldMessenger GlobalKey
    _scaffoldMessengerKey = _overlayManager.generateUniqueKey<ScaffoldMessengerState>();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Builder(
        builder: (context) {
          return widget.child;
        },
      ),
    );
  }
}

/// 安全的Scaffold包装器
class SafeScaffold extends StatefulWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool primary;
  final DragStartBehavior drawerDragStartBehavior;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final Color? drawerScrimColor;
  final double? drawerEdgeDragWidth;
  final bool drawerEnableOpenDragGesture;
  final bool endDrawerEnableOpenDragGesture;
  final String? restorationId;

  const SafeScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.primary = true,
    this.drawerDragStartBehavior = DragStartBehavior.start,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.drawerScrimColor,
    this.drawerEdgeDragWidth,
    this.drawerEnableOpenDragGesture = true,
    this.endDrawerEnableOpenDragGesture = true,
    this.restorationId,
  });

  @override
  State<SafeScaffold> createState() => _SafeScaffoldState();
}

class _SafeScaffoldState extends State<SafeScaffold> {
  final OverlayManager _overlayManager = OverlayManager();
  late GlobalKey<ScaffoldState> _scaffoldKey;

  @override
  void initState() {
    super.initState();
    // 生成唯一的Scaffold GlobalKey
    _scaffoldKey = _overlayManager.generateUniqueKey<ScaffoldState>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: widget.appBar,
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
      drawer: widget.drawer,
      endDrawer: widget.endDrawer,
      bottomNavigationBar: widget.bottomNavigationBar,
      bottomSheet: widget.bottomSheet,
      backgroundColor: widget.backgroundColor,
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      primary: widget.primary,
      drawerDragStartBehavior: widget.drawerDragStartBehavior,
      extendBody: widget.extendBody,
      extendBodyBehindAppBar: widget.extendBodyBehindAppBar,
      drawerScrimColor: widget.drawerScrimColor,
      drawerEdgeDragWidth: widget.drawerEdgeDragWidth,
      drawerEnableOpenDragGesture: widget.drawerEnableOpenDragGesture,
      endDrawerEnableOpenDragGesture: widget.endDrawerEnableOpenDragGesture,
      restorationId: widget.restorationId,
    );
  }
}

/// 安全的PopupMenuButton包装器
class SafePopupMenuButton<T> extends StatefulWidget {
  final PopupMenuItemBuilder<T> itemBuilder;
  final T? initialValue;
  final PopupMenuItemSelected<T>? onSelected;
  final PopupMenuCanceled? onCanceled;
  final String? tooltip;
  final double? elevation;
  final EdgeInsetsGeometry padding;
  final Widget? child;
  final Widget? icon;
  final Offset offset;
  final bool enabled;
  final ShapeBorder? shape;
  final Color? color;
  final bool? enableFeedback;
  final BoxConstraints? constraints;
  final PopupMenuPosition position;
  final Clip clipBehavior;

  const SafePopupMenuButton({
    super.key,
    required this.itemBuilder,
    this.initialValue,
    this.onSelected,
    this.onCanceled,
    this.tooltip,
    this.elevation,
    this.padding = const EdgeInsets.all(8.0),
    this.child,
    this.icon,
    this.offset = Offset.zero,
    this.enabled = true,
    this.shape,
    this.color,
    this.enableFeedback,
    this.constraints,
    this.position = PopupMenuPosition.over,
    this.clipBehavior = Clip.none,
  });

  @override
  State<SafePopupMenuButton<T>> createState() => _SafePopupMenuButtonState<T>();
}

class _SafePopupMenuButtonState<T> extends State<SafePopupMenuButton<T>> {
  final OverlayManager _overlayManager = OverlayManager();
  late ValueKey<String> _popupKey;

  @override
  void initState() {
    super.initState();
    // 生成唯一的PopupMenu ValueKey
    _popupKey = _overlayManager.generateUniqueValueKey(prefix: 'popup_menu');
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      key: _popupKey,
      itemBuilder: widget.itemBuilder,
      initialValue: widget.initialValue,
      onSelected: widget.onSelected,
      onCanceled: widget.onCanceled,
      tooltip: widget.tooltip,
      elevation: widget.elevation,
      padding: widget.padding,
      child: widget.child,
      icon: widget.icon,
      offset: widget.offset,
      enabled: widget.enabled,
      shape: widget.shape,
      color: widget.color,
      enableFeedback: widget.enableFeedback,
      constraints: widget.constraints,
      position: widget.position,
      clipBehavior: widget.clipBehavior,
    );
  }
}

/// 安全的DropdownButton包装器
class SafeDropdownButton<T> extends StatefulWidget {
  final List<DropdownMenuItem<T>>? items;
  final DropdownButtonBuilder? selectedItemBuilder;
  final T? value;
  final Widget? hint;
  final Widget? disabledHint;
  final ValueChanged<T?>? onChanged;
  final VoidCallback? onTap;
  final int elevation;
  final TextStyle? style;
  final Widget? underline;
  final Widget? icon;
  final Color? iconDisabledColor;
  final Color? iconEnabledColor;
  final double iconSize;
  final bool isDense;
  final bool isExpanded;
  final double? itemHeight;
  final Color? focusColor;
  final FocusNode? focusNode;
  final bool autofocus;
  final Color? dropdownColor;
  final double? menuMaxHeight;
  final bool? enableFeedback;
  final AlignmentGeometry alignment;
  final BorderRadius? borderRadius;

  const SafeDropdownButton({
    super.key,
    required this.items,
    this.selectedItemBuilder,
    this.value,
    this.hint,
    this.disabledHint,
    this.onChanged,
    this.onTap,
    this.elevation = 8,
    this.style,
    this.underline,
    this.icon,
    this.iconDisabledColor,
    this.iconEnabledColor,
    this.iconSize = 24.0,
    this.isDense = false,
    this.isExpanded = false,
    this.itemHeight,
    this.focusColor,
    this.focusNode,
    this.autofocus = false,
    this.dropdownColor,
    this.menuMaxHeight,
    this.enableFeedback,
    this.alignment = AlignmentDirectional.centerStart,
    this.borderRadius,
  });

  @override
  State<SafeDropdownButton<T>> createState() => _SafeDropdownButtonState<T>();
}

class _SafeDropdownButtonState<T> extends State<SafeDropdownButton<T>> {
  final OverlayManager _overlayManager = OverlayManager();
  late ValueKey<String> _dropdownKey;

  @override
  void initState() {
    super.initState();
    // 生成唯一的Dropdown ValueKey
    _dropdownKey = _overlayManager.generateUniqueValueKey(prefix: 'dropdown');
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<T>(
      key: _dropdownKey,
      items: widget.items,
      selectedItemBuilder: widget.selectedItemBuilder,
      value: widget.value,
      hint: widget.hint,
      disabledHint: widget.disabledHint,
      onChanged: widget.onChanged,
      onTap: widget.onTap,
      elevation: widget.elevation,
      style: widget.style,
      underline: widget.underline,
      icon: widget.icon,
      iconDisabledColor: widget.iconDisabledColor,
      iconEnabledColor: widget.iconEnabledColor,
      iconSize: widget.iconSize,
      isDense: widget.isDense,
      isExpanded: widget.isExpanded,
      itemHeight: widget.itemHeight,
      focusColor: widget.focusColor,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      dropdownColor: widget.dropdownColor,
      menuMaxHeight: widget.menuMaxHeight,
      enableFeedback: widget.enableFeedback,
      alignment: widget.alignment,
      borderRadius: widget.borderRadius,
    );
  }
}
