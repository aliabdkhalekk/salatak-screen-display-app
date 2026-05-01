import 'package:flutter_riverpod/flutter_riverpod.dart';

final displayControlControllerProvider =
    NotifierProvider<DisplayControlController, DisplayControlState>(
  DisplayControlController.new,
);

class DisplayControlState {
  const DisplayControlState({
    this.forceBlack = false,
    this.forceBlackUntil,
  });

  final bool forceBlack;
  final DateTime? forceBlackUntil;

  bool isForceBlackActive(DateTime now) {
    if (!forceBlack) {
      return false;
    }
    final until = forceBlackUntil;
    return until == null || now.isBefore(until);
  }
}

class DisplayControlController extends Notifier<DisplayControlState> {
  @override
  DisplayControlState build() {
    return const DisplayControlState();
  }

  void forceBlackUntil(DateTime? nextScheduledTransition) {
    state = DisplayControlState(
      forceBlack: true,
      forceBlackUntil: nextScheduledTransition,
    );
  }

  void clearForceBlack() {
    state = const DisplayControlState();
  }
}
