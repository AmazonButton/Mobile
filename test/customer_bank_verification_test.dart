import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smart_order_button/models/customer_bank_account.dart';
import 'package:smart_order_button/screens/customer_bank_accounts_screen.dart';
import 'package:smart_order_button/services/api_client.dart';
import 'package:smart_order_button/services/customer_bank_api_service.dart';

void main() {
  late ApiClient api;
  const account = CustomerBankAccount(
    id: '7',
    bankName: 'Test Bank',
    maskedNumber: '******1234',
    accountName: 'TEST USER',
    verificationStatus: 'PENDING',
    isDefault: true,
  );
  http.Response response(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    api = ApiClient();
    await api.setTokens(accessToken: 'test-only');
  });
  tearDown(() => api.testClient = http.Client());

  test('F07: receiving 2,000 VND alone does not verify ownership', () {
    final state = BankVerificationState.fromJson({
      'accountVerificationStatus': 'PENDING',
      'session': {
        'paymentStatus': 'PAID',
        'verificationStatus': 'FAILED_MISMATCH',
        'refundStatus': 'PENDING_REFUND',
      },
    });
    expect(state.isVerified, isFalse);
    expect(state.verificationLabel, 'Đã nhận tiền — đang đối chiếu tài khoản');
  });

  test(
    'F07: create uses customer API and only masked account data is retained',
    () async {
      api.testClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, endsWith('/customers/me/bank-accounts'));
        expect(jsonDecode(request.body), {
          'bankBin': '970422',
          'bankName': 'Test Bank',
          'accountNumber': '123456789',
          'accountName': 'TEST USER',
          'isDefault': true,
        });
        return response({
          'data': {
            'id': '7',
            'bankName': 'Test Bank',
            'accountNumberMasked': '******6789',
            'accountName': 'TEST USER',
            'verificationStatus': 'PENDING',
            'isDefault': true,
          },
        });
      });
      final saved = await CustomerBankApiService().addAccount(
        bankBin: '970422',
        bankName: 'Test Bank',
        accountNumber: '123456789',
        accountName: ' test user ',
        isDefault: true,
      );
      expect(saved.maskedNumber, '******6789');
      expect(saved.isVerified, isFalse);
    },
  );

  testWidgets(
    'F07: adding an account through the form displays only the saved masked number',
    (tester) async {
      var created = false;
      api.testClient = MockClient((request) async {
        if (request.url.path.endsWith('/banks')) {
          return response({
            'data': [
              {'bin': '970422', 'name': 'Test Bank', 'shortName': 'Test Bank'},
            ],
          });
        }
        if (request.method == 'POST') {
          expect(jsonDecode(request.body)['accountNumber'], '123456789');
          created = true;
          return response({
            'data': {
              'id': '7',
              'accountNumberMasked': '******6789',
              'bankName': 'Test Bank',
              'accountName': 'TEST USER',
              'verificationStatus': 'PENDING',
            },
          });
        }
        return response({
          'data': created
              ? [
                  {
                    'id': '7',
                    'accountNumberMasked': '******6789',
                    'bankName': 'Test Bank',
                    'accountName': 'TEST USER',
                    'verificationStatus': 'PENDING',
                  },
                ]
              : [],
        });
      });
      await tester.pumpWidget(
        const MaterialApp(home: CustomerBankAccountsScreen()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thêm tài khoản'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Bank').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('bank-number')), '123456789');
      await tester.enterText(find.byKey(const Key('bank-name')), 'TEST USER');
      await tester.ensureVisible(find.text('Lưu tài khoản'));
      await tester.tap(find.text('Lưu tài khoản'));
      await tester.pumpAndSettle();
      expect(created, isTrue);
      expect(
        find.text('******6789'),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data)
            .join(' | '),
      );
      expect(find.text('123456789'), findsNothing);
      expect(find.text('Chưa xác minh chính chủ'), findsOneWidget);
    },
  );

  testWidgets(
    'F07: verification pending does not report success; check reads authoritative status',
    (tester) async {
      const qrPayload =
          '00020101021238540010A0000007270124000697042201100987654321'
          '0208QRIBFTTA5204601153037045405650005802VN62140810DH123456786304ABCD';
      var verified = false;
      var received = false;
      var starts = 0;
      api.testClient = MockClient((request) async {
        if (request.method == 'POST') {
          starts++;
          expect(request.url.path, endsWith('/7/initiate-verification'));
          return response({
            'data': {
              'accountId': '7',
              'amount': 2000,
              'checkoutUrl': 'https://pay.payos.vn/web/test',
              'qrCode': qrPayload,
              'sessionStatus': 'ACTIVE',
            },
          });
        }
        expect(request.url.path, endsWith('/7/verification-status'));
        return response({
          'data': {
            'accountVerificationStatus': verified ? 'VERIFIED' : 'PENDING',
            'session': {
              'paymentStatus': received ? 'PAID' : 'PENDING',
              'refundStatus': verified ? 'REFUNDED' : 'PENDING_REFUND',
              'refundSummary': {
                'totalRefundedAmount': verified ? 2000 : 0,
                'totalPendingRefundAmount': verified ? 0 : 2000,
              },
            },
          },
        });
      });
      await tester.pumpWidget(
        const MaterialApp(
          home: CustomerBankVerificationScreen(
            account: account,
            initiate: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(starts, 1);
      expect(find.text('Đã xác minh chính chủ'), findsNothing);
      expect(find.text('Mở thanh toán xác minh 2.000đ'), findsOneWidget);
      expect(find.byKey(const Key('bank-verification-qr')), findsOneWidget);
      final validation = QrValidator.validate(
        data: qrPayload,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );
      expect(validation.isValid, isTrue);
      await tester.scrollUntilVisible(
        find.byKey(const Key('bank-verification-status')),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Đang chờ xác minh'), findsOneWidget);
      received = true;
      await tester.ensureVisible(find.text('Kiểm tra trạng thái'));
      await tester.tap(find.text('Kiểm tra trạng thái'));
      await tester.pumpAndSettle();
      expect(
        find.text('Đã nhận tiền — đang đối chiếu tài khoản'),
        findsOneWidget,
      );
      expect(find.text('Đã xác minh chính chủ'), findsNothing);
      expect(find.text('Mở thanh toán xác minh 2.000đ'), findsNothing);
      expect(find.byKey(const Key('bank-verification-qr')), findsNothing);
      verified = true;
      await tester.ensureVisible(find.text('Kiểm tra trạng thái'));
      await tester.tap(find.text('Kiểm tra trạng thái'));
      await tester.pumpAndSettle();
      expect(find.text('Đã xác minh chính chủ'), findsOneWidget);
      expect(find.text('Đã hoàn khoản xác minh'), findsOneWidget);
      expect(find.text('Đã hoàn cọc'), findsNothing);
      expect(find.text('Mở thanh toán xác minh 2.000đ'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('F07: non-payable sessions never expose QR or checkout actions', (
    tester,
  ) async {
    final scenarios = [
      {'amount': 1999, 'sessionStatus': 'ACTIVE', 'rejectionReason': null},
      {'amount': 2000, 'sessionStatus': 'CANCELLED', 'rejectionReason': null},
      {
        'amount': 2000,
        'sessionStatus': 'ACTIVE',
        'rejectionReason': 'Không khớp chủ tài khoản',
      },
    ];

    for (final scenario in scenarios) {
      api.testClient = MockClient(
        (request) async => request.method == 'POST'
            ? response({
                'data': {
                  'amount': scenario['amount'],
                  'checkoutUrl': 'https://pay.payos.vn/web/test',
                  'qrCode': '00020101021238540010A000000727',
                  'sessionStatus': scenario['sessionStatus'],
                },
              })
            : response({
                'data': {
                  'accountVerificationStatus': 'PENDING',
                  'session': {
                    'paymentStatus': 'PENDING',
                    'refundStatus': 'NONE',
                    'rejectionReason': scenario['rejectionReason'],
                  },
                },
              }),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: CustomerBankVerificationScreen(
            account: account,
            initiate: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bank-verification-qr')), findsNothing);
      expect(find.text('Mở thanh toán xác minh 2.000đ'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    }
  });

  testWidgets(
    'F07: disabled provider shows error without fabricated payment link',
    (tester) async {
      api.testClient = MockClient(
        (_) async => response({'message': 'Tính năng xác minh đang tắt'}, 503),
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: CustomerBankVerificationScreen(
            account: account,
            initiate: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tính năng xác minh đang tắt'), findsOneWidget);
      expect(find.text('Mở thanh toán xác minh 2.000đ'), findsNothing);
      expect(find.text('Đã xác minh chính chủ'), findsNothing);
    },
  );

  testWidgets('F07: expired session cannot open an old payment link', (
    tester,
  ) async {
    api.testClient = MockClient(
      (request) async => request.method == 'POST'
          ? response({
              'data': {
                'amount': 2000,
                'checkoutUrl': 'https://pay.payos.vn/web/test',
                'qrCode': '00020101021238540010A000000727',
                'sessionStatus': 'ACTIVE',
              },
            })
          : response({
              'data': {
                'accountVerificationStatus': 'PENDING',
                'session': {'isExpired': true, 'paymentStatus': 'EXPIRED'},
              },
            }),
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: CustomerBankVerificationScreen(account: account, initiate: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Phiên xác minh đã hết hạn'), findsOneWidget);
    expect(find.text('Mở thanh toán xác minh 2.000đ'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
