import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_order_button/models/device_model.dart';
import 'package:smart_order_button/models/order_model.dart';
import 'package:smart_order_button/services/user_profile_service.dart';

void main() {
  group('Strongly-Typed Models & Services Relocation (Story 2.3)', () {
    test('UserProfileService is relocated to services/ and manages state cleanly', () {
      final service = UserProfileService();
      service.updateName('Trần Hoàng Nam');
      service.updatePhone('0912345678');
      service.updateEmail('nam.tran@example.com');
      service.updateAddress('Tòa Landmark 81, P.2501');

      expect(service.name, 'Trần Hoàng Nam');
      expect(service.shortName, 'Nam');
      expect(service.phone, '0912345678');
      expect(service.email, 'nam.tran@example.com');
      expect(service.address, 'Tòa Landmark 81, P.2501');
      expect(service.initials, 'TN');

      service.reset();
      expect(service.name, '');
      expect(service.phone, '');
      expect(service.email, '');
      expect(service.address, '');
    });

    group('OrderModel defensive parsing and typed properties', () {
      test('Parses backend order payload with nested orderItems', () {
        final json = {
          'id': 'ord-123',
          'orderCode': '#ORD-20261018-099',
          'status': 'SHIPPING',
          'createdAt': '2026-10-18T10:30:00Z',
          'totalAmount': 130000,
          'customer': {
            'fullName': 'Nguyễn Văn Minh',
          },
          'deliveryAddress': 'Căn hộ S2.05-1204',
          'button': {
            'buttonName': 'Nút Bếp',
            'deviceId': 'ESP32-KITCHEN',
          },
          'orderItems': [
            {
              'quantity': 2,
              'product': {
                'name': 'Nước khoáng LaVie 19L',
              },
            }
          ]
        };

        final order = OrderModel.fromJson(json);

        expect(order.id, 'ord-123');
        expect(order.orderCode, '#ORD-20261018-099');
        expect(order.displayTitle, '2x Nước khoáng LaVie 19L');
        expect(order.customerName, 'Nguyễn Văn Minh');
        expect(order.apartment, 'Căn hộ S2.05-1204');
        expect(order.buttonName, 'Nút Bếp');
        expect(order.deviceId, 'ESP32-KITCHEN');
        expect(order.rawAmount, 130000);
        expect(order.price, '130.000đ');
        expect(order.status, OrderStatus.info);
        expect(order.rawStatus, 'SHIPPING');
        expect(order.isShipping, isTrue);
        expect(order.isPending, isFalse);
        expect(order.isCompleted, isFalse);
        expect(order.icon, LucideIcons.droplets);
      });

      test('Parses emergency cancellable PENDING status order', () {
        final json = {
          'orderNumber': 'SOB-PENDING-001',
          'status': 'PENDING',
          'productName': 'Bình Gas Petrolimex 12kg',
          'totalAmount': 380000,
        };

        final order = OrderModel.fromJson(json);

        expect(order.id, 'SOB-PENDING-001');
        expect(order.orderCode, 'SOB-PENDING-001');
        expect(order.isPending, isTrue);
        expect(order.isEmergencyCancellable, isTrue);
        expect(order.status, OrderStatus.warning);
        expect(order.statusText, 'Chờ xác nhận');
        expect(order.icon, LucideIcons.flame);
      });

      test('Safely handles empty or missing JSON fields without throwing', () {
        final order = OrderModel.fromJson({});

        expect(order.id, 'SOB');
        expect(order.orderCode, '#SOB');
        expect(order.product, 'Nhu yếu phẩm');
        expect(order.displayTitle, 'Nhu yếu phẩm');
        expect(order.customerName, 'Cư dân');
        expect(order.apartment, 'Căn hộ');
        expect(order.status, OrderStatus.warning);
        expect(order.rawStatus, 'PENDING');
        expect(order.rawAmount, 0);
      });
    });

    group('DeviceModel defensive parsing, copyWith and typed properties', () {
      test('Parses backend device payload with buttonProducts and roomLocation', () {
        final json = {
          'deviceId': 'ESP32-LIVING-ROOM',
          'buttonName': 'Nút Bàn Trà',
          'roomLocation': 'Phòng khách tầng 2',
          'status': 'ACTIVE',
          'batteryLevel': 92,
          'buttonProducts': [
            {
              'product': {
                'name': 'Aquafina 500ml (24 chai)',
                'price': 98000,
              }
            }
          ],
        };

        final device = DeviceModel.fromJson(json);

        expect(device.id, 'ESP32-LIVING-ROOM');
        expect(device.name, 'Nút Bàn Trà');
        expect(device.room, 'Phòng khách tầng 2');
        expect(device.location, 'Phòng khách tầng 2');
        expect(device.product, 'Aquafina 500ml (24 chai)');
        expect(device.price, '98000đ');
        expect(device.battery, 92);
        expect(device.badgeText, '24 chai');
        expect(device.isOnline, isTrue);
        expect(device.isOffline, isFalse);
        expect(device.status, DeviceStatus.online);
      });

      test('Correctly flags warning status for low battery and offline status', () {
        final lowBatteryDevice = DeviceModel.fromJson({
          'deviceId': 'ESP32-LOW',
          'battery': 12,
          'status': 'ACTIVE',
        });
        expect(lowBatteryDevice.status, DeviceStatus.warning);
        expect(lowBatteryDevice.batteryText, '12%');

        final offlineDevice = DeviceModel.fromJson({
          'deviceId': 'ESP32-OFF',
          'status': 'OFFLINE',
          'battery': 50,
        });
        expect(offlineDevice.status, DeviceStatus.offline);
        expect(offlineDevice.isOffline, isTrue);
        expect(offlineDevice.batteryText, 'Offline');
      });

      test('copyWith creates modified clone while preserving untouched fields', () {
        const original = DeviceModel(
          id: 'dev-1',
          name: 'Nút Ban Công',
          room: 'Ban công',
          product: 'Nước Lavie 20L',
          price: '65.000đ',
          battery: 80,
          status: DeviceStatus.online,
        );

        final updated = original.copyWith(
          product: 'Bình Gas Petrolimex 12kg',
          price: '380.000đ',
          badgeText: '12kg',
        );

        expect(updated.id, 'dev-1');
        expect(updated.name, 'Nút Ban Công');
        expect(updated.room, 'Ban công');
        expect(updated.product, 'Bình Gas Petrolimex 12kg');
        expect(updated.price, '380.000đ');
        expect(updated.badgeText, '12kg');
        expect(updated.battery, 80);
      });
    });
  });
}
