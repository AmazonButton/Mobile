import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_order_button/models/button_product_model.dart';
import 'package:smart_order_button/providers/providers.dart';
import 'package:smart_order_button/screens/devices_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Centralized State Architecture & Provider Integration (Story 3.1)', () {
    test('DeviceProvider updates device product and notifies listeners', () {
      final deviceProvider = DeviceProvider();
      expect(deviceProvider.devices.first.product, 'Nước Lavie 20L');

      const newProduct = ButtonProductModel(
        id: 'prod-petrolimex-12kg',
        name: 'Bình Gas Petrolimex 12kg',
        shortName: 'Bình Gas Petrolimex 12kg',
        brand: 'Petrolimex',
        specs: '12kg',
        price: 380000,
        priceFormatted: '380.000đ',
        unitPriceFormatted: '31.666đ/kg',
        discountTag: 'Ưu đãi',
        deliveryTag: 'Giao nhanh 2h',
        rating: 4.9,
        reviewCount: 100,
        description: 'Gas Petrolimex chính hãng',
        category: 'Năng lượng / Bếp',
        icon: Icons.local_fire_department,
        themeColor: Colors.orange,
      );

      bool notified = false;
      deviceProvider.addListener(() {
        notified = true;
      });

      deviceProvider.updateDeviceProduct('btn-1', newProduct);

      expect(notified, isTrue);
      expect(deviceProvider.devices.first.product, 'Bình Gas Petrolimex 12kg');
      expect(deviceProvider.devices.first.price, '380.000đ');
      expect(deviceProvider.devices.first.badgeText, '12kg');
    });

    test('OrderProvider manages active and history orders and notifies listeners', () async {
      final orderProvider = OrderProvider();
      expect(orderProvider.orders.isNotEmpty, isTrue);
      expect(orderProvider.activeOrders.isNotEmpty, isTrue);
      expect(orderProvider.historyOrders.isNotEmpty, isTrue);

      bool notified = false;
      orderProvider.addListener(() {
        notified = true;
      });

      await orderProvider.cancelOrder('SOB-20260919-003');
      expect(notified, isTrue);
    });

    test('UserProvider manages user details and notifies listeners', () {
      final userProvider = UserProvider();
      bool notified = false;
      userProvider.addListener(() {
        notified = true;
      });

      userProvider.updateName('Lê Hoàng Long');
      expect(notified, isTrue);
      expect(userProvider.name, 'Lê Hoàng Long');
      expect(userProvider.shortName, 'Long');

      userProvider.updatePhone('0988776655');
      expect(userProvider.phone, '0988776655');
    });

    testWidgets('Device update dispatched via DeviceProvider reactively syncs to UI', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final deviceProvider = DeviceProvider();
      final orderProvider = OrderProvider();
      final userProvider = UserProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: deviceProvider),
            ChangeNotifierProvider.value(value: orderProvider),
            ChangeNotifierProvider.value(value: userProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DevicesScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initial state contains 'Nước Lavie 20L'
      expect(find.text('Nước Lavie 20L'), findsWidgets);

      // Programmatically update the product in DeviceProvider
      const updatedProduct = ButtonProductModel(
        id: 'prod-saigonpetro-12kg',
        name: 'Bình Gas Saigon Petro 12kg',
        shortName: 'Bình Gas Saigon Petro 12kg',
        brand: 'Saigon Petro',
        specs: '12kg',
        price: 365000,
        priceFormatted: '365.000đ',
        unitPriceFormatted: '30.416đ/kg',
        discountTag: 'Ưu đãi',
        deliveryTag: 'Giao nhanh 45 phút',
        rating: 4.8,
        reviewCount: 50,
        description: 'Gas Saigon Petro chính hãng',
        category: 'Năng lượng / Bếp',
        icon: Icons.local_fire_department,
        themeColor: Colors.orange,
      );

      deviceProvider.updateDeviceProduct('btn-1', updatedProduct);
      await tester.pumpAndSettle();

      // UI is reactively updated without manual page reload
      expect(find.text('Bình Gas Saigon Petro 12kg'), findsWidgets);
      expect(find.text('365.000đ'), findsWidgets);
    });
  });
}
