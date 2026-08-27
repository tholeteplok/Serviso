import 'package:flutter_test/flutter_test.dart';

import 'package:serviso/core/models/wo_status.dart';
import 'package:serviso/features/workorders/logic/wo_state_machine.dart';

void main() {
  group('WoStateMachine transitions', () {
    test('menunggu -> dikerjakan via start', () {
      expect(WoStateMachine.transition(WoStatus.menunggu, WoEvent.start),
          WoStatus.dikerjakan);
    });

    test('dikerjakan -> selesai via complete', () {
      expect(WoStateMachine.transition(WoStatus.dikerjakan, WoEvent.complete),
          WoStatus.selesai);
    });

    test('start hanya menunggu -> dikerjakan', () {
      expect(WoStateMachine.transition(WoStatus.menunggu, WoEvent.start),
          WoStatus.dikerjakan);
      expect(WoStateMachine.transition(WoStatus.dikerjakan, WoEvent.start),
          isNull);
      expect(WoStateMachine.canTransition(WoStatus.dikerjakan, WoEvent.start),
          isFalse);
      expect(WoStateMachine.transition(WoStatus.selesai, WoEvent.start), isNull);
      expect(WoStateMachine.transition(WoStatus.dibatalkan, WoEvent.start),
          isNull);
    });

    test('menunggu -> dibatalkan via cancel', () {
      expect(WoStateMachine.transition(WoStatus.menunggu, WoEvent.cancel),
          WoStatus.dibatalkan);
    });

    test('selesai -> dibatalkan only via cancel (reversal path)', () {
      expect(WoStateMachine.transition(WoStatus.selesai, WoEvent.cancel),
          WoStatus.dibatalkan);
    });

    test('illegal transitions return null', () {
      expect(WoStateMachine.transition(WoStatus.dibatalkan, WoEvent.start), isNull);
      expect(WoStateMachine.transition(WoStatus.dibatalkan, WoEvent.cancel), isNull);
      expect(WoStateMachine.transition(WoStatus.dibatalkan, WoEvent.complete), isNull);
      expect(WoStateMachine.transition(WoStatus.selesai, WoEvent.start), isNull);
      expect(WoStateMachine.transition(WoStatus.selesai, WoEvent.complete), isNull);
      expect(WoStateMachine.transition(WoStatus.menunggu, WoEvent.complete), isNull);
    });

    test('canTransition mirrors transition', () {
      for (final from in WoStatus.values) {
        for (final event in WoEvent.values) {
          final t = WoStateMachine.transition(from, event);
          expect(WoStateMachine.canTransition(from, event), t != null);
        }
      }
    });
  });
}
