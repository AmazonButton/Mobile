import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/phone_auth_service.dart';
import '../services/auth_api_service.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'signup/widgets/widgets.dart';

/// Màn hình Đăng ký & Onboarding thiết bị Smart Order Button
/// Orchestrator điều phối 5 bước kết nối chuẩn theo Figma: "Một nút nhấn. Năm bước kết nối"
class SignUpScreen extends StatefulWidget {
  final int
  initialStep; // 0: Chào mừng, 1: Bước 1, 2: Bước 2, 3: Bước 3, 4: Bước 4, 5: Bước 5
  final PhoneAuthService? phoneAuthService;
  final AuthApiService? authApiService;
  final String initialPhone;

  const SignUpScreen({
    super.key,
    this.initialStep = 0,
    this.phoneAuthService,
    this.authApiService,
    this.initialPhone = '',
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  late final PageController _pageController;
  late int _currentStep;

  // Global Keys to access subphase back handling in Step 3 and Step 4
  final GlobalKey<StepBlePairingViewState> _bleStepKey =
      GlobalKey<StepBlePairingViewState>();
  final GlobalKey<StepWifiSetupViewState> _wifiStepKey =
      GlobalKey<StepWifiSetupViewState>();

  // Confirmed resident identity
  String _confirmedFullName = '';
  String _confirmedPhone = '';
  String _verificationId = '';
  int? _resendToken;
  bool _isSendingOtp = false;
  bool _otpBusy = false;
  bool _registered = false;
  int _otpSession = 0;
  int _otpRequest = 0;
  PhoneAuthCredential? _autoCredential;
  bool get _authBusy => _isSendingOtp || _otpBusy;

  @override
  void initState() {
    super.initState();
    _confirmedPhone = widget.initialPhone;
    _currentStep = widget.initialStep;
    _pageController = PageController(initialPage: _currentStep);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    FocusScope.of(context).unfocus();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (!reduceMotion) HapticFeedback.lightImpact();
    setState(() => _currentStep = step);
    if (reduceMotion) {
      _pageController.jumpToPage(step);
      return;
    }
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleBack() {
    if (_authBusy) return;
    HapticFeedback.lightImpact();
    if (_currentStep == 1 && widget.initialStep == 1) {
      Navigator.of(context).pop();
      return;
    }
    if (_currentStep == 0) {
      Navigator.of(context).pop();
      return;
    }

    if (_currentStep == 3 &&
        (_bleStepKey.currentState?.handleBack() ?? false)) {
      return;
    }

    if (_currentStep == 4 &&
        (_wifiStepKey.currentState?.handleBack() ?? false)) {
      return;
    }

    if (_currentStep == 2) {
      _editPhone();
    } else if (_currentStep == 3 && _registered) {
      _goToStep(0);
    } else {
      _goToStep(_currentStep - 1);
    }
  }

  void _onStep1Submit(String name, String phone) async {
    if (_authBusy || _registered) return;
    setState(() {
      _confirmedFullName = name.trim();
      _confirmedPhone = phone.trim();
      _verificationId = '';
      _resendToken = null;
      _autoCredential = null;
      _otpSession++;
    });
    try {
      await _requestOtp();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: SignupTheme.figmaDanger,
        ),
      );
    }
  }

  void _editPhone() {
    if (_authBusy || _registered) return;
    _otpRequest++;
    _autoCredential = null;
    _verificationId = '';
    _resendToken = null;
    _goToStep(1);
  }

  Future<void> _requestOtp({bool resend = false}) async {
    if (_isSendingOtp || _registered) return;
    final request = ++_otpRequest;
    setState(() {
      _isSendingOtp = true;
      _autoCredential = null;
    });
    final completer = Completer<void>();
    bool isCurrent() => mounted && request == _otpRequest && !_registered;
    void complete() {
      if (!completer.isCompleted) completer.complete();
    }

    // Attach the error handler before Firebase can invoke a callback.
    final completion = completer.future.timeout(const Duration(seconds: 75));
    try {
      unawaited(
        Future<void>.sync(
          () => (widget.phoneAuthService ?? PhoneAuthService()).sendOtp(
            phone: _confirmedPhone,
            resendToken: resend ? _resendToken : null,
            onCodeSent: (newVerificationId, newToken) {
              if (isCurrent() && _autoCredential == null) {
                setState(() {
                  _isSendingOtp = false;
                  _verificationId = newVerificationId;
                  _resendToken = newToken;
                });
                if (_currentStep != 2) _goToStep(2);
              }
              complete();
            },
            onAutoVerify: (credential) {
              if (isCurrent()) {
                setState(() {
                  _isSendingOtp = false;
                  _autoCredential = credential;
                });
                if (_currentStep != 2) _goToStep(2);
              }
              complete();
            },
            onError: (err) {
              if (!completer.isCompleted) {
                completer.completeError(Exception(err));
              }
            },
          ),
        ).catchError((Object error) {
          if (!completer.isCompleted) completer.completeError(error);
        }),
      );
      await completion;
    } on TimeoutException {
      if (isCurrent()) _otpRequest++;
      throw Exception('Gửi mã mất quá nhiều thời gian. Vui lòng thử lại.');
    } catch (_) {
      if (isCurrent()) _otpRequest++;
      rethrow;
    } finally {
      if (mounted && (request == _otpRequest || _isSendingOtp)) {
        setState(() => _isSendingOtp = false);
      }
    }
  }

  void _finishAndGoToApp() {
    HapticFeedback.heavyImpact();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop:
          !_authBusy &&
          (_currentStep == 0 || (_currentStep == 1 && widget.initialStep == 1)),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
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
                      onStart: () => _goToStep(_registered ? 3 : 1),
                      onLogin: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                    ),

                    // Step 1: Resident Identity
                    StepIdentityForm(
                      initialName: _confirmedFullName,
                      initialPhone: _confirmedPhone,
                      isLoading: _isSendingOtp,
                      onContinue: _onStep1Submit,
                    ),

                    // Step 2: OTP Verification
                    StepOtpVerification(
                      key: ValueKey(_otpSession),
                      phone: _confirmedPhone,
                      fullName: _confirmedFullName,
                      verificationId: _verificationId,
                      autoCredential: _autoCredential,
                      phoneAuthService: widget.phoneAuthService,
                      authApiService: widget.authApiService,
                      onBusyChanged: (busy) {
                        if (mounted) setState(() => _otpBusy = busy);
                      },
                      onEditPhone: _editPhone,
                      onVerified: () {
                        _registered = true;
                        _otpRequest++;
                        _goToStep(3);
                      },
                      onResend: () => _requestOtp(resend: true),
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
      ),
    );
  }
}
