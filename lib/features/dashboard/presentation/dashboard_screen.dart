import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/platform/screen_control_service.dart';
import '../../automation/domain/prayer_flow_models.dart';
import '../../mosque_display/application/display_control_controller.dart';
import '../../mosque_display/presentation/mosque_content_screens.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/domain/app_settings.dart';
import '../../settings/presentation/settings_screen.dart';
import '../application/dashboard_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardControllerProvider);
    final settings = ref.watch(settingsControllerProvider);
    final displayControl = ref.watch(displayControlControllerProvider);
    final isForceBlack =
        displayControl.isForceBlackActive(dashboardState.now) &&
            dashboardState.automation.mode == DisplayStateMode.blackScreen;

    void openSettings() {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => const SettingsScreen(),
        ),
      );
    }

    void unlockDisplay() {
      ref
          .read(settingsControllerProvider.notifier)
          .updateScreenLockModeEnabled(false);
      ref.read(displayControlControllerProvider.notifier).clearForceBlack();
      unawaited(ref.read(screenControlServiceProvider).wakeForPrayerFlow());
      unawaited(
        ref
            .read(screenControlServiceProvider)
            .setKeepScreenOn(settings.keepScreenAlwaysOn),
      );
      ref.read(dashboardControllerProvider.notifier).recalculateAfterUnlock();
    }

    void lockDisplay() {
      ref
          .read(settingsControllerProvider.notifier)
          .updateScreenLockModeEnabled(true);
    }

    void showBlackScreen() {
      ref
          .read(settingsControllerProvider.notifier)
          .updateScreenLockModeEnabled(true);
      ref.read(displayControlControllerProvider.notifier).forceBlackUntil(
            dashboardState.automation.nextTransitionAt,
          );
      if (settings.offModeType == OffModeTypeOption.realStandby) {
        unawaited(ref.read(screenControlServiceProvider).enterRealStandby());
      }
    }

    void recalculateScheduleNow() {
      ref.read(dashboardControllerProvider.notifier).recalculateNow();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recalculate schedule now')),
      );
    }

    final content = isForceBlack
        ? MosqueContentScreens.fromSnapshot(
            snapshot: PrayerFlowSnapshot.black(
              nextTransitionAt: dashboardState.automation.nextTransitionAt,
            ),
            now: dashboardState.now,
            prayerDay: null,
            settings: settings,
            onOpenSettings: openSettings,
            controlsVisible: !settings.screenLockModeEnabled,
          )
        : MosqueDisplaySurface(
            state: dashboardState,
            settings: settings,
            onOpenSettings: openSettings,
            controlsVisible: !settings.screenLockModeEnabled,
          );

    return FocusTraversalGroup(
      child: Scaffold(
        body: _LockedDisplayShell(
          locked: settings.screenLockModeEnabled,
          onUnlock: unlockDisplay,
          onOpenSettings: openSettings,
          onLock: lockDisplay,
          onBlackScreen: showBlackScreen,
          onRecalculateSchedule: recalculateScheduleNow,
          child: content,
        ),
      ),
    );
  }
}

class _LockedDisplayShell extends ConsumerStatefulWidget {
  const _LockedDisplayShell({
    required this.locked,
    required this.onUnlock,
    required this.onOpenSettings,
    required this.onLock,
    required this.onBlackScreen,
    required this.onRecalculateSchedule,
    required this.child,
  });

  final bool locked;
  final VoidCallback onUnlock;
  final VoidCallback onOpenSettings;
  final VoidCallback onLock;
  final VoidCallback onBlackScreen;
  final VoidCallback onRecalculateSchedule;
  final Widget child;

  @override
  ConsumerState<_LockedDisplayShell> createState() =>
      _LockedDisplayShellState();
}

class _LockedDisplayShellState extends ConsumerState<_LockedDisplayShell> {
  static const Duration _unlockWindow = Duration(milliseconds: 1500);
  static const Duration _okLongPressUnlockDuration =
      Duration(milliseconds: 2300);

  final FocusNode _focusNode = FocusNode(debugLabel: 'DisplayUnlockShell');
  int _tapCount = 0;
  DateTime? _firstTapAt;
  String? _lastUnlockSource;
  Timer? _okLongPressTimer;

