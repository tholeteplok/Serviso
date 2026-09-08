import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/session_controller.dart';

final presenceServiceProvider = Provider<PresenceService>((ref) {
  final service = PresenceService(ref);
  ref.onDispose(service.dispose);
  return service;
});

class PresenceService with WidgetsBindingObserver {
  PresenceService(this._ref) {
    WidgetsBinding.instance.addObserver(this);
    _initSessionListener();
  }

  final Ref _ref;
  Timer? _timer;
  DateTime? _lastPingTime;
  static const Duration _interval = Duration(minutes: 3);
  static const Duration _throttle = Duration(seconds: 45);

  void _initSessionListener() {
    _ref.listen(sessionProvider, (prev, next) {
      final profile = next.valueOrNull;
      if (profile != null && profile.isActive) {
        startHeartbeat();
      } else {
        stopHeartbeat();
      }
    });

    final currentProfile = _ref.read(sessionProvider).valueOrNull;
    if (currentProfile != null && currentProfile.isActive) {
      startHeartbeat();
    }
  }

  void startHeartbeat() {
    _timer?.cancel();
    ping();
    _timer = Timer.periodic(_interval, (_) => ping());
  }

  void stopHeartbeat() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> ping({bool force = false}) async {
    final now = DateTime.now();
    if (!force && _lastPingTime != null && now.difference(_lastPingTime!) < _throttle) {
      return;
    }

    final session = _ref.read(sessionProvider).valueOrNull;
    if (session == null || !session.isActive) return;

    _lastPingTime = now;
    try {
      await _ref.read(authRepositoryProvider).updateLastSeen();
    } catch (_) {
      // Best-effort ping
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      startHeartbeat();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      stopHeartbeat();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timer = null;
  }
}
