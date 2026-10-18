import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_order_button/screens/signup_screen.dart';
import 'package:smart_order_button/screens/signup/widgets/widgets.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  setUp(() {
    // Ensures predictable environment
  });

  group('Story 4.2 - Modular SignUp Step Components Tests', () {
    testWidgets('StepWelcomeView renders title, illustrations, and invokes callbacks', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool started = false;
      bool loggedIn = false;

      await tester.pumpWidget(
        buildTestableWidget(
          StepWelcomeView(
            onStart: () => started = true,
            onLogin: () => loggedIn = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cùng cài đặt thiết bị của bạn nhé!'), findsOneWidget);
      expect(find.text('Chỉ mất khoảng 2 phút.'), findsOneWidget);
      expect(find.text('Một nút nhấn nhỏ. Kết nối thật dễ.'), findsOneWidget);

      await tester.tap(find.text('Bắt đầu'));
      await tester.pumpAndSettle();
      expect(started, isTrue);

      await tester.tap(find.text('Tôi đã có tài khoản'));
      await tester.pumpAndSettle();
      expect(loggedIn, isTrue);
    });

    testWidgets('StepIdentityForm validates inputs with PhoneValidator and invokes onContinue', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      String? submittedName;
      String? submittedPhone;

      await tester.pumpWidget(
        buildTestableWidget(
          StepIdentityForm(
            initialName: 'Nguyễn Văn A',
            initialPhone: '0901234567',
            onContinue: (name, phone) {
              submittedName = name;
              submittedPhone = phone;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bạn tên là gì?'), findsOneWidget);
      expect(find.text('Họ và tên'), findsOneWidget);
      expect(find.text('Số điện thoại'), findsOneWidget);

      // Verify submit works with valid initial values
      await tester.tap(find.text('Gửi mã xác nhận'));
      await tester.pumpAndSettle();

      expect(submittedName, equals('Nguyễn Văn A'));
      expect(submittedPhone, equals('0901234567'));
    });

    testWidgets('StepOtpVerification renders masked phone and invokes edit phone callback', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool editPhoneCalled = false;

      await tester.pumpWidget(
        buildTestableWidget(
          StepOtpVerification(
            phone: '0912345123',
            onEditPhone: () => editPhoneCalled = true,
            onVerified: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Nhập mã gồm 6 số'), findsOneWidget);
      expect(find.text('+84 91xx xxx 123'), findsOneWidget); // Masked phone format
      expect(find.text('Sửa số'), findsOneWidget);

      await tester.tap(find.text('Sửa số'));
      await tester.pump();
      expect(editPhoneCalled, isTrue);
    });

    testWidgets('StepBlePairingView renders wake device prompt', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestableWidget(
          StepBlePairingView(
            onPairingComplete: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đánh thức thiết bị của bạn'), findsOneWidget);
      expect(find.text('Xanh dương nhấp nháy'), findsOneWidget);
      expect(find.text('Đèn đã nhấp nháy xanh'), findsOneWidget);
    });

    testWidgets('StepWifiSetupView renders 2.4GHz and 5GHz network items and reacts to tap', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestableWidget(
          StepWifiSetupView(
            onWifiConnected: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chọn WiFi cho thiết bị'), findsOneWidget);
      expect(find.text('Nhà Minh'), findsOneWidget);
      expect(find.text('Nhà Minh_5G'), findsOneWidget);

      // Tap 5GHz network should display SnackBar warning
      await tester.tap(find.text('Nhà Minh_5G'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Nút bấm chỉ hỗ trợ Wi-Fi băng tần 2.4GHz!'), findsOneWidget);
    });

    testWidgets('StepSuccessView renders connected state and invokes completion callbacks', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool finished = false;
      bool addAnother = false;

      await tester.pumpWidget(
        buildTestableWidget(
          StepSuccessView(
            fullName: 'Minh',
            deviceName: 'Nút nhấn · A3F9',
            wifiSsid: 'Nhà Minh',
            onFinish: () => finished = true,
            onAddAnotherDevice: () => addAnother = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Xong rồi, Minh!'), findsOneWidget);
      expect(find.text('Nút nhấn · A3F9'), findsOneWidget);
      expect(find.text('Đã kết nối'), findsOneWidget);

      await tester.tap(find.text('Vào ứng dụng'));
      await tester.pumpAndSettle();
      expect(finished, isTrue);

      await tester.tap(find.text('Thêm thiết bị khác'));
      await tester.pumpAndSettle();
      expect(addAnother, isTrue);
    });

    testWidgets('SignUpScreen orchestrator initializes at step 0 and step 1 properly', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: SignUpScreen(initialStep: 0),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cùng cài đặt thiết bị của bạn nhé!'), findsOneWidget);

      // Advance to step 1
      await tester.tap(find.text('Bắt đầu'));
      await tester.pumpAndSettle();

      expect(find.text('Bước 1/5'), findsOneWidget);
      expect(find.text('Bạn tên là gì?'), findsOneWidget);
    });
  });
}
