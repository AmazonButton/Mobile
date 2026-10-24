import 'package:flutter/widgets.dart';
import '../models/product_stock.dart';
import 'products_api_service.dart';
import 'devices_api_service.dart';
import 'api_client.dart';

class StockService extends ChangeNotifier with WidgetsBindingObserver {
  static final StockService instance = StockService._();
  StockService._() {
    WidgetsBinding.instance.addObserver(this);
  }
  final Map<String, ProductStock?> stocks = {};
  final Map<String, List<Map<String, dynamic>>> configurations = {};
  final Map<String, Future<void>> _pending = {};
  final Set<String> _tracked = {};
  ProductStock? stock(String id) => stocks[id];
  void remember(String id, dynamic inventory) {
    stocks[id] = ProductStock.fromJson(inventory);
  }

  Future<void> refreshDevice(String id) =>
      _pending[id] ??= _refreshDevice(id).whenComplete(() {
        _pending.remove(id);
      });
  Future<void> _refreshDevice(String id) async {
    _tracked.add(id);
    try {
      final device = await DevicesApiService().getDeviceById(id);
      final raw = device['products'] ?? device['buttonProducts'];
      if (raw is! List) throw StateError('Missing configuration');
      final items = raw
          .whereType<Map>()
          .map((p) => Map<String, dynamic>.from(p))
          .toList();
      configurations[id] = items;
      await Future.wait(
        items.map((item) async {
          final productId = (item['productId'] ?? item['product']?['productId'])
              ?.toString();
          if (productId == null) return;
          stocks[productId] = null;
          try {
            final product = await ProductsApiService().getProductById(
              productId,
            );
            remember(
              productId,
              product['status'] == 'ACTIVE' ? product['inventory'] : null,
            );
          } catch (_) {
            stocks[productId] = null;
          }
        }),
      );
    } catch (_) {
      configurations.remove(id);
    }
    notifyListeners();
  }

  Future<void> refreshAll() async {
    await Future.wait(_tracked.toList().map(refreshDevice));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refreshAll();
  }

  String? problem(String id) {
    final items = configurations[id];
    if (items == null) return 'Chưa kiểm tra được tồn kho';
    if (items.isEmpty) return 'Chưa gán sản phẩm';
    for (final item in items) {
      final productId = (item['productId'] ?? item['product']?['productId'])
          ?.toString();
      final quantity = int.tryParse(item['quantity'].toString());
      final value = stocks[productId];
      if (value == null || quantity == null || quantity < 1) {
        return 'Chưa kiểm tra được tồn kho';
      }
      if (value.available < quantity) {
        return '${item['productName'] ?? 'Sản phẩm'}: ${value.label(quantity)}';
      }
    }
    return null;
  }

  Future<void> verify(String id) async {
    final pending = _pending[id];
    if (pending != null) await pending;
    await refreshDevice(id);
    final message = problem(id);
    if (message != null) {
      throw ApiException(
        message: message,
        statusCode: 409,
        errorCode: 'MOBILE_STOCK_UNAVAILABLE',
      );
    }
  }
}
