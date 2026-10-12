import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../l10n/lang.dart';
import 'package:provider/provider.dart';
import '../services/session_state.dart';
import '../services/pin_service.dart';
import '../theme/app_theme.dart';
import '../widgets/keypad.dart';
import '../widgets/pin_dots.dart';
import 'profile_setup_screen.dart';

class PinSetupScreen extends StatefulWidget {
  final bool isChangingPin;
  
  const PinSetupScreen({super.key, this.isChangingPin = false});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _entered = '';
  bool _isSaving = false;

  void _onDigit(String digit) {
    if (_entered.length >= 4 || _isSaving) return;
    setState(() {
      _entered += digit;
    });
  }

  void _onDelete() {
    if (_entered.isEmpty || _isSaving) return;
    setState(() {
      _entered = _entered.substring(0, _entered.length - 1);
    });
  }

  Future<void> _onContinue() async {
    if (_entered.length == 4 && !_isSaving) {
      setState(() {
        _isSaving = true;
      });
      
      // Save the PIN (CRUD - Create/Update)
      final pinService = await MockPinService.init();
      await pinService.set(_entered);
      
      // Unlock the session immediately so the user can use the app
      if (mounted) {
        final session = context.read<SessionState>();
        session.unlockForTesting(); // Grant access
        
        if (widget.isChangingPin) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t('pin_changed') ?? 'PIN Changed Successfully ✅', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileSetupScreen(),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canContinue = _entered.length == 4;

    return ValueListenableBuilder<Lang>(valueListenable: LangService.current, builder: (context, lang, _) { return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primaryDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Secure Your Privacy',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create a 4-digit PIN',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 48),

                PinDots(
                  filled: _entered.length,
                  error: false,
                ),
                const SizedBox(height: 48),

                Keypad(
                  onDigit: _onDigit,
                  onDelete: _onDelete,
                  enabled: !_isSaving,
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: canContinue && !_isSaving ? _onContinue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canContinue ? AppTheme.primaryDark : AppTheme.primaryColor.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }
}
