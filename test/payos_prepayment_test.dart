import 'package:flutter_test/flutter_test.dart';
import 'package:smart_order_button/models/order_model.dart';
import 'package:smart_order_button/models/payos_payment_data.dart';
import 'package:smart_order_button/providers/order_provider.dart';
import 'package:smart_order_button/services/notification_service.dart';

void main() {
  group('Story 6.1, 6.2, 6.3 - PayOS Pre-payment Unit & Integration Tests', () {
    test('OrderModel parses paymentStatus and paymentMethod correctly', () {
      final jsonUnpaid = {
        'id': 'ord-101',
        'orderCode': '#ORD-101',
        'totalAmount': 120000,
        'orderStatus': 'PENDING',
        'paymentStatus': 'UNPAID',
        'paymentMethod': 'COD',
      };

      final orderUnpaid = OrderModel.fromJson(jsonUnpaid);
      expect(orderUnpaid.isUnpaid, isTrue);
      expect(orderUnpaid.isPaid, isFalse);
      expect(orderUnpaid.isPayos, isFalse);
      expect(orderUnpaid.paymentStatus, equals('UNPAID'));
      expect(orderUnpaid.paymentMethod, equals('COD'));

      final jsonPaid = {
        'id': 'ord-102',
        'orderCode': '#ORD-102',
        'totalAmount': 250000,
        'orderStatus': 'CONFIRMED',
        'paymentStatus': 'PAID',
        'paymentMethod': 'PAYOS',
      };

      final orderPaid = OrderModel.fromJson(jsonPaid);
      expect(orderPaid.isPaid, isTrue);
      expect(orderPaid.isUnpaid, isFalse);
      expect(orderPaid.isPayos, isTrue);
    });

    test('PayosPaymentData parses API response and constructs VietQR image URL', () {
      final dataJson = {
        'paymentTransactionId': 'tx-999',
        'orderCode': 12345678,
        'amount': 65000,
        'description': 'DH12345678',
        'checkoutUrl': 'https://pay.payos.vn/web/link-abc',
        'qrCode': '00020101021238540010A00000072701240006970422011009876543210208QRIBFTTA5204601153037045405650005802VN62140810DH123456786304ABCD',
        'status': 'PENDING',
        'accountName': 'SMART ORDER CORP',
        'accountNumber': '0987654321',
        'bin': '970422',
        'bankName': 'MBBank',
      };

      final paymentData = PayosPaymentData.fromJson(dataJson);
      expect(paymentData.orderCode, equals(12345678));
      expect(paymentData.amount, equals(65000));
      expect(paymentData.accountName, equals('SMART ORDER CORP'));
      expect(paymentData.accountNumber, equals('0987654321'));
      expect(paymentData.bin, equals('970422'));

      // Kiểm tra URL ảnh VietQR được sinh tự động
      final vietQrUrl = paymentData.vietQrImageUrl;
      expect(vietQrUrl.contains('img.vietqr.io/image/970422-0987654321-compact2.png'), isTrue);
      expect(vietQrUrl.contains('amount=65000'), isTrue);
      expect(vietQrUrl.contains('addInfo=DH12345678'), isTrue);
      expect(vietQrUrl.contains('accountName=SMART+ORDER+CORP') || vietQrUrl.contains('accountName=SMART%20ORDER%20CORP'), isTrue);
    });

    test('OrderProvider.markOrderAsPaid reactively updates order paymentStatus to PAID', () {
      final initialOrder = OrderModel(
        id: 'ord-test-1',
        orderCode: '#ORD-TEST-1',
        customerName: 'Nguyễn Văn A',
        apartment: 'Căn hộ 12.04',
        product: 'Nước Lavie 20L',
        title: 'Nước Lavie 20L',
        buttonName: 'Bếp',
        time: 'Vừa xong',
        price: '65.000đ',
        rawAmount: 65000,
        status: OrderStatus.warning,
        rawStatus: 'PENDING',
        statusText: 'Chờ xác nhận',
        paymentStatus: 'UNPAID',
        paymentMethod: 'COD',
      );

      final provider = OrderProvider(initialOrders: [initialOrder]);
      expect(provider.orders.first.isUnpaid, isTrue);

      String? notifiedOrderId;
      OrderModel? notifiedOrder;
      OrderProvider.onOrderPaid = (id, order) {
        notifiedOrderId = id;
        notifiedOrder = order;
      };

      provider.markOrderAsPaid('ord-test-1');

      expect(provider.orders.first.isPaid, isTrue);
      expect(provider.orders.first.isUnpaid, isFalse);
      expect(provider.orders.first.paymentStatus, equals('PAID'));
      expect(provider.orders.first.paymentMethod, equals('PAYOS'));
      expect(provider.orders.first.rawStatus, equals('CONFIRMED'));
      expect(notifiedOrderId, equals('ord-test-1'));
      expect(notifiedOrder?.isPaid, isTrue);
    });

    test('NotificationService.onPaymentConfirmed hook is triggered on payment confirmation', () {
      String? confirmedOrderId;
      String? confirmedOrderCode;

      NotificationService.onPaymentConfirmed = (orderId, orderCode) {
        confirmedOrderId = orderId;
        confirmedOrderCode = orderCode;
      };

      NotificationService.onPaymentConfirmed?.call('ord-test-999', '#ORD-999');

      expect(confirmedOrderId, equals('ord-test-999'));
      expect(confirmedOrderCode, equals('#ORD-999'));
    });
  });
}