  @override
  void initState() {
    super.initState();
    _configureRemoteCapture();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestFocus());
  }

  @override
  void didUpdateWidget(covariant _LockedDisplayShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locked != widget.locked) {
      _configureRemoteCapture();
      _resetUnlockSequence();
      if (!widget.locked) {
        _focusNode.unfocus();
      }
    }
    if (widget.locked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _requestFocus());
    }
  }

  @override
  void dispose() {
    _okLongPressTimer?.cancel();
    ref.read(screenControlServiceProvider).setRemoteUnlockCapture(false);
    ref.read(screenControlServiceProvider).setRemoteKeyHandler(null);
    _focusNode.dispose();
    super.dispose();
  }

  void _configureRemoteCapture() {
    final screenControl = ref.read(screenControlServiceProvider);
    screenControl.setRemoteKeyHandler(_handleNativeRemoteKey);
    unawaited(screenControl.setRemoteUnlockCapture(widget.locked));
  }

  void _requestFocus() {
    if (!mounted) {
      return;
    }
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  void _handleNativeRemoteKey(RemoteUnlockKey key, String action) {
    if (!widget.locked) {
      return;
    }

    final label = key == RemoteUnlockKey.back ? 'BACK' : 'OK';
    debugPrint('Remote key detected: $label');

    if (key == RemoteUnlockKey.ok) {
      if (action == 'down') {
        _startOkLongPressTimer();
        _registerUnlockPulse(source: label);
      } else if (action == 'up') {
        _okLongPressTimer?.cancel();
      }
      return;
    }

    if (key == RemoteUnlockKey.back && action == 'down') {
      _registerUnlockPulse(source: label);
    }
  }

  void _startOkLongPressTimer() {
    _okLongPressTimer?.cancel();
    _okLongPressTimer = Timer(_okLongPressUnlockDuration, () {
      if (!mounted || !widget.locked) {
        return;
      }
      debugPrint('Unlock sequence progress: long press OK');
      _unlock();
    });
  }

  void _registerUnlockPulse({required String source}) {
    if (!widget.locked) {
      return;
    }

    final now = DateTime.now();
    final firstTapAt = _firstTapAt;
    if (firstTapAt == null ||
        now.difference(firstTapAt) > _unlockWindow ||
        _lastUnlockSource != source) {
      _firstTapAt = now;
      _tapCount = 1;
      _lastUnlockSource = source;
      debugPrint('Unlock sequence progress: 1/3');
      return;
    }

    _tapCount += 1;
    debugPrint('Unlock sequence progress: ${_tapCount.clamp(1, 3)}/3');
    if (_tapCount >= 3) {
      _unlock();
    }
  }

  void _unlock() {
    _resetUnlockSequence();
    widget.onUnlock();
  }

  void _resetUnlockSequence() {
    _tapCount = 0;
    _firstTapAt = null;
    _lastUnlockSource = null;
    _okLongPressTimer?.cancel();
  }

  KeyEventResult _handleFlutterKeyEvent(FocusNode node, KeyEvent event) {
    if (!widget.locked) {
      return KeyEventResult.ignored;
    }

    final logicalKey = event.logicalKey;
    final isOk = logicalKey == LogicalKeyboardKey.select ||
        logicalKey == LogicalKeyboardKey.enter ||
        logicalKey == LogicalKeyboardKey.numpadEnter ||
        logicalKey == LogicalKeyboardKey.space;
    final isBack = logicalKey == LogicalKeyboardKey.goBack ||
        logicalKey == LogicalKeyboardKey.escape ||
        logicalKey == LogicalKeyboardKey.browserBack;

    if (!isOk && !isBack) {
      return KeyEventResult.ignored;
    }

    final label = isBack ? 'BACK' : 'OK';
    debugPrint('Remote key detected: $label');

    if (event is KeyDownEvent) {
      if (isOk) {
        _startOkLongPressTimer();
      }
      _registerUnlockPulse(source: label);
      return KeyEventResult.handled;
    }

    if (event is KeyUpEvent) {
      if (isOk) {
        _okLongPressTimer?.cancel();
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.locked,
      canRequestFocus: widget.locked,
      skipTraversal: !widget.locked,
      descendantsAreFocusable: !widget.locked,
      descendantsAreTraversable: !widget.locked,
      onKeyEvent: _handleFlutterKeyEvent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.locked
                  ? () => _registerUnlockPulse(source: 'TOUCH')
                  : null,
              child: AbsorbPointer(
                absorbing: widget.locked,
                child: widget.child,
              ),
            ),
          ),
          if (!widget.locked)
            _AdminControls(
              onOpenSettings: widget.onOpenSettings,
              onLock: widget.onLock,
              onBlackScreen: widget.onBlackScreen,
              onRecalculateSchedule: widget.onRecalculateSchedule,
            ),
        ],
      ),
    );
  }
}

