import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pinput/pinput.dart';
import 'package:smart_order_button/screens/register_step_two_screen.dart';
import 'package:smart_order_button/models/user_profile_service.dart';

void main() {
  testWidgets('RegisterStepTwoScreen renders all required elements per design spec', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RegisterStepTwoScreen(
          fullName: 'Nguyễn Văn A',
          phoneNumber: '0901234567',
          email: 'nguyenvana@gmail.com',
        ),
      ),
    );

    // Initial pump for entry animation
    await tester.pumpAndSettle();

    // 1. Header checks
    expect(find.byIcon(LucideIcons.chevronLeft), findsOneWidget);
    expect(find.text('Tạo tài khoản'), findsOneWidget);
    expect(find.text('Bước 2/2'), findsOneWidget);

    // 2. OTP section checks
    expect(find.text('XÁC THỰC SỐ ĐIỆN THOẠI'), findsOneWidget);
    expect(find.byType(Pinput), findsOneWidget);
    expect(find.textContaining('Chưa nhận được mã?'), findsOneWidget);
    expect(find.textContaining('Gửi lại'), findsOneWidget);

    // 3. Security Section checks
    expect(find.text('THIẾT LẬP BẢO MẬT'), findsOneWidget);
    expect(find.text('Mật khẩu (ít nhất 8 ký tự)'), findsOneWidget);
    expect(find.text('Xác nhận mật khẩu'), findsOneWidget);
    expect(find.byIcon(LucideIcons.lock), findsNWidgets(2));
    expect(find.byIcon(LucideIcons.eye), findsNWidgets(2));

    // 4. Bottom action button checks
    expect(find.text('Hoàn tất đăng ký'), findsOneWidget);

    // 5. Test Password visibility toggle
    final eyeButtons = find.byIcon(LucideIcons.eye);
    await tester.tap(eyeButtons.first);
    await tester.pumpAndSettle();
    expect(find.byIcon(LucideIcons.eyeOff), findsOneWidget);

    // 6. Test empty submit validation
    await tester.tap(find.text('Hoàn tất đăng ký'));
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập đủ 6 chữ số OTP'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);

    // 7. Test filling OTP and mismatched password
    final pinputFinder = find.byType(Pinput);
    await tester.enterText(pinputFinder, '123456');
    await tester.pumpAndSettle();

    final textFields = find.byType(TextField);
    // index 0 is password, index 1 is confirm password
    await tester.enterText(textFields.at(0), 'password123');
    await tester.enterText(textFields.at(1), 'mismatched123');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hoàn tất đăng ký'));
    await tester.pumpAndSettle();
    expect(find.text('Mật khẩu xác nhận không khớp'), findsOneWidget);

    // 8. Fix confirmation password and submit successfully
    await tester.enterText(textFields.at(1), 'password123');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hoàn tất đăng ký'));
    // Wait for the simulated async delay (900ms)
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();

    // Check success modal
    expect(find.text('Đăng ký thành công!'), findsOneWidget);
    expect(find.text('Bắt đầu sử dụng SmartTap'), findsOneWidget);

    // Verify UserProfileService was updated
    expect(UserProfileService().name, 'Nguyễn Văn A');
    expect(UserProfileService().phone, '0901234567');
  });
}
