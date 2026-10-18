import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_order_button/providers/device_provider.dart';
import 'package:smart_order_button/providers/order_provider.dart';
import 'package:smart_order_button/providers/user_provider.dart';
import 'package:smart_order_button/screens/home_screen.dart';
import 'package:smart_order_button/screens/profile_screen.dart';
import 'package:smart_order_button/services/auth_api_service.dart';
import 'package:smart_order_button/services/user_profile_service.dart';

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
  }) async {
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

    test('UserProvider.loadProfile() fetches real user data and updates all fields', () async {
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
    });

    test('UserProvider.loadProfile() gracefully extracts address from customerProfile sub-object', () async {
      mockAuthService.mockMeResponse = {
        'success': true,
        'data': {
          'id': 'usr-101',
          'fullName': 'Nguyễn Thị Mai',
          'phone': '0987654321',
          'email': 'mai.nguyen@smartorder.local',
          'customerProfile': {
            'defaultAddress': 'P.1809 - Tòa Landmark 81, Vinhomes Central Park',
          },
        },
      };

      await userProvider.loadProfile();

      expect(userProvider.name, 'Nguyễn Thị Mai');
      expect(userProvider.shortName, 'Mai');
      expect(userProvider.address, 'P.1809 - Tòa Landmark 81, Vinhomes Central Park');
      expect(userProvider.initials, 'NM');
    });

    test('UserProvider.loadProfile() captures error message when network fails', () async {
      mockAuthService.shouldThrow = true;

      await userProvider.loadProfile();

      expect(userProvider.isLoading, isFalse);
      expect(userProvider.errorMessage, isNotNull);
      expect(userProvider.errorMessage, contains('Network connection timed out'));
    });

    test('UserProvider shortName formatting handles single and multi-word names', () {
      userProvider.updateName('Mai');
      expect(userProvider.shortName, 'Mai');

      userProvider.updateName('Lê Hoàng Long');
      expect(userProvider.shortName, 'Long');

      userProvider.updateName('Alexander');
      expect(userProvider.shortName, 'Alexander');
    });

    test('UserProvider individual setters trigger backend sync and notify listeners', () {
      bool notified = false;
      userProvider.addListener(() {
        notified = true;
      });

      userProvider.updateName('Đặng Văn Hùng');
      expect(notified, isTrue);
      expect(userProvider.name, 'Đặng Văn Hùng');
      expect(userProvider.shortName, 'Hùng');
      expect(mockAuthService.lastUpdatedProfile?['fullName'], 'Đặng Văn Hùng');

      userProvider.updatePhone('0909090909');
      expect(userProvider.phone, '0909090909');
      expect(mockAuthService.lastUpdatedProfile?['phone'], '0909090909');

      userProvider.updateEmail('hung.dang@smartorder.local');
      expect(userProvider.email, 'hung.dang@smartorder.local');
      expect(mockAuthService.lastUpdatedProfile?['email'], 'hung.dang@smartorder.local');

      userProvider.updateAddress('Tòa Masteri Centre Point, Quận 9');
      expect(userProvider.address, 'Tòa Masteri Centre Point, Quận 9');
      expect(mockAuthService.lastUpdatedProfile?['address'], 'Tòa Masteri Centre Point, Quận 9');
    });

    test('UserProvider.updateProfile() updates multiple fields concurrently', () async {
      await userProvider.updateProfile(
        fullName: 'Phạm Thị Thúy',
        phone: '0933112233',
        email: 'thuy.pham@smartorder.local',
        address: 'P.304 - Tòa S3.02',
      );

      expect(userProvider.name, 'Phạm Thị Thúy');
      expect(userProvider.shortName, 'Thúy');
      expect(userProvider.phone, '0933112233');
      expect(userProvider.email, 'thuy.pham@smartorder.local');
      expect(userProvider.address, 'P.304 - Tòa S3.02');
    });

    test('UserProvider.reset() clears all profile information and error state', () async {
      await userProvider.loadProfile();
      expect(userProvider.name, isNotEmpty);

      userProvider.reset();

      expect(userProvider.name, isEmpty);
      expect(userProvider.phone, isEmpty);
      expect(userProvider.email, isEmpty);
      expect(userProvider.address, isEmpty);
      expect(userProvider.errorMessage, isNull);
    });
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

    testWidgets('HomeScreen loads profile on startup and reactively updates greeting and address', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ChangeNotifierProvider<DeviceProvider>.value(value: deviceProvider),
            ChangeNotifierProvider<OrderProvider>.value(value: orderProvider),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // After loadProfile finishes, greeting displays real shortName 'Tuấn'
      expect(find.text('Tuấn'), findsWidgets);
      expect(find.text('P.502 - Tòa S1.01, Vinhomes Grand Park'), findsWidgets);

      // Now reactively update the name via UserProvider
      userProvider.updateName('Nguyễn Thị Mai');
      await tester.pumpAndSettle();

      // Greeting reactively shifts to 'Mai'
      expect(find.text('Mai'), findsWidgets);
      expect(find.text('Tuấn'), findsNothing);

      // Reactively update the address
      userProvider.updateAddress('Tòa S5.03 - Căn 1205');
      await tester.pumpAndSettle();

      expect(find.text('Tòa S5.03 - Căn 1205'), findsWidgets);
    });
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

    testWidgets('ProfileScreen displays profile and allows editing phone number via modal', (WidgetTester tester) async {
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
      expect(find.text('tuan.tran@smartorder.local'), findsOneWidget);

      // Tap on the phone tile to open edit phone modal
      await tester.tap(find.text('Số điện thoại'));
      await tester.pumpAndSettle();

      expect(find.text('Đổi số điện thoại'), findsOneWidget);

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
    });

    testWidgets('ProfileScreen allows editing email via modal', (WidgetTester tester) async {
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
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ],
          child: const MaterialApp(
            home: ProfileScreen(showBackButton: false),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the email tile to open edit email modal
      await tester.tap(find.text('Email'));
      await tester.pumpAndSettle();

      expect(find.text('Đổi địa chỉ email'), findsOneWidget);

      // Enter a new email
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, 'tuan.new@smartorder.vn');
      await tester.pumpAndSettle();

      // Tap 'Lưu thay đổi'
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();

      expect(find.text('tuan.new@smartorder.vn'), findsOneWidget);
      expect(userProvider.email, 'tuan.new@smartorder.vn');
      expect(mockAuthService.lastUpdatedProfile?['email'], 'tuan.new@smartorder.vn');
    });
  });
}