class _AdminControls extends StatelessWidget {
  const _AdminControls({
    required this.onOpenSettings,
    required this.onLock,
    required this.onBlackScreen,
    required this.onRecalculateSchedule,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback onLock;
  final VoidCallback onBlackScreen;
  final VoidCallback onRecalculateSchedule;

  @override
  Widget build(BuildContext context) {
    return _AdminControlsFocusSurface(
      onOpenSettings: onOpenSettings,
      onLock: onLock,
      onBlackScreen: onBlackScreen,
      onRecalculateSchedule: onRecalculateSchedule,
    );
  }
}

class _AdminControlsFocusSurface extends StatefulWidget {
  const _AdminControlsFocusSurface({
    required this.onOpenSettings,
    required this.onLock,
    required this.onBlackScreen,
    required this.onRecalculateSchedule,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback onLock;
  final VoidCallback onBlackScreen;
  final VoidCallback onRecalculateSchedule;

  @override
  State<_AdminControlsFocusSurface> createState() =>
      _AdminControlsFocusSurfaceState();
}

class _AdminControlsFocusSurfaceState
    extends State<_AdminControlsFocusSurface> {
  final FocusNode _settingsNode = FocusNode(debugLabel: 'AdminSettingsButton');
  final FocusNode _lockNode = FocusNode(debugLabel: 'AdminLockButton');
  final FocusNode _blackNode = FocusNode(debugLabel: 'AdminBlackButton');
  final FocusNode _recalculateNode =
      FocusNode(debugLabel: 'AdminRecalculateScheduleButton');
  Timer? _focusRequestTimer;
  Timer? _focusFallbackTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusRequestTimer = Timer(
        const Duration(milliseconds: 160),
        _requestFirstFocus,
      );
    });
    _focusFallbackTimer = Timer(
      const Duration(milliseconds: 240),
      _requestFirstFocusIfNeeded,
    );
  }

  @override
  void dispose() {
    _focusRequestTimer?.cancel();
    _focusFallbackTimer?.cancel();
    _settingsNode.dispose();
    _lockNode.dispose();
    _blackNode.dispose();
    _recalculateNode.dispose();
    super.dispose();
  }

  void _requestFirstFocus() {
    if (!mounted) {
      return;
    }
    FocusScope.of(context).requestFocus(_settingsNode);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final focused = FocusManager.instance.primaryFocus?.debugLabel ?? 'none';
      debugPrint('Focused control after unlock: $focused');
    });
  }

  void _requestFirstFocusIfNeeded() {
    if (!mounted) {
      return;
    }

    final focusedNode = FocusManager.instance.primaryFocus;
    if (focusedNode == null ||
        focusedNode == FocusManager.instance.rootScope ||
        !<_FocusNodeIdentity>{
          _FocusNodeIdentity(_settingsNode),
          _FocusNodeIdentity(_lockNode),
          _FocusNodeIdentity(_blackNode),
          _FocusNodeIdentity(_recalculateNode),
        }.contains(_FocusNodeIdentity(focusedNode))) {
      _requestFirstFocus();
    }
  }

  KeyEventResult _moveFocusOnArrow(
    KeyEvent event, {
    required FocusNode previous,
    required FocusNode next,
  }) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowDown) {
      debugPrint('Remote key detected: ${_remoteKeyLabel(key)}');
      FocusScope.of(context).requestFocus(next);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowUp) {
      debugPrint('Remote key detected: ${_remoteKeyLabel(key)}');
      FocusScope.of(context).requestFocus(previous);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      top: AppLayout.gap(context, compact: 14, medium: 20),
      start: AppLayout.gap(context, compact: 14, medium: 20),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xDD06100D),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(AppLayout.gap(context, compact: 8)),
            child: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Wrap(
                spacing: AppLayout.gap(context, compact: 8, medium: 10),
                runSpacing: AppLayout.gap(context, compact: 8, medium: 10),
                children: [
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(1),
                    child: _FocusedAdminButton(
                      focusNode: _settingsNode,
                      autofocus: true,
                      onKeyEvent: (node, event) => _moveFocusOnArrow(
                        event,
                        previous: _recalculateNode,
                        next: _lockNode,
                      ),
                      onPressed: widget.onOpenSettings,
                      icon: const Icon(Icons.settings_rounded),
                      label: 'Settings / الإعدادات',
                    ),
                  ),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(2),
                    child: _FocusedAdminButton(
                      focusNode: _lockNode,
                      onKeyEvent: (node, event) => _moveFocusOnArrow(
                        event,
                        previous: _settingsNode,
                        next: _blackNode,
                      ),
                      onPressed: widget.onLock,
                      icon: const Icon(Icons.lock_rounded),
                      label: 'Lock Screen / وضع القفل',
                    ),
                  ),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(3),
                    child: _FocusedAdminButton(
                      focusNode: _blackNode,
                      onKeyEvent: (node, event) => _moveFocusOnArrow(
                        event,
                        previous: _lockNode,
                        next: _recalculateNode,
                      ),
                      onPressed: widget.onBlackScreen,
                      icon: const Icon(Icons.power_settings_new_rounded),
                      label: 'Black Screen / إطفاء الشاشة',
                    ),
                  ),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(4),
                    child: _FocusedAdminButton(
                      focusNode: _recalculateNode,
                      onKeyEvent: (node, event) => _moveFocusOnArrow(
                        event,
                        previous: _blackNode,
                        next: _settingsNode,
                      ),
                      onPressed: widget.onRecalculateSchedule,
                      icon: const Icon(Icons.refresh_rounded),
                      label: 'Recalculate schedule now',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusNodeIdentity {
  const _FocusNodeIdentity(this.node);

  final FocusNode node;

  @override
  bool operator ==(Object other) {
    return other is _FocusNodeIdentity && identical(node, other.node);
  }

  @override
  int get hashCode => identityHashCode(node);
}

class _FocusedAdminButton extends StatefulWidget {
  const _FocusedAdminButton({
    required this.focusNode,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.onKeyEvent,
    this.autofocus = false,
  });

  final FocusNode focusNode;
  final VoidCallback onPressed;
  final Widget icon;
  final String label;
  final FocusOnKeyEventCallback onKeyEvent;
  final bool autofocus;

  @override
  State<_FocusedAdminButton> createState() => _FocusedAdminButtonState();
}

class _FocusedAdminButtonState extends State<_FocusedAdminButton> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _FocusedAdminButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      widget.focusNode.addListener(_handleFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChanged);
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final focused = widget.focusNode.hasFocus;
    return Focus(
      canRequestFocus: false,
      descendantsAreFocusable: true,
      onKeyEvent: _handleKeyEvent,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        scale: focused ? 1.045 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: const Color(0xFFD8BE74).withValues(alpha: 0.36),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: FilledButton.icon(
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            onPressed: _activate,
            icon: widget.icon,
            label: Text(widget.label),
            style: ButtonStyle(
              side: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.focused)) {
                  return const BorderSide(
                    color: Color(0xFFD8BE74),
                    width: 2,
                  );
                }
                return BorderSide.none;
              }),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final navigationResult = widget.onKeyEvent(node, event);
    if (navigationResult == KeyEventResult.handled) {
      return navigationResult;
    }

    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (!_isOkKey(key)) {
      return KeyEventResult.ignored;
    }

    debugPrint('Remote key detected: OK');
    _activate();
    return KeyEventResult.handled;
  }

  void _activate() {
    debugPrint('Selected control on OK: ${widget.label}');
    widget.onPressed();
  }
}

bool _isOkKey(LogicalKeyboardKey key) {
  return key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.numpadEnter ||
      key == LogicalKeyboardKey.space;
}

String _remoteKeyLabel(LogicalKeyboardKey key) {
  if (key == LogicalKeyboardKey.arrowUp) {
    return 'UP';
  }
  if (key == LogicalKeyboardKey.arrowDown) {
    return 'DOWN';
  }
  if (key == LogicalKeyboardKey.arrowLeft) {
    return 'LEFT';
  }
  if (key == LogicalKeyboardKey.arrowRight) {
    return 'RIGHT';
  }
  return key.keyLabel;
}
