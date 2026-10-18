import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/user_profile_service.dart';
import 'dashboard_screen.dart';
import 'signup/widgets/widgets.dart';

/// Màn hình Đăng ký & Onboarding thiết bị Smart Order Button
/// Orchestrator điều phối 5 bước kết nối chuẩn theo Figma: "Một nút nhấn. Năm bước kết nối"
class SignUpScreen extends StatefulWidget {
  final int initialStep; // 0: Chào mừng, 1: Bước 1, 2: Bước 2, 3: Bước 3, 4: Bước 4, 5: Bước 5

  const SignUpScreen({
    super.key,
    this.initialStep = 0,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  late final PageController _pageController;
  late int _currentStep;

  // Global Keys to access subphase back handling in Step 3 and Step 4
  final GlobalKey<StepBlePairingViewState> _bleStepKey = GlobalKey<StepBlePairingViewState>();
  final GlobalKey<StepWifiSetupViewState> _wifiStepKey = GlobalKey<StepWifiSetupViewState>();

  // Confirmed resident identity
  String _confirmedFullName = 'Minh';
  String _confirmedPhone = '0912345123';

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    _pageController = PageController(initialPage: _currentStep);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    HapticFeedback.lightImpact();
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleBack() {
    HapticFeedback.lightImpact();
    if (_currentStep == 0) {
      Navigator.of(context).pop();
      return;
    }

    if (_currentStep == 3 && (_bleStepKey.currentState?.handleBack() ?? false)) {
      return;
    }

    if (_currentStep == 4 && (_wifiStepKey.currentState?.handleBack() ?? false)) {
      return;
    }

    _goToStep(_currentStep - 1);
  }

  void _onStep1Submit(String name, String phone) {
    _confirmedFullName = name;
    _confirmedPhone = phone;

    UserProfileService().updateName(_confirmedFullName);
    UserProfileService().updatePhone(_confirmedPhone);

    _goToStep(2);
  }

  void _finishAndGoToApp() {
    HapticFeedback.heavyImpact();
    UserProfileService().updateName(_confirmedFullName);
    UserProfileService().updatePhone(_confirmedPhone);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SignupTheme.figmaBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Stepper & Navigation Bar
            SignupTopStepper(
              currentStep: _currentStep,
              onBack: _handleBack,
              onHelp: () => showSignupHelpBottomSheet(context),
            ),

            // Page Views (0..5)
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Step 0: Welcome
                  StepWelcomeView(
                    onStart: () => _goToStep(1),
                    onLogin: () => Navigator.of(context).pop(),
                  ),

                  // Step 1: Resident Identity
                  StepIdentityForm(
                    initialName: _confirmedFullName,
                    initialPhone: _confirmedPhone,
                    onContinue: _onStep1Submit,
                  ),

                  // Step 2: OTP Verification
                  StepOtpVerification(
                    phone: _confirmedPhone,
                    onEditPhone: () => _goToStep(1),
                    onVerified: () => _goToStep(3),
                  ),

                  // Step 3: BLE Discovery & Pairing
                  StepBlePairingView(
                    key: _bleStepKey,
                    onPairingComplete: () => _goToStep(4),
                  ),

                  // Step 4: WiFi Setup
                  StepWifiSetupView(
                    key: _wifiStepKey,
                    onWifiConnected: () => _goToStep(5),
                  ),

                  // Step 5: Success & Completion
                  StepSuccessView(
                    fullName: _confirmedFullName,
                    onFinish: _finishAndGoToApp,
                    onAddAnotherDevice: () => _goToStep(3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
