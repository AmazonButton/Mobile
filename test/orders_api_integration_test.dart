import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_order_button/models/order_model.dart';
import 'package:smart_order_button/providers/order_provider.dart';
import 'package:smart_order_button/screens/orders_screen.dart';
import 'package:smart_order_button/services/orders_api_service.dart';

class MockOrdersApiService implements OrdersApiService {
  List<OrderModel> mockOrders = [];
  bool shouldFail = false;
  int getOrdersCalls = 0;
  int cancelOrderCalls = 0;
  String? lastCancelledId;

  @override
  Future<List<OrderModel>> getOrders({String? status}) async {
    getOrdersCalls++;
    if (shouldFail) {
      throw Exception('Không thể kết nối đến máy chủ đơn hàng');
    }
    return mockOrders;
  }

  @override
  Future<Map<String, dynamic>> cancelOrder(String id, {String? reason}) async {
    cancelOrderCalls++;
    lastCancelledId = id;
    if (shouldFail) {
      throw Exception('Lỗi hủy đơn');
    }
    return {'success': true, 'message': 'Đã hủy đơn'};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Story 3.3 - OrderProvider & Orders API Integration Tests', () {
    late MockOrdersApiService mockApi;

    setUp(() {
      mockApi = MockOrdersApiService();
    });

    test('OrderProvider loads orders and separates active vs history correctly', () async {
      mockApi.mockOrders = [
        const OrderModel(
          id: 'ord-active-1',
          orderCode: '#ORD-001',
          customerName: 'Nguyễn Văn A',
          apartment: 'P1204',
          product: 'Lavie 20L',
          time: '10:00',
          price: '65.000đ',
          rawAmount: 65000,
          status: OrderStatus.warning,
          rawStatus: 'PENDING',
          statusText: 'Chờ xử lý',
        ),
        const OrderModel(
          id: 'ord-active-2',
          orderCode: '#ORD-002',
          customerName: 'Nguyễn Văn A',
          apartment: 'P1204',
          product: 'Aquafina 500ml',
          time: '09:30',
          price: '98.000đ',
          rawAmount: 98000,
          status: OrderStatus.info,
          rawStatus: 'SHIPPING',
          statusText: 'Đang giao',
        ),
        const OrderModel(
          id: 'ord-history-1',
          orderCode: '#ORD-003',
          customerName: 'Nguyễn Văn A',
          apartment: 'P1204',
          product: 'Gas Petrolimex 12kg',
          time: 'Hôm qua',
          price: '380.000đ',
          rawAmount: 380000,
          status: OrderStatus.success,
          rawStatus: 'DELIVERED',
          statusText: 'Đã giao',
        ),
      ];

      final provider = OrderProvider(apiService: mockApi, initialOrders: []);

      expect(provider.orders.isEmpty, isTrue);
      expect(provider.isLoading, isFalse);

      final future = provider.loadOrders();
      expect(provider.isLoading, isTrue);

      await future;
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.orders.length, equals(3));
      expect(provider.activeOrders.length, equals(2));
      expect(provider.historyOrders.length, equals(1));
      expect(provider.totalSpend, equals(380000));
      expect(mockApi.getOrdersCalls, equals(1));
    });

