import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_order_button/models/order_model.dart';
import 'package:smart_order_button/providers/order_provider.dart';
import 'package:smart_order_button/providers/user_provider.dart';
import 'package:smart_order_button/screens/forgot_info_screen.dart';
import 'package:smart_order_button/screens/orders/widgets/order_card_item.dart';
import 'package:smart_order_button/screens/orders/widgets/payos_qr_payment_sheet.dart';
import 'package:smart_order_button/services/api_client.dart';
import 'package:smart_order_button/services/auth_api_service.dart';
import 'package:smart_order_button/services/payments_api_service.dart';
import 'package:smart_order_button/services/user_profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ApiClient api;
  http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );
  OrderModel order(
    String status, {
    String payment = 'PAID',
    int amount = 100,
  }) => OrderModel.fromJson({
    'orderId': status,
    'orderStatus': status,
    'paymentStatus': payment,
    'totalAmount': amount,
  });

  setUp(() async {
    api = ApiClient();
    SharedPreferences.setMockInitialValues({});
    await api.clearTokens();
    await api.setTokens(accessToken: 'test-only');
    UserProfileService().reset();
  });
  tearDown(() async {
    api.testClient = http.Client();
    await api.clearTokens();
    UserProfileService().reset();
  });

  test(
    'F01: retry reuses key and payload; new attempt receives a new key',
    () async {
      final keys = <String>[];
      final bodies = <String>[];
      api.testClient = MockClient((request) async {
        keys.add(
          request.headers['X-Idempotency-Key'] ??
              request.headers['x-idempotency-key'] ??
              '',
        );
        bodies.add(request.body);
        return jsonResponse({'message': 'Temporary failure'}, 503);
      });
      final key = PaymentsApiService.newPaymentKey();
      for (var i = 0; i < 2; i++) {
        await expectLater(
          PaymentsApiService().createPayosPaymentLink(
            orderId: '42',
            idempotencyKey: key,
          ),
          throwsA(isA<ApiException>()),
        );
      }
      await expectLater(
        PaymentsApiService().createPayosPaymentLink(orderId: '42'),
        throwsA(isA<ApiException>()),
      );
      expect(keys.take(2), [key, key]);
      expect(keys.last, isNot(key));
      expect(keys.every((key) => key.length >= 32), isTrue);
      expect(bodies.toSet(), hasLength(1));
    },
  );

  testWidgets('F01: QR sheet keeps the same key after a failed request', (
    tester,
  ) async {
    final keys = <String?>[];
    api.testClient = MockClient((request) async {
      keys.add(request.headers['X-Idempotency-Key']);
      return jsonResponse({'message': 'Temporary failure'}, 503);
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PayosQrPaymentSheet(
            order: OrderModel.fromJson({
              'orderId': '42',
              'orderStatus': 'PENDING',
            }),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(keys, hasLength(2));
    expect(keys.first, isNotEmpty);
    expect(keys.last, keys.first);
    await tester.pumpWidget(const SizedBox());
  });

  test(
    'F03: PATCH profile, only update local state after server success',
    () async {
      final response = Completer<http.Response>();
      api.testClient = MockClient((request) {
        expect(request.method, 'PATCH');
        expect(request.url.path, endsWith('/auth/me'));
        expect(jsonDecode(request.body), {'fullName': 'New Name'});
        return response.future;
      });
      UserProfileService().updateName('Old Name');
      final provider = UserProvider();
      final pending = provider.updateName('New Name');
      expect(provider.name, 'Old Name');
      response.complete(
        jsonResponse({
          'success': true,
          'data': {'fullName': 'Saved Name'},
        }),
      );
      await pending;
      expect(provider.name, 'Saved Name');
      provider.dispose();
    },
  );

  test(
    'F03: backend failure propagates without changing saved profile',
    () async {
      api.testClient = MockClient(
        (_) async => jsonResponse({'message': 'Rejected'}, 400),
      );
      UserProfileService().updateName('Old Name');
      final provider = UserProvider();
      await expectLater(
        provider.updateName('New Name'),
        throwsA(isA<ApiException>()),
      );
      expect(provider.name, 'Old Name');
      expect(provider.errorMessage, contains('Rejected'));
      provider.dispose();
    },
  );

  test(
    'F03: unsupported profile fields never appear saved or reach the server',
    () async {
      api.testClient = MockClient(
        (_) async => throw StateError('Unexpected request'),
      );
      final provider = UserProvider();
      await expectLater(
        provider.updateEmail('new@example.com'),
        throwsStateError,
      );
      await expectLater(
        provider.updateAddress('New address'),
        throwsStateError,
      );
      expect(provider.email, isEmpty);
      expect(provider.address, isEmpty);
      await expectLater(
        AuthApiService().updateProfile(email: 'new@example.com'),
        throwsA(isA<ApiException>()),
      );
      provider.dispose();
    },
  );

  testWidgets('F04: request failure stays on email step', (tester) async {
    api.testClient = MockClient(
      (_) async => jsonResponse({'message': 'Too many requests'}, 429),
    );
    await tester.pumpWidget(const MaterialApp(home: ForgotInfoScreen()));
    await tester.enterText(
      find.byKey(const Key('recovery-email')),
      'person@example.com',
    );
    await tester.tap(find.text('Gửi mã xác thực'));
    await tester.pumpAndSettle();
    expect(find.text('Too many requests'), findsOneWidget);
    expect(find.byKey(const Key('recovery-otp')), findsNothing);
  });

  testWidgets(
    'F04: invalid OTP stays in form; successful reset sends email, token and password',
    (tester) async {
      var failReset = true;
      var forgotRequests = 0;
      api.testClient = MockClient((request) async {
        final body = jsonDecode(request.body);
        if (request.url.path.endsWith('/forgot-password')) {
          forgotRequests++;
          expect(body, {'email': 'person@example.com'});
          return jsonResponse({'success': true});
        }
        expect(request.url.path, endsWith('/reset-password'));
        expect(body, {
          'email': 'person@example.com',
          'token': '123456',
          'newPassword': 'NewPassword1!',
        });
        return failReset
            ? jsonResponse({'message': 'Mã không hợp lệ hoặc đã hết hạn'}, 400)
            : jsonResponse({'success': true});
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const ForgotInfoScreen(),
                  ),
                ),
                child: const Text('Open recovery'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open recovery'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('recovery-email')),
        'Person@Example.com',
      );
      await tester.tap(find.text('Gửi mã xác thực'));
      await tester.pumpAndSettle();
      expect(forgotRequests, 1);
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Gửi lại sau 60s'),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(find.byKey(const Key('recovery-otp')), '123456');
      await tester.enterText(
        find.byKey(const Key('recovery-password')),
        'NewPassword1!',
      );
      await tester.enterText(
        find.byKey(const Key('recovery-confirmation')),
        'NewPassword1!',
      );
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Đặt lại mật khẩu'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Đặt lại mật khẩu'));
      await tester.pumpAndSettle();
      expect(find.text('Mã không hợp lệ hoặc đã hết hạn'), findsOneWidget);
      expect(find.byType(ForgotInfoScreen), findsOneWidget);
      failReset = false;
      await tester.tap(find.widgetWithText(FilledButton, 'Đặt lại mật khẩu'));
      await tester.pumpAndSettle();
      expect(find.byType(ForgotInfoScreen), findsNothing);
    },
  );

  test(
    'F05: preparation, ready and failed delivery remain active; spend excludes unfinished/rejected/refunded',
    () {
      final provider = OrderProvider(
        initialOrders: [
          order('PREPARING'),
          order('READY_FOR_DELIVERY'),
          order('DELIVERY_FAILED'),
          order('REJECTED'),
          order('CANCELLED'),
          order('DELIVERED'),
          order('COMPLETED'),
          order('COMPLETED', payment: 'REFUNDED'),
          order('DELIVERED', payment: 'UNPAID'),
        ],
      );
      expect(provider.activeOrders.map((order) => order.rawStatus), [
        'PREPARING',
        'READY_FOR_DELIVERY',
        'DELIVERY_FAILED',
      ]);
      expect(provider.historyOrders, hasLength(6));
      expect(provider.totalSpend, 200);
      expect(order('PREPARING').statusText, 'Đang chuẩn bị');
      expect(order('READY_FOR_DELIVERY').statusText, 'Sẵn sàng giao');
      expect(order('REJECTED').canPay, isFalse);
      expect(order('DELIVERY_FAILED').canPay, isFalse);
      provider.dispose();
    },
  );

  testWidgets(
    'F05: failed delivery does not display a successful delivery timeline',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: OrderTimeline(rawStatus: 'DELIVERY_FAILED')),
        ),
      );
      expect(find.text('Giao hàng thất bại'), findsOneWidget);
      expect(find.text('Đã giao hàng'), findsNothing);
    },
  );
}
