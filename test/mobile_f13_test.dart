import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_order_button/services/api_client.dart';
import 'package:smart_order_button/services/auth_api_service.dart';
import 'package:smart_order_button/services/google_login_service.dart';
import 'package:smart_order_button/services/identity_verification_service.dart';
import 'package:smart_order_button/models/identity_verification.dart';
import 'package:smart_order_button/screens/change_password_screen.dart';
import 'package:smart_order_button/screens/identity_verification_screen.dart';
import 'package:smart_order_button/screens/login_screen.dart';
import 'package:smart_order_button/screens/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ApiClient api;
  http.Response reply(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
  Map<String, dynamic> session(
    String id,
    String status, {
    String url = 'https://verify.didit.me/session/example',
    String? expires,
  }) => {
    'sessionId': id,
    'status': status,
    'verificationUrl': url,
    'createdAt': '2026-11-01T00:00:00Z',
    'expiresAt': ?expires,
  };
  Map<String, dynamic> list(
    List<Map<String, dynamic>> items, {
    int page = 1,
    bool more = false,
  }) => {
    'data': items,
    'pagination': {'page': page, 'pageSize': 20, 'hasNextPage': more},
  };
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    api = ApiClient();
    await api.setTokens(
      accessToken: 'old-session',
      refreshToken: 'old-refresh',
    );
  });
  tearDown(() async {
    api.testClient = http.Client();
    await api.clearTokens();
  });

  test(
    'Google exchanges SDK token only and replaces both backend tokens',
    () async {
      api.testClient = MockClient((req) async {
        expect(req.url.path.endsWith('/auth/google-login'), isTrue);
        expect(jsonDecode(req.body), {'token': 'google-id-token'});
        return reply({
          'success': true,
          'data': {
            'accessToken': 'new-session',
            'refreshToken': 'new-refresh',
            'user': {'fullName': 'Test'},
          },
        });
      });
      final service = GoogleLoginService(
        acquireIdToken: () async => 'google-id-token',
      );
      await service.signIn();
      expect(api.accessToken, 'new-session');
      expect(api.refreshToken, 'new-refresh');
      await api.init(force: true);
      expect(api.accessToken, 'new-session');
    },
  );

  test(
    'Google cancellation sends no backend request and keeps prior session',
    () async {
      api.testClient = MockClient((_) async => fail('Must not call backend'));
      expect(
        await GoogleLoginService(acquireIdToken: () async => null).signIn(),
        isNull,
      );
      expect(api.accessToken, 'old-session');
    },
  );

  test(
    'Google malformed response cannot report success or replace session',
    () async {
      api.testClient = MockClient(
        (_) async => reply({
          'success': true,
          'data': {
            'user': {'email': 'test@example.com'},
          },
        }),
      );
      await expectLater(
        GoogleLoginService(acquireIdToken: () async => 'token').signIn(),
        throwsA(isA<ApiException>()),
      );
      expect(api.accessToken, 'old-session');
    },
  );

  test(
    'Google double invocation opens a single authentication attempt',
    () async {
      final token = Completer<String?>();
      var calls = 0;
      final service = GoogleLoginService(
        acquireIdToken: () {
          calls++;
          return token.future;
        },
      );
      final pending = service.signIn();
      expect(await service.signIn(), isNull);
      expect(calls, 1);
      token.complete(null);
      await pending;
    },
  );

  testWidgets('Google backend rejection stays at login and shows real error', (
    tester,
  ) async {
    api.testClient = MockClient(
      (_) async => reply({'message': 'Tài khoản bị vô hiệu hóa'}, 403),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          googleService: GoogleLoginService(
            acquireIdToken: () async => 'token',
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('googleLogin')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Tài khoản bị vô hiệu hóa'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  test(
    'Password change clears persisted session after server success',
    () async {
      api.testClient = MockClient((req) async {
        expect(req.url.path.endsWith('/auth/change-password'), isTrue);
        expect(req.headers['authorization'], 'Bearer old-session');
        expect(jsonDecode(req.body), {
          'currentPassword': 'OldSecret1!',
          'newPassword': 'NewSecret2!',
        });
        return reply({'success': true});
      });
      await AuthApiService().changePassword(
        currentPassword: 'OldSecret1!',
        newPassword: 'NewSecret2!',
      );
      expect(api.isAuthenticated, isFalse);
      expect(api.refreshToken, isNull);
      await api.init(force: true);
      expect(api.isAuthenticated, isFalse);
    },
  );

  test(
    'Incorrect current password preserves session and never refreshes',
    () async {
      var calls = 0;
      api.testClient = MockClient((req) async {
        calls++;
        return reply({'message': 'Mật khẩu hiện tại không chính xác'}, 401);
      });
      await expectLater(
        AuthApiService().changePassword(
          currentPassword: 'wrong',
          newPassword: 'NewSecret2!',
        ),
        throwsA(isA<ApiException>()),
      );
      expect(calls, 1);
      expect(api.accessToken, 'old-session');
    },
  );

  testWidgets(
    'Password form blocks weak/mismatching passwords without sending',
    (tester) async {
      api.testClient = MockClient(
        (_) async => fail('Validation must block request'),
      );
      await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));
      await tester.enterText(
        find.byKey(const ValueKey('password0')),
        'OldSecret1!',
      );
      await tester.enterText(find.byKey(const ValueKey('password1')), 'weak');
      await tester.enterText(
        find.byKey(const ValueKey('password2')),
        'different',
      );
      await tester.ensureVisible(find.text('Lưu mật khẩu mới'));
      await tester.tap(find.text('Lưu mật khẩu mới'));
      await tester.pump();
      expect(find.textContaining('Cần ít nhất 8 ký tự'), findsOneWidget);
      expect(find.text('Mật khẩu nhập lại chưa khớp.'), findsOneWidget);
    },
  );

  testWidgets('Password save failure stays on form with retryable inputs', (
    tester,
  ) async {
    api.testClient = MockClient(
      (_) async => reply({'message': 'Mật khẩu hiện tại không chính xác'}, 401),
    );
    await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));
    for (final entry in {
      0: 'OldSecret1!',
      1: 'NewSecret2!',
      2: 'NewSecret2!',
    }.entries) {
      await tester.enterText(
        find.byKey(ValueKey('password${entry.key}')),
        entry.value,
      );
    }
    await tester.ensureVisible(find.text('Lưu mật khẩu mới'));
    await tester.tap(find.text('Lưu mật khẩu mới'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(ChangePasswordScreen), findsOneWidget);
    expect(find.text('Mật khẩu hiện tại không chính xác'), findsOneWidget);
    expect(api.isAuthenticated, isTrue);
  });

  testWidgets('Successful password change removes protected route', (
    tester,
  ) async {
    api.testClient = MockClient((_) async => reply({'success': true}));
    await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));
    for (final entry in {
      0: 'OldSecret1!',
      1: 'NewSecret2!',
      2: 'NewSecret2!',
    }.entries) {
      await tester.enterText(
        find.byKey(ValueKey('password${entry.key}')),
        entry.value,
      );
    }
    await tester.ensureVisible(find.text('Lưu mật khẩu mới'));
    await tester.tap(find.text('Lưu mật khẩu mới'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(ChangePasswordScreen), findsNothing);
    expect(api.isAuthenticated, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  test(
    'eKYC decision rereads saved session rather than stale decision status',
    () async {
      final paths = <String>[];
      api.testClient = MockClient((req) async {
        paths.add(req.url.path);
        return reply({
          'data': req.url.path.endsWith('/decision')
              ? {
                  'status': 'PENDING',
                  'decision': {
                    'status': 'Approved',
                    'document_number': 'ignored',
                  },
                }
              : session('7', 'APPROVED'),
        });
      });
      expect(
        (await IdentityVerificationService().checkDecision('7')).approved,
        isTrue,
      );
      expect(paths.map((p) => p.split('/').last), ['decision', '7']);
    },
  );

  test(
    'eKYC launch accepts only HTTPS Didit hosts and unexpired pending sessions',
    () {
      for (final url in [
        'http://verify.didit.me/s',
        'https://didit.me.evil.test/s',
        'https://evil.test/s',
        'https://user@verify.didit.me/s',
        'file:///tmp/s',
      ]) {
        expect(
          IdentityVerification.fromJson(
            session('1', 'PENDING', url: url),
          ).launchUri,
          isNull,
        );
      }
      expect(
        IdentityVerification.fromJson(session('1', 'PENDING')).launchUri,
        isNotNull,
      );
      expect(
        IdentityVerification.fromJson(
          session('1', 'PENDING', expires: '2020-01-01T00:00:00Z'),
        ).canContinue,
        isFalse,
      );
      expect(
        IdentityVerification.fromJson(session('1', 'IN_REVIEW')).canContinue,
        isFalse,
      );
    },
  );

  testWidgets(
    'eKYC restores pending session without creating; browser does not approve',
    (tester) async {
      var posts = 0, opens = 0;
      api.testClient = MockClient((req) async {
        if (req.method == 'POST') posts++;
        return reply(list([session('2', 'PENDING')]));
      });
      await tester.pumpWidget(
        MaterialApp(
          home: IdentityVerificationScreen(
            openUrl: (_) async {
              opens++;
              return true;
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(posts, 0);
      await tester.tap(find.text('Tiếp tục xác minh'));
      await tester.pump();
      await tester.pump();
      expect(opens, 1);
      expect(posts, 0);
      expect(find.text('Đã xác minh danh tính'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('eKYC waits for explicit consent before creating a session', (
    tester,
  ) async {
    var posts = 0;
    api.testClient = MockClient((req) async {
      if (req.method == 'POST') {
        posts++;
        return reply({'data': session('3', 'PENDING')});
      }
      return reply(list([]));
    });
    await tester.pumpWidget(
      MaterialApp(home: IdentityVerificationScreen(openUrl: (_) async => true)),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Bắt đầu xác minh'));
    await tester.pumpAndSettle();
    expect(posts, 0);
    await tester.tap(find.text('Để sau'));
    await tester.pumpAndSettle();
    expect(posts, 0);
    await tester.tap(find.text('Bắt đầu xác minh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục với Didit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(posts, 1);
    expect(find.text('Tiếp tục xác minh'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'eKYC history load failure offers retry without creating sessions',
    (tester) async {
      var failLoad = true;
      api.testClient = MockClient((req) async {
        expect(req.method, 'GET');
        return failLoad
            ? reply({'message': 'Không tải được lịch sử'}, 503)
            : reply(list([]));
      });
      await tester.pumpWidget(
        const MaterialApp(home: IdentityVerificationScreen()),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Bắt đầu xác minh'), findsNothing);
      expect(find.text('Thử lại'), findsOneWidget);
      failLoad = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Bắt đầu xác minh'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('eKYC reloads authoritative result when app resumes', (
    tester,
  ) async {
    var state = 'IN_REVIEW';
    api.testClient = MockClient(
      (req) async => reply(
        req.url.path.endsWith('/sessions')
            ? list([session('4', state)])
            : {'data': session('4', state)},
      ),
    );
    await tester.pumpWidget(
      const MaterialApp(home: IdentityVerificationScreen()),
    );
    await tester.pump();
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    state = 'APPROVED';
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(find.text('Đã xác minh danh tính'), findsOneWidget);
    expect(find.text('Tạo phiên xác minh mới'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('eKYC history loads next page and retains first page', (
    tester,
  ) async {
    api.testClient = MockClient((req) async {
      final page = int.parse(req.url.queryParameters['page']!);
      return reply(
        list(
          [session(page == 1 ? '5' : '2', 'DECLINED')],
          page: page,
          more: page == 1,
        ),
      );
    });
    await tester.pumpWidget(
      const MaterialApp(home: IdentityVerificationScreen()),
    );
    await tester.pump();
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Tải thêm lịch sử'), 180);
    await tester.tap(find.text('Tải thêm lịch sử'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Phiên #5'), findsOneWidget);
    expect(find.textContaining('Phiên #2'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Profile exposes F13 and removes excluded account/avatar/settings actions',
    (tester) async {
      api.testClient = MockClient((_) async => reply({'data': {}}));
      await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Cài đặt ứng dụng'), findsNothing);
      expect(find.text('Xóa tài khoản'), findsNothing);
      expect(find.text('Đổi mật khẩu'), findsOneWidget);
      expect(find.text('Xác minh danh tính'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
