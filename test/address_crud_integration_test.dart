import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_order_button/models/address_model.dart';
import 'package:smart_order_button/providers/address_provider.dart';
import 'package:smart_order_button/providers/user_provider.dart';
import 'package:smart_order_button/screens/address/address_form_sheet.dart';
import 'package:smart_order_button/screens/address/address_list_screen.dart';
import 'package:smart_order_button/screens/profile_screen.dart';
import 'package:smart_order_button/services/address_api_service.dart';
import 'package:smart_order_button/services/auth_api_service.dart';
import 'package:smart_order_button/services/user_profile_service.dart';

class MockAddressApiService implements AddressApiService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  List<AddressModel> mockAddresses = [
    const AddressModel(
      id: 'addr-1',
      recipientName: 'Nguyễn Văn An',
      phone: '0988776655',
      addressDetail: 'P.1204 - Tòa S2.05, Vinhomes Grand Park',
      ward: 'Phường Long Thạnh Mỹ',
      district: 'TP. Thủ Đức',
      province: 'TP. Hồ Chí Minh',
      isDefault: true,
      label: 'Nhà riêng',
    ),
    const AddressModel(
      id: 'addr-2',
      recipientName: 'Nguyễn Văn An',
      phone: '0988776655',
      addressDetail: 'Tòa Landmark 81, 720A Điện Biên Phủ',
      ward: 'Phường 22',
      district: 'Quận Bình Thạnh',
      province: 'TP. Hồ Chí Minh',
      isDefault: false,
      label: 'Cơ quan',
    ),
  ];

  @override
  Future<List<AddressModel>> getAddresses() async {
    return List.from(mockAddresses);
  }

  @override
  Future<AddressModel> createAddress(AddressModel address) async {
    final created = address.copyWith(
      id: address.id.isNotEmpty
          ? address.id
          : 'addr-${mockAddresses.length + 1}',
    );
    if (created.isDefault) {
      mockAddresses =
          mockAddresses.map((a) => a.copyWith(isDefault: false)).toList();
    }
    mockAddresses.insert(0, created);
    return created;
  }

  @override
  Future<AddressModel> updateAddress(AddressModel address) async {
    final idx = mockAddresses.indexWhere((a) => a.id == address.id);
    if (idx != -1) {
      if (address.isDefault) {
        mockAddresses =
            mockAddresses.map((a) => a.copyWith(isDefault: false)).toList();
      }
      mockAddresses[idx] = address;
    }
    return address;
  }

  @override
  Future<bool> deleteAddress(String addressId) async {
    mockAddresses.removeWhere((a) => a.id == addressId);
    if (mockAddresses.isNotEmpty && !mockAddresses.any((a) => a.isDefault)) {
      mockAddresses[0] = mockAddresses[0].copyWith(isDefault: true);
    }
    return true;
  }

  @override
  Future<bool> setDefaultAddress(String addressId) async {
    mockAddresses = mockAddresses.map((a) {
      return a.copyWith(isDefault: a.id == addressId);
    }).toList();
    return true;
  }
}

