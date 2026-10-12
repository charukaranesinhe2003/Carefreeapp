import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

import 'package:cycle_care/services/pin_service.dart';
import 'package:cycle_care/services/session_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPinService pinService;
  late SessionState session;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    Hive.init('./test_hive_session');
    if (Hive.isBoxOpen('settings')) {
      await Hive.box<dynamic>('settings').clear();
    }
    pinService = await MockPinService.init(demoPin: '1234');
    session = SessionState(pinService: pinService);
  });

  tearDown(() async {
    session.dispose();
    await Hive.deleteFromDisk();
  });

  group('SessionState', () {
    test('starts locked', () {
      expect(session.unlocked, isFalse);
    });

    test('tryUnlock with correct PIN sets unlocked to true', () async {
      final ok = await session.tryUnlock('1234');
      expect(ok, isTrue);
      expect(session.unlocked, isTrue);
    });

    test('tryUnlock with wrong PIN keeps locked', () async {
      final ok = await session.tryUnlock('0000');
      expect(ok, isFalse);
      expect(session.unlocked, isFalse);
    });

    test('failCount increments on wrong attempts', () async {
      expect(session.failCount, 0);
      await session.tryUnlock('0000');
      expect(session.failCount, 1);
      await session.tryUnlock('0000');
      expect(session.failCount, 2);
    });

    test('correct PIN resets failCount', () async {
      await session.tryUnlock('0000');
      await session.tryUnlock('0000');
      expect(session.failCount, 2);

      await session.tryUnlock('1234');
      expect(session.failCount, 0);
    });

    test('locks out after $maxAttempts wrong attempts', () async {
      for (var i = 0; i < SessionState.maxAttempts; i++) {
        await session.tryUnlock('0000');
      }
      expect(session.isLockedOut, isTrue);
      expect(session.lockoutRemaining, greaterThan(0));
      expect(session.lockoutRemaining, lessThanOrEqualTo(30));
    });

    test('tryUnlock returns false while locked out', () async {
      for (var i = 0; i < SessionState.maxAttempts; i++) {
        await session.tryUnlock('0000');
      }
      // Even the correct PIN is rejected while locked out.
      final ok = await session.tryUnlock('1234');
      expect(ok, isFalse);
    });

    test('lock() re-locks the session', () async {
      await session.tryUnlock('1234');
      expect(session.unlocked, isTrue);
      session.lock();
      expect(session.unlocked, isFalse);
    });

    test('lockout survives recreation (persisted)', () async {
      for (var i = 0; i < SessionState.maxAttempts; i++) {
        await session.tryUnlock('0000');
      }
      expect(session.isLockedOut, isTrue);

      // Simulate app restart: create a new SessionState reading the same box.
      session.dispose();
      session = SessionState(pinService: pinService);
      expect(session.isLockedOut, isTrue);
      expect(session.lockoutRemaining, greaterThan(0));
    });

    test('notifies listeners on state changes', () async {
      var notified = 0;
      session.addListener(() => notified++);

      await session.tryUnlock('0000'); // wrong
      expect(notified, 1);

      await session.tryUnlock('1234'); // correct
      expect(notified, 2);

      session.lock();
      expect(notified, 3);
    });
  });
}

const maxAttempts = SessionState.maxAttempts;
