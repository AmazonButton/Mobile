import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_order_button/models/address_model.dart';
import 'package:smart_order_button/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_order_button/providers/device_provider.dart';
import 'package:smart_order_button/providers/address_provider.dart';
import 'package:smart_order_button/providers/order_provider.dart';
import 'package:smart_order_button/providers/user_provider.dart';
import 'package:smart_order_button/screens/home_screen.dart';
import 'package:smart_order_button/screens/profile_screen.dart';
import 'package:smart_order_button/services/auth_api_service.dart';
import 'package:smart_order_button/services/user_profile_service.dart';

class _ProfileAddresses extends AddressProvider {
  @override
  Future<void> loadAddresses({bool force = false}) async {}
  @override
  String get currentAddressDisplay => UserProfileService().address;
  @override
  AddressModel get selectedAddress => AddressModel(
    id: 'address',
    recipientName: 'Test',
    phone: '0912345678',
    addressDetail: currentAddressDisplay,
    latitude: 10.8,
    longitude: 106.7,
  );
}

class MockAuthApiService implements AuthApiService {
  Map<String, dynamic> mockMeResponse = {
    'success': true,
    'data': {
      'id': 'usr-100',
      'fullName': 'Trần Anh Tuấn',
      'phone': '0912345678',
      'email': 'tuan.tran@smartorder.local',
      'address': 'P.502 - Tòa S1.01, Vinhomes Grand Park',
    },
  };
  bool shouldThrow = false;
  Map<String, dynamic>? lastUpdatedProfile;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Map<String, dynamic>> getMe() async {
    if (shouldThrow) {
      throw Exception('Network connection timed out');
    }
    return mockMeResponse['data'] ?? mockMeResponse;
  }

  @override
  Future<Map<String, dynamic>> getProfile() => getMe();