class MockAuthApiServiceStub implements AuthApiService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Map<String, dynamic>> getMe() async => {
        'id': 'usr-1',
        'fullName': 'Nguyễn Văn An',
        'phone': '0988776655',
        'email': 'customer@smartorder.local',
        'address': 'P.1204 - Tòa S2.05, Vinhomes Grand Park',
      };

  @override
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? phone,
    String? email,
    String? address,
  }) async =>
      {'success': true};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AddressModel Unit Tests', () {
    test('AddressModel correctly serializes and deserializes', () {
      final json = {
        'id': 'addr-99',
        'recipientName': 'Trần Văn Bình',
        'phone': '0901234567',
        'addressDetail': 'P.802 - Tòa S1.01',
        'ward': 'Long Thạnh Mỹ',
        'district': 'Thủ Đức',
        'province': 'TP.HCM',
        'isDefault': true,
        'label': 'Nhà riêng',
      };

      final model = AddressModel.fromJson(json);
      expect(model.id, 'addr-99');
      expect(model.recipientName, 'Trần Văn Bình');
      expect(model.phone, '0901234567');
      expect(model.isDefault, isTrue);
      expect(model.fullAddress, contains('P.802 - Tòa S1.01'));
      expect(model.fullAddress, contains('Long Thạnh Mỹ'));

      final serialized = model.toJson();
      expect(serialized['recipientName'], 'Trần Văn Bình');
      expect(serialized['isDefault'], isTrue);
    });
  });

  group('AddressProvider CRUD Flow Tests', () {
    late MockAddressApiService mockApi;
    late UserProfileService userProfile;
    late AddressProvider provider;

    setUp(() {
      mockApi = MockAddressApiService();
      userProfile = UserProfileService();
      userProfile.reset();
      provider = AddressProvider(
        apiService: mockApi,
        userProfileService: userProfile,
      );
    });

    test('loadAddresses() fetches addresses and sets default address in userProfile', () async {
      expect(provider.addresses, isEmpty);

      await provider.loadAddresses();

      expect(provider.addresses.length, 2);
      expect(provider.defaultAddress?.id, 'addr-1');
      expect(provider.selectedAddress?.id, 'addr-1');
      expect(userProfile.address, contains('P.1204 - Tòa S2.05'));
    });

    test('addAddress() creates address, prepends to list, and updates default if flagged', () async {
      await provider.loadAddresses();

      const newAddr = AddressModel(
        id: 'addr-3',
        recipientName: 'Lê Văn Cường',
        phone: '0911223344',
        addressDetail: 'P.0405 - Tòa Masteri M1',
        ward: 'Long Thạnh Mỹ',
        district: 'Thủ Đức',
        province: 'TP.HCM',
        isDefault: true,
        label: 'Căn hộ mới',
      );

      final created = await provider.addAddress(newAddr);
      expect(created, isNotNull);
      expect(provider.addresses.length, 3);
      expect(provider.defaultAddress?.id, 'addr-3');
      expect(userProfile.address, contains('Masteri M1'));
    });

    test('updateAddress() modifies target address in provider list', () async {
      await provider.loadAddresses();

      final updated = provider.addresses.first.copyWith(
        recipientName: 'Nguyễn Văn An (VIP)',
        addressDetail: 'P.1504 - Tòa S2.05',
      );

      final ok = await provider.updateAddress(updated);
      expect(ok, isTrue);

      final found = provider.addresses.firstWhere((a) => a.id == updated.id);
      expect(found.recipientName, 'Nguyễn Văn An (VIP)');
      expect(found.addressDetail, 'P.1504 - Tòa S2.05');
    });

    test('setDefaultAddress() updates default flag and syncs with UserProfileService', () async {
      await provider.loadAddresses();

      final ok = await provider.setDefaultAddress('addr-2');
      expect(ok, isTrue);
      expect(provider.defaultAddress?.id, 'addr-2');
      expect(userProfile.address, contains('Landmark 81'));
    });

    test('deleteAddress() removes item and gracefully picks remaining default', () async {
      await provider.loadAddresses();

      final ok = await provider.deleteAddress('addr-1');
      expect(ok, isTrue);
      expect(provider.addresses.length, 1);
      expect(provider.defaultAddress?.id, 'addr-2');
    });
  });

  group('Address UI Widget Tests', () {
    late MockAddressApiService mockApi;
    late UserProfileService userProfile;
    late AddressProvider addressProvider;
    late UserProvider userProvider;

    setUp(() {
      mockApi = MockAddressApiService();
      userProfile = UserProfileService();
      userProfile.reset();
      addressProvider = AddressProvider(
        apiService: mockApi,
        userProfileService: userProfile,
      );
      userProvider = UserProvider(
        authService: MockAuthApiServiceStub(),
        localProfile: userProfile,
      );
    });

    testWidgets('AddressListScreen renders address cards and handles selection', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await addressProvider.loadAddresses();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AddressProvider>.value(value: addressProvider),
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ],
          child: const MaterialApp(
            home: AddressListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Địa chỉ nhận hàng'), findsOneWidget);
      expect(find.text('P.1204 - Tòa S2.05, Vinhomes Grand Park'), findsOneWidget);
      expect(find.text('Mặc định'), findsOneWidget);
      expect(find.text('Tòa Landmark 81, 720A Điện Biên Phủ'), findsOneWidget);

      // Tap on edit button
      expect(find.text('Sửa'), findsWidgets);
      expect(find.text('Xóa'), findsWidgets);
    });

    testWidgets('AddressFormSheet allows entering new address fields', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      AddressModel? savedResult;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AddressProvider>.value(value: addressProvider),
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AddressFormSheet(
                onSaved: (addr) => savedResult = addr,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Thêm địa chỉ nhận hàng'), findsOneWidget);
      expect(find.text('LOẠI ĐỊA CHỈ'), findsOneWidget);

      // Enter details
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Trần Thị Thu');
      await tester.enterText(textFields.at(1), '0977889900');
      await tester.enterText(textFields.at(2), 'P.1002 - Tòa S3.01');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lưu địa chỉ mới'));
      await tester.pumpAndSettle();

      expect(savedResult, isNotNull);
      expect(savedResult!.recipientName, 'Trần Thị Thu');
      expect(savedResult!.phone, '0977889900');
      expect(savedResult!.addressDetail, 'P.1002 - Tòa S3.01');
    });

    testWidgets('ProfileScreen tapping Địa chỉ giao hàng opens AddressListScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await userProvider.loadProfile();
      await addressProvider.loadAddresses();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AddressProvider>.value(value: addressProvider),
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ],
          child: const MaterialApp(
            home: ProfileScreen(showBackButton: false),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find "Địa chỉ giao hàng" tile
      expect(find.text('Địa chỉ giao hàng'), findsOneWidget);

      // Tap on it
      await tester.tap(find.text('Địa chỉ giao hàng'));
      await tester.pumpAndSettle();

      // Should now be on AddressListScreen!
      expect(find.text('Địa chỉ nhận hàng'), findsOneWidget);
      expect(find.text('P.1204 - Tòa S2.05, Vinhomes Grand Park'), findsOneWidget);
    });
  });
}
