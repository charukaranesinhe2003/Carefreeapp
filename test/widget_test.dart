import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:cycle_care/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Tests must never hit the network for fonts.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('AppTheme exposes the core brand colours', () {
    expect(AppTheme.primaryColor, const Color(0xFFE97495));
    expect(AppTheme.backgroundColor, const Color(0xFFFDF2F8));
  });
}
