import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

import 'package:cycle_care/services/pin_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    // Hive needs a temp directory for tests.
    Hive.init('./test_hive_pin');
    // Clean slate: delete the settings box if it exists.
    if (Hive.isBoxOpen('settings')) {
      await Hive.box<dynamic>('settings').clear();
    }
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  group('MockPinService', () {
    test('isSet returns false when no PIN is configured', () async {
      final service = await MockPinService.init();
      expect(await service.isSet(), isFalse);
    });

    test('set() makes isSet() return true', () async {
      final service = await MockPinService.init();
      await service.set('1234');
      expect(await service.isSet(), isTrue);
    });

    test('verify returns true for the correct PIN', () async {
      final service = await MockPinService.init();
      await service.set('5678');
      expect(await service.verify('5678'), isTrue);
    });

    test('verify returns false for the wrong PIN', () async {
      final service = await MockPinService.init();
      await service.set('5678');
      expect(await service.verify('0000'), isFalse);
      expect(await service.verify('5679'), isFalse);
      expect(await service.verify(''), isFalse);
    });

    test('verify returns false when no PIN is set', () async {
      final service = await MockPinService.init();
      expect(await service.verify('1234'), isFalse);
    });

    test('changing the PIN invalidates the old one', () async {
      final service = await MockPinService.init();
      await service.set('1111');
      expect(await service.verify('1111'), isTrue);

      await service.set('2222');
      expect(await service.verify('1111'), isFalse);
      expect(await service.verify('2222'), isTrue);
    });

    test('DEMO_PIN seed sets the PIN on first run', () async {
      final service = await MockPinService.init(demoPin: '1234');
      expect(await service.isSet(), isTrue);
      expect(await service.verify('1234'), isTrue);
    });

    test('DEMO_PIN does not overwrite an existing PIN', () async {
      final service1 = await MockPinService.init();
      await service1.set('9999');

      // Re-init with a different demo pin.
      final service2 = await MockPinService.init(demoPin: '1234');
      expect(await service2.verify('9999'), isTrue);
      expect(await service2.verify('1234'), isFalse);
    });

    test('hash is different for different PINs', () async {
      final service = await MockPinService.init();
      await service.set('1234');
      final box = Hive.box<dynamic>('settings');
      final data1 = Map<String, dynamic>.from(box.get('pin') as Map);

      await service.set('5678');
      final data2 = Map<String, dynamic>.from(box.get('pin') as Map);

      // Different salt and hash.
      expect(data1['hash'], isNot(data2['hash']));
    });

    test('stored data has salt and hash, never plain text', () async {
      final service = await MockPinService.init();
      await service.set('1234');
      final box = Hive.box<dynamic>('settings');
      final data = box.get('pin') as Map;
      expect(data['salt'], isA<String>());
      expect(data['hash'], isA<String>());
      expect(data.containsKey('pin'), isFalse,
          reason: 'PIN should never be stored in plain text');
      // Salt should be 16 bytes = 32 hex chars.
      expect((data['salt'] as String).length, 32);
    });
  });
}