  @override
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? phone,
    String? email,
    String? address,
    String? avatarUrl,
  }) async {
    if (shouldThrow) throw Exception('Profile save failed');
    final updated = <String, dynamic>{};
    if (fullName != null) updated['fullName'] = fullName;
    if (phone != null) updated['phone'] = phone;
    if (email != null) updated['email'] = email;
    if (address != null) updated['address'] = address;
    lastUpdatedProfile = updated;
    return {'success': true, 'data': lastUpdatedProfile};
  }

  @override
  Future<void> logout() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient().testClient = MockClient(
      (_) async => http.Response(jsonEncode({'data': []}), 200),
    );
  });
  tearDown(() => ApiClient().testClient = http.Client());

  group('Story 3.4 - UserProvider & Profile API Integration Tests', () {
    late MockAuthApiService mockAuthService;
    late UserProfileService localProfile;
    late UserProvider userProvider;

    setUp(() {
      mockAuthService = MockAuthApiService();
      localProfile = UserProfileService();
      localProfile.reset();
      userProvider = UserProvider(
        authService: mockAuthService,
        localProfile: localProfile,
      );
    });

    test(
      'UserProvider.loadProfile() fetches real user data and updates all fields',
      () async {
        expect(userProvider.name, isEmpty);

        await userProvider.loadProfile();

        expect(userProvider.name, 'Trần Anh Tuấn');
        expect(userProvider.shortName, 'Tuấn');
        expect(userProvider.phone, '0912345678');
        expect(userProvider.email, 'tuan.tran@smartorder.local');
        expect(userProvider.address, 'P.502 - Tòa S1.01, Vinhomes Grand Park');
        expect(userProvider.initials, 'TT');
        expect(userProvider.isLoading, isFalse);
        expect(userProvider.errorMessage, isNull);
      },
    );

    test(
      'UserProvider.loadProfile() gracefully extracts address from customerProfile sub-object',
      () async {
        mockAuthService.mockMeResponse = {
          'success': true,
          'data': {
            'id': 'usr-101',
            'fullName': 'Nguyễn Thị Mai',
            'phone': '0987654321',
            'email': 'mai.nguyen@smartorder.local',
            'customerProfile': {
              'defaultAddress':
                  'P.1809 - Tòa Landmark 81, Vinhomes Central Park',
            },
          },
        };

        await userProvider.loadProfile();

        expect(userProvider.name, 'Nguyễn Thị Mai');
        expect(userProvider.shortName, 'Mai');
        expect(
          userProvider.address,
          'P.1809 - Tòa Landmark 81, Vinhomes Central Park',
        );
        expect(userProvider.initials, 'NM');
      },
    );

    test(
      'UserProvider.loadProfile() captures error message when network fails',
      () async {
        mockAuthService.shouldThrow = true;

        await userProvider.loadProfile();

        expect(userProvider.isLoading, isFalse);
        expect(userProvider.errorMessage, isNotNull);
        expect(
          userProvider.errorMessage,
          contains('Network connection timed out'),
        );
      },
    );

    test(
      'UserProvider shortName formatting handles single and multi-word names',
      () async {
        await userProvider.updateName('Mai');
        expect(userProvider.shortName, 'Mai');

        await userProvider.updateName('Lê Hoàng Long');
        expect(userProvider.shortName, 'Long');

        await userProvider.updateName('Alexander');
        expect(userProvider.shortName, 'Alexander');
      },
    );

    test(
      'UserProvider individual setters trigger backend sync and notify listeners',
      () async {
        bool notified = false;
        userProvider.addListener(() {
          notified = true;
        });

        await userProvider.updateName('Đặng Văn Hùng');
        expect(notified, isTrue);
        expect(userProvider.name, 'Đặng Văn Hùng');
        expect(userProvider.shortName, 'Hùng');
        expect(
          mockAuthService.lastUpdatedProfile?['fullName'],
          'Đặng Văn Hùng',
        );

        await userProvider.updatePhone('0909090909');
        expect(userProvider.phone, '0909090909');
        expect(mockAuthService.lastUpdatedProfile?['phone'], '0909090909');

        await expectLater(
          userProvider.updateEmail('hung.dang@smartorder.local'),
          throwsStateError,
        );
        expect(userProvider.email, isNot('hung.dang@smartorder.local'));

        await expectLater(
          userProvider.updateAddress('Tòa Masteri Centre Point, Quận 9'),
          throwsStateError,
        );
      },
    );

    test(
      'UserProvider.updateProfile() updates multiple fields concurrently',
      () async {
        await userProvider.updateProfile(
          fullName: 'Phạm Thị Thúy',
          phone: '0933112233',
        );

        expect(userProvider.name, 'Phạm Thị Thúy');
        expect(userProvider.shortName, 'Thúy');
        expect(userProvider.phone, '0933112233');
        expect(
          mockAuthService.lastUpdatedProfile?.keys,
          containsAll(['fullName', 'phone']),
        );
      },
    );

    test(
      'UserProvider.reset() clears all profile information and error state',
      () async {
        await userProvider.loadProfile();
        expect(userProvider.name, isNotEmpty);

        userProvider.reset();

        expect(userProvider.name, isEmpty);
        expect(userProvider.phone, isEmpty);
        expect(userProvider.email, isEmpty);
        expect(userProvider.address, isEmpty);
        expect(userProvider.errorMessage, isNull);
      },
    );
  });

  group('Story 3.4 - HomeScreen Reactive Greeting & Address UI Tests', () {
    late MockAuthApiService mockAuthService;
    late UserProfileService localProfile;
    late UserProvider userProvider;
    late DeviceProvider deviceProvider;
    late OrderProvider orderProvider;

    setUp(() {
      mockAuthService = MockAuthApiService();
      localProfile = UserProfileService();
      localProfile.reset();
      userProvider = UserProvider(
        authService: mockAuthService,
        localProfile: localProfile,
      );
      deviceProvider = DeviceProvider();
      orderProvider = OrderProvider();
    });

    testWidgets(
      'HomeScreen loads profile on startup and reactively updates greeting and address',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AddressProvider>(
                create: (_) => _ProfileAddresses(),
              ),
              ChangeNotifierProvider<UserProvider>.value(value: userProvider),
              ChangeNotifierProvider<DeviceProvider>.value(
                value: deviceProvider,
              ),
              ChangeNotifierProvider<OrderProvider>.value(value: orderProvider),
            ],
            child: const MaterialApp(home: HomeScreen()),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // After loadProfile finishes, greeting displays real shortName 'Tuấn'
        expect(find.text('Chào Tuấn 👋'), findsWidgets);
        expect(
          find.text('P.502 - Tòa S1.01, Vinhomes Grand Park'),
          findsWidgets,
        );

        // Now reactively update the name via UserProvider
        await userProvider.updateName('Nguyễn Thị Mai');
        await tester.pumpAndSettle();

        // Greeting reactively shifts to 'Mai'
        expect(find.text('Chào Mai 👋'), findsWidgets);
        expect(find.text('Tuấn'), findsNothing);

        // Reactively update the address
        localProfile.updateAddress('Tòa S5.03 - Căn 1205');
        await tester.pumpAndSettle();

        expect(find.text('Tòa S5.03 - Căn 1205'), findsWidgets);
      },
    );
  });

  group('Story 3.4 - ProfileScreen Reactive Fields & Editing UI Tests', () {
    late MockAuthApiService mockAuthService;
    late UserProfileService localProfile;
    late UserProvider userProvider;

    setUp(() {
      mockAuthService = MockAuthApiService();
      localProfile = UserProfileService();
      localProfile.reset();
      userProvider = UserProvider(
        authService: mockAuthService,
        localProfile: localProfile,
      );
    });

    testWidgets(
      'ProfileScreen displays profile and allows editing phone number via modal',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await userProvider.loadProfile();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AddressProvider>(
                create: (_) => _ProfileAddresses(),
              ),
              ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ],
            child: const MaterialApp(
              home: ProfileScreen(showBackButton: false),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check displayed profile fields
        expect(find.text('Trần Anh Tuấn'), findsWidgets);
        expect(find.text('0912345678'), findsOneWidget);
        await tester.tap(find.text('Chỉnh sửa hồ sơ'));
        await tester.pumpAndSettle();
        expect(find.text('tuan.tran@smartorder.local'), findsOneWidget);

        // Tap on the phone tile to open edit phone modal
        await tester.tap(find.text('Số điện thoại'));
        await tester.pumpAndSettle();

        expect(find.text('Chỉnh sửa số điện thoại'), findsOneWidget);

        // Enter a new phone number
        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);
        await tester.enterText(textField, '0999888777');
        await tester.pumpAndSettle();

        // Tap 'Lưu thay đổi'
        await tester.tap(find.text('Lưu thay đổi'));
        await tester.pumpAndSettle();

        // Modal closed, new phone number visible in UI and UserProvider
        expect(find.text('0999888777'), findsOneWidget);
        expect(userProvider.phone, '0999888777');
        expect(mockAuthService.lastUpdatedProfile?['phone'], '0999888777');
      },
    );

    testWidgets(
      'ProfileScreen keeps failed edits open without changing saved data',
      (tester) async {
        await userProvider.loadProfile();
        await tester.pumpWidget(
          ChangeNotifierProvider<UserProvider>.value(
            value: userProvider,
            child: const MaterialApp(
              home: ProfileScreen(showBackButton: false),
            ),
          ),
        );
        await tester.pumpAndSettle();
        mockAuthService.shouldThrow = true;
        await tester.tap(find.text('Chỉnh sửa hồ sơ'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Số điện thoại'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '0999888777');
        await tester.tap(find.text('Lưu thay đổi'));
        await tester.pumpAndSettle();
        expect(
          find.text('Không thể lưu hồ sơ. Vui lòng thử lại.'),
          findsOneWidget,
        );
        expect(find.text('Lưu thay đổi'), findsOneWidget);
        expect(userProvider.phone, '0912345678');
        expect(find.text('Cập nhật hồ sơ thành công'), findsNothing);
      },
    );

    testWidgets('ProfileScreen displays email as read-only', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await userProvider.loadProfile();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AddressProvider>(
              create: (_) => _ProfileAddresses(),
            ),
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ],
          child: const MaterialApp(home: ProfileScreen(showBackButton: false)),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Chỉnh sửa hồ sơ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Email'));
      await tester.pumpAndSettle();
      expect(find.text('Đổi địa chỉ email'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(userProvider.email, 'tuan.tran@smartorder.local');
      expect(mockAuthService.lastUpdatedProfile, isNull);
    });
  });
}