    test('OrderProvider handles empty orders list from backend', () async {
      mockApi.mockOrders = [];
      final provider = OrderProvider(
        apiService: mockApi,
        initialOrders: List.from(OrderModel.sampleOrders),
      );

      expect(provider.orders.isNotEmpty, isTrue);

      await provider.loadOrders();

      expect(provider.orders.isEmpty, isTrue);
      expect(provider.activeOrders.isEmpty, isTrue);
      expect(provider.historyOrders.isEmpty, isTrue);
      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, isFalse);
    });

    test('OrderProvider handles network error gracefully', () async {
      mockApi.shouldFail = true;

      final initial = [
        const OrderModel(
          id: 'ord-initial',
          customerName: 'Nguyễn Văn A',
          apartment: 'P1204',
          product: 'Lavie 20L',
          time: '10:00',
          status: OrderStatus.warning,
          statusText: 'Chờ xử lý',
        ),
      ];

      final provider = OrderProvider(apiService: mockApi, initialOrders: initial);

      await provider.loadOrders();

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, contains('Không thể kết nối đến máy chủ đơn hàng'));
      expect(provider.orders.length, equals(1));
    });

    test('OrderProvider cancels order and shifts it to history', () async {
      final initial = [
        const OrderModel(
          id: 'ord-cancel-target',
          orderCode: '#ORD-999',
          customerName: 'Nguyễn Văn A',
          apartment: 'P1204',
          product: 'Nước Lavie 20L',
          time: '12:00',
          price: '65.000đ',
          status: OrderStatus.warning,
          rawStatus: 'PENDING',
          statusText: 'Chờ xử lý',
        ),
      ];

      final provider = OrderProvider(apiService: mockApi, initialOrders: initial);

      expect(provider.activeOrders.length, equals(1));
      expect(provider.historyOrders.length, equals(0));

      await provider.cancelOrder('ord-cancel-target');

      expect(mockApi.cancelOrderCalls, equals(1));
      expect(mockApi.lastCancelledId, equals('ord-cancel-target'));
      expect(provider.activeOrders.length, equals(0));
      expect(provider.historyOrders.length, equals(1));
      expect(provider.historyOrders.first.rawStatus, equals('CANCELLED'));
      expect(provider.historyOrders.first.statusText, equals('Đã hủy'));
    });

    test('OrderProvider.refreshOrders calls loadOrders', () async {
      mockApi.mockOrders = [];
      final provider = OrderProvider(apiService: mockApi);

      await provider.refreshOrders();
      expect(mockApi.getOrdersCalls, equals(1));
    });
  });

  group('Story 3.3 - OrdersScreen UI Integration Tests', () {
    testWidgets('OrdersScreen displays empty state when no active orders exist', (tester) async {
      final mockApi = MockOrdersApiService();
      mockApi.mockOrders = [];

      final provider = OrderProvider(apiService: mockApi, initialOrders: []);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<OrderProvider>.value(
            value: provider,
            child: const OrdersScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Không có đơn hàng nào đang diễn ra'), findsOneWidget);
      expect(find.text('Đang diễn ra (0)'), findsOneWidget);
      expect(find.text('Lịch sử (0)'), findsOneWidget);
    });

    testWidgets('OrdersScreen displays Error State with retry button on network failure', (tester) async {
      final mockApi = MockOrdersApiService();
      mockApi.shouldFail = true;

      final provider = OrderProvider(apiService: mockApi, initialOrders: []);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<OrderProvider>.value(
            value: provider,
            child: const OrdersScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Không thể tải đơn hàng'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);

      // Now fix mock network and tap retry
      mockApi.shouldFail = false;
      mockApi.mockOrders = [
        const OrderModel(
          id: 'ord-recovered',
          orderCode: '#ORD-REC',
          customerName: 'Nguyễn Văn A',
          apartment: 'P1204',
          product: 'Nước Lavie 20L',
          time: 'Vừa xong',
          price: '65.000đ',
          status: OrderStatus.warning,
          rawStatus: 'PENDING',
          statusText: 'Chờ xử lý',
        ),
      ];

      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Không thể tải đơn hàng'), findsNothing);
      expect(find.text('Nước Lavie 20L'), findsOneWidget);
      expect(find.text('Đang diễn ra (1)'), findsOneWidget);
    });

    testWidgets('OrdersScreen supports pull-to-refresh on active tab', (tester) async {
      final mockApi = MockOrdersApiService();
      mockApi.mockOrders = [];

      final provider = OrderProvider(apiService: mockApi, initialOrders: []);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<OrderProvider>.value(
            value: provider,
            child: const OrdersScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.fling(find.byType(ListView).first, const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(mockApi.getOrdersCalls, greaterThanOrEqualTo(1));
    });
  });
}
