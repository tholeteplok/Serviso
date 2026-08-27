import '../../../core/models/wo_status.dart';

enum WoEvent { start, complete, cancel }

class IllegalTransitionException implements Exception {
  const IllegalTransitionException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract final class WoStateMachine {
  static const _allowed = {
    WoStatus.menunggu: {WoEvent.start, WoEvent.cancel},
    WoStatus.dikerjakan: {WoEvent.start, WoEvent.complete, WoEvent.cancel},
    WoStatus.selesai: {WoEvent.cancel},
    WoStatus.dibatalkan: <WoEvent>{},
  };

  static bool canTransition(WoStatus from, WoEvent event) =>
      _allowed[from]?.contains(event) ?? false;

  static WoStatus? transition(WoStatus from, WoEvent event) {
    if (!canTransition(from, event)) return null;
    switch ((from, event)) {
      case (WoStatus.menunggu, WoEvent.start):
        return WoStatus.dikerjakan;
      case (WoStatus.menunggu, WoEvent.cancel):
        return WoStatus.dibatalkan;
      case (WoStatus.dikerjakan, WoEvent.start):
        return WoStatus.menunggu;
      case (WoStatus.dikerjakan, WoEvent.complete):
        return WoStatus.selesai;
      case (WoStatus.dikerjakan, WoEvent.cancel):
        return WoStatus.dibatalkan;
      case (WoStatus.selesai, WoEvent.cancel):
        return WoStatus.dibatalkan;
      default:
        return null;
    }
  }
}
