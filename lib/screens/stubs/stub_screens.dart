import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../main_screen.dart';

/// Placeholder for a screen owned by another team member.
///
/// Exists only to prove navigation works. Do not build real features here.
class StubScreen extends StatelessWidget {
  final String title;
  final String owner;
  final IconData icon;

  const StubScreen({
    super.key,
    required this.title,
    required this.owner,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Coming soon ($owner)',
                style: const TextStyle(color: AppTheme.textLight),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Member 1: language selection and onboarding.
class OnboardingStubScreen extends StatelessWidget {
  const OnboardingStubScreen({super.key});

  @override
  Widget build(BuildContext context) => const StubScreen(
        title: 'Onboarding',
        owner: 'Member 1',
        icon: Icons.waving_hand_outlined,
      );
}

/// Member 1: PIN setup.
class PinSetupStubScreen extends StatelessWidget {
  const PinSetupStubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set up your PIN'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 56, color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              Text('Set up your PIN', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Coming soon (Member 1)',
                style: TextStyle(color: AppTheme.textLight),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                  );
                },
                child: const Text('Continue to App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Member 4: pharmacy directory.
class PharmacyStubScreen extends StatelessWidget {
  const PharmacyStubScreen({super.key});

  @override
  Widget build(BuildContext context) => const StubScreen(
        title: 'Find help nearby',
        owner: 'Member 4',
        icon: Icons.local_pharmacy_outlined,
      );
}
