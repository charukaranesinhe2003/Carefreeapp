import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'screens/initial_onboarding_screen.dart';
import 'screens/privacy_lock_screen.dart';
import 'screens/main_screen.dart';
import 'screens/widget_kit_screen.dart';
import 'services/local_storage_service.dart';
import 'services/pin_service.dart';
import 'services/saved_articles_store.dart';
import 'services/session_state.dart';
import 'services/starred_tips_store.dart';
import 'services/daily_log_store.dart';
import 'theme/app_theme.dart';
import 'widgets/test_mode_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Offline-first: fonts are bundled in assets/google_fonts, never fetched at runtime.
  GoogleFonts.config.allowRuntimeFetching = false;

  await LocalStorageService.init();
  await SavedArticlesStore.init();
  await StarredTipsStore.init();
  await DailyLogStore.init();

  // Dev/test seed: flutter run --dart-define=DEMO_PIN=1234
  const demoPin = String.fromEnvironment('DEMO_PIN');
  final pinService = await MockPinService.init(
    demoPin: demoPin.isNotEmpty ? demoPin : null,
  );

  runApp(CycleCareApp(pinService: pinService));
}

class CycleCareApp extends StatelessWidget {
  const CycleCareApp({super.key, required this.pinService});

  final PinService pinService;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SessionState>(
      create: (_) => SessionState(pinService: pinService),
      child: MaterialApp(
        title: 'Cycle Care',
        theme: AppTheme.lightTheme,
        home: FutureBuilder<bool>(
          future: pinService.isSet(),
          builder: (context, snapshot) {
            // While checking, show a blank loading screen or splash
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: AppTheme.backgroundColor,
                body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
              );
            }
            
            final isPinSet = snapshot.data ?? false;
            
            if (isPinSet) {
              // Old user -> Ask for PIN
              return const PrivacyLockScreen();
            } else {
              // New user -> Setup flow
              return const InitialOnboardingScreen();
            }
          },
        ),
        debugShowCheckedModeBanner: false,
        builder: (context, child) =>
            TestModeOverlay(child: child ?? const SizedBox()),
        routes: {
          // Debug-only widget kit screen (Phase 1 accept criteria).
          if (kDebugMode) '/kit': (_) => const WidgetKitScreen(),
        },
      ),
    );
  }
}

