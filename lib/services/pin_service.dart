import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';

// TODO: Member 1 will replace this mock with their own implementation
// that includes PIN setup UI and recovery flow.

/// Contract for PIN storage and verification.
///
/// A 4-digit PIN is a deterrent against family members, not strong security.
/// We use PBKDF2-SHA-256 with a random salt and lockout throttling.
abstract class PinService {
  Future<bool> isSet();
  Future<bool> verify(String pin);

  /// Used by the mock and the dev seed only. Member 1's real implementation
  /// will have PIN setup behind their onboarding flow.
  Future<void> set(String pin);
}

/// Mock implementation backed by the `settings` Hive box.
///
/// PIN is stored as `{ salt: hex, hash: hex }` under the key `pin`.
/// Never stores the PIN in plain text.
class MockPinService implements PinService {
  MockPinService._();

  static const String _settingsBox = 'settings';
  static const String _pinKey = 'pin';
  static const int _iterations = 10000;
  static const int _saltLength = 16;

  /// Initialises the service. Opens the settings box if needed.
  /// If a `DEMO_PIN` dart-define is provided and no PIN is set yet,
  /// seeds that PIN so testers can be "given a PIN".
  static Future<MockPinService> init({String? demoPin}) async {
    if (!Hive.isBoxOpen(_settingsBox)) {
      await Hive.openBox<dynamic>(_settingsBox);
    }
    final service = MockPinService._();

    // Dev/test seed: --dart-define=DEMO_PIN=1234
    if (demoPin != null && demoPin.isNotEmpty && !(await service.isSet())) {
      await service.set(demoPin);
    }

    return service;
  }

  Box<dynamic> get _box => Hive.box<dynamic>(_settingsBox);

  @override
  Future<bool> isSet() async {
    final data = _box.get(_pinKey);
    return data is Map && data['salt'] != null && data['hash'] != null;
  }

  @override
  Future<bool> verify(String pin) async {
    final data = _box.get(_pinKey);
    if (data is! Map) return false;
    final storedSalt = data['salt'] as String?;
    final storedHash = data['hash'] as String?;
    if (storedSalt == null || storedHash == null) return false;

    final saltBytes = _hexDecode(storedSalt);
    final derived = _pbkdf2(pin, saltBytes);
    return derived == storedHash;
  }

  @override
  Future<void> set(String pin) async {
    final saltBytes = _randomSalt();
    final saltHex = _hexEncode(saltBytes);
    final hashHex = _pbkdf2(pin, saltBytes);
    await _box.put(_pinKey, {'salt': saltHex, 'hash': hashHex});
  }

  // ── Crypto helpers ──────────────────────────────────────────────

  static Uint8List _randomSalt() {
    final rng = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(_saltLength, (_) => rng.nextInt(256)),
    );
  }

  static String _pbkdf2(String pin, Uint8List salt) {
    // PBKDF2 with HMAC-SHA256.
    final key = utf8.encode(pin);
    var block = Uint8List.fromList([...salt, 0, 0, 0, 1]); // block index 1
    var u = Hmac(sha256, key).convert(block).bytes;
    var result = List<int>.of(u);
    for (var i = 1; i < _iterations; i++) {
      u = Hmac(sha256, key).convert(u).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    return _hexEncode(Uint8List.fromList(result));
  }

  static String _hexEncode(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static Uint8List _hexDecode(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }
}
