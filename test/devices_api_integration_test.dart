import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_order_button/models/device_model.dart';
import 'package:smart_order_button/providers/device_provider.dart';
import 'package:smart_order_button/screens/devices_screen.dart';
import 'package:smart_order_button/screens/home_screen.dart';
import 'package:smart_order_button/services/devices_api_service.dart';

class MockDevicesApiService implements DevicesApiService {
  List<DeviceModel> mockDevices = [];
  bool shouldFail = false;
  int getDevicesCalls = 0;

  @override
  Future<List<DeviceModel>> getDevices({String? status, String? search}) async {
    getDevicesCalls++;
    if (shouldFail) {
      throw Exception('Không thể kết nối máy chủ');
    }
    return mockDevices;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Story 3.2 - DeviceProvider & Devices API Integration Tests', () {
    late MockDevicesApiService mockApi;

    setUp(() {
      mockApi = MockDevicesApiService();
    });

    test('DeviceProvider loads devices from API successfully', () async {
      mockApi.mockDevices = [
        const DeviceModel(
          id: 'dev-101',
          name: 'Nút Phòng Khách VIP',
          room: 'Phòng Khách',
          product: 'Nước Khoáng Lavie',
          price: '70.000đ',
          battery: 92,
          badgeText: '20L',
          signal: 'Rất tốt',
          status: DeviceStatus.online,
        ),
      ];

      final provider = DeviceProvider(apiService: mockApi, initialDevices: []);

      expect(provider.devices.isEmpty, isTrue);
      expect(provider.isLoading, isFalse);

      final future = provider.loadDevices();
      expect(provider.isLoading, isTrue);

      await future;
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.devices.length, equals(1));
      expect(provider.devices.first.id, equals('dev-101'));
      expect(provider.devices.first.name, equals('Nút Phòng Khách VIP'));
      expect(mockApi.getDevicesCalls, equals(1));
    });

    test('DeviceProvider handles empty device list from backend', () async {
      mockApi.mockDevices = [];

      final provider = DeviceProvider(
        apiService: mockApi,
        initialDevices: List.from(DeviceModel.sampleDevices),
      );

      expect(provider.devices.isNotEmpty, isTrue);

      await provider.loadDevices();

      expect(provider.devices.isEmpty, isTrue);
      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, isFalse);
    });

    test('DeviceProvider handles network error gracefully', () async {
      mockApi.shouldFail = true;

      final initial = [
        const DeviceModel(
          id: 'dev-cached',
          name: 'Nút Đã Lưu',
          room: 'Kho',
          battery: 80,
          status: DeviceStatus.online,
        ),
      ];

      final provider = DeviceProvider(
        apiService: mockApi,
        initialDevices: initial,
      );

      await provider.loadDevices();

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, contains('Không thể kết nối máy chủ'));
      // Giữ lại dữ liệu hiện có khi có lỗi kết nối
      expect(provider.devices.length, equals(1));
      expect(provider.devices.first.id, equals('dev-cached'));
    });

    test('DeviceProvider.refreshDevices calls loadDevices', () async {
      mockApi.mockDevices = [];
      final provider = DeviceProvider(apiService: mockApi);

      await provider.refreshDevices();
      expect(mockApi.getDevicesCalls, equals(1));
    });
  });

  group('Story 3.2 - DevicesScreen UI Integration Tests', () {
    testWidgets(
      'DevicesScreen displays empty state when no devices are registered',
      (tester) async {
        final mockApi = MockDevicesApiService();
        mockApi.mockDevices = [];

        final provider = DeviceProvider(
          apiService: mockApi,
          initialDevices: [],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<DeviceProvider>.value(
              value: provider,
              child: const DevicesScreen(),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Chào người bạn mới!'), findsOneWidget);
        expect(find.text('Kết nối thiết bị đầu tiên'), findsOneWidget);
        expect(find.text('0 nút bấm đang kết nối'), findsNothing);
      },
    );

    testWidgets('DevicesScreen displays real devices loaded from provider', (
      tester,
    ) async {
      final mockApi = MockDevicesApiService();
      final sample = [
        const DeviceModel(
          id: 'btn-real-1',
          name: 'Nút Bếp Căn Hộ 1204',
          room: 'Nhà bếp',
          product: 'Lavie 20L',
          price: '65.000đ',
          battery: 88,
          badgeText: '20L',
          signal: 'Rất tốt',
          status: DeviceStatus.online,
        ),
      ];
      mockApi.mockDevices = sample;

      final provider = DeviceProvider(
        apiService: mockApi,
        initialDevices: sample,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DeviceProvider>.value(
            value: provider,
            child: const DevicesScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Nút Bếp Căn Hộ 1204'), findsOneWidget);
      expect(find.text('1 người bạn của nhà'), findsOneWidget);
      expect(find.text('Chưa có nút bấm nào'), findsNothing);
    });

    testWidgets('DevicesScreen supports pull-to-refresh', (tester) async {
      final mockApi = MockDevicesApiService();
      mockApi.mockDevices = [];

      final provider = DeviceProvider(apiService: mockApi, initialDevices: []);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DeviceProvider>.value(
            value: provider,
            child: const DevicesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Trigger pull to refresh gesture
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(mockApi.getDevicesCalls, greaterThanOrEqualTo(1));
    });
  });

  group('Story 3.2 - HomeScreen UI Integration Tests', () {
    testWidgets(
      'HomeScreen displays empty state in smart buttons section when devices is empty',
      (tester) async {
        final mockApi = MockDevicesApiService();
        mockApi.mockDevices = [];

        final provider = DeviceProvider(
          apiService: mockApi,
          initialDevices: [],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<DeviceProvider>.value(
              value: provider,
              child: const HomeScreen(),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Chưa có nút bấm nào'), findsOneWidget);
        expect(find.text('Thêm nút nhấn mới'), findsOneWidget);
      },
    );
  });
}
