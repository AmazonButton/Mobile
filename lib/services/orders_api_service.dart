import '../models/page_result.dart';
import '../models/order_timeline_entry.dart';
import 'stock_service.dart';
import 'products_api_service.dart';
import '../models/order_model.dart';
import 'api_client.dart';
import 'api_config.dart';

class OrdersApiService {
  static final OrdersApiService _instance = OrdersApiService._internal();
  factory OrdersApiService() => _instance;
  OrdersApiService._internal();

  final ApiClient _client = ApiClient();
  final Set<String> _ordering = {};

  /// Lấy danh sách lịch sử đơn hàng của người dùng được ánh xạ thành strongly-typed OrderModel
  Future<List<OrderModel>> getOrders({String? status}) async {
    final orders = <String, OrderModel>{};
    var page = 1;
    while (true) {
      final batch = await getOrdersPage(page: page, status: status);
      for (final order in batch.items) {
        orders[order.id] = order;
      }
      if (!batch.hasNextPage) return orders.values.toList();
      page++;
    }
  }

  Future<PageResult<OrderModel>> getOrdersPage({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? paymentStatus,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      'paymentStatus': ?paymentStatus,
      if (fromDate != null) 'fromDate': fromDate.toUtc().toIso8601String(),
      if (toDate != null) 'toDate': toDate.toUtc().toIso8601String(),
    };
    if (status != null && status.isNotEmpty) query['status'] = status;

    final response = await _client.get(ApiConfig.orders, queryParams: query);
    final batch = PageResult<Map<String, dynamic>>.fromResponse(
      response,
      (row) => row,
      requestedPage: page,
      pageSize: pageSize,
    );
    final data = batch.items;
    {
      // Older order responses omit images; resolve via 3-min cached product map
      // only if any order line is missing an image.
      final needsCatalog = data.any((raw) {
        final items = raw['items'] is List ? raw['items'] : raw['orderItems'];
        if (items is! List) return false;
        return items.any((line) {
          if (line is! Map) return false;
          final nested = line['product'];
          final hasImg =
              (line['imageUrl'] ?? line['thumbnailUrl']) != null ||
              (nested is Map &&
                  (nested['imageUrl'] ?? nested['thumbnailUrl']) != null);
          return !hasImg;
        });
      });
      var catalog = <String, Map>{};
      if (needsCatalog) {
        try {
          catalog = await ProductsApiService()
              .getProductMapCached()
              .timeout(const Duration(seconds: 2), onTimeout: () => {});
        } catch (_) {
          // Product lookup must not prevent customers from viewing their orders.
        }
      }
      final orders = data.map((raw) {
        final item = Map<String, dynamic>.from(raw);
        final key = item['items'] is List ? 'items' : 'orderItems';
        final items = item[key];
        if (items is List) {
          item[key] = items.map((line) {
            if (line is! Map) return line;
            final copy = Map<String, dynamic>.from(line);
            final nested = copy['product'];
            final id =
                copy['productId'] ??
                (nested is Map ? nested['productId'] ?? nested['id'] : null);
            final product = id == null ? null : catalog[id.toString()];
            if (product != null) {
              copy['product'] = {
                ...product,
                if (nested is Map) ...nested,
                'imageUrl': product['imageUrl'] ?? product['thumbnailUrl'],
                'images': product['images'],
              };
            }
            return copy;
          }).toList();
        }
        return OrderModel.fromJson(item);
      }).toList();
      return PageResult(
        items: orders,
        page: batch.page,
        pageSize: batch.pageSize,
        totalItems: batch.totalItems,
        hasNextPage: batch.hasNextPage,
      );
    }
  }

  Future<List<OrderTimelineEntry>> getTimeline(String id) async {
    final response = await _client.get(
      '/orders/${Uri.encodeComponent(id)}/timeline',
    );
    final rows = response['data']?['timeline'];
    if (rows is! List) {
      throw const FormatException('Không thể tải lịch sử đơn hàng');
    }
    final entries = rows
        .map<OrderTimelineEntry>(
          (row) => OrderTimelineEntry.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
    entries.sort(
      (a, b) => (a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0)),
    );
    return entries;
  }

  /// Lấy thông tin chi tiết một đơn hàng theo ID
  Future<Map<String, dynamic>> getOrderById(String id) async {
    final response = await _client.get(ApiConfig.orderDetail(id));
    return response['data'] ?? response;
  }

  /// Đặt hàng siêu tốc 1 chạm bằng deviceId của nút bấm IoT
  Future<Map<String, dynamic>> quickReorder({required String deviceId}) async {
    final id = deviceId.trim();
    if (!_ordering.add(id)) {
      throw ApiException(message: 'Đang xử lý đặt hàng', statusCode: 409);
    }
    try {
      await StockService.instance.verify(id);
      final response = await _client.post(
        ApiConfig.ordersQuickReorder,
        body: {'deviceId': id},
      );
      await StockService.instance.refreshDevice(id);
      return response;
    } catch (error) {
      await StockService.instance.refreshDevice(id);
      if (error is ApiException &&
          error.errorCode != 'MOBILE_STOCK_UNAVAILABLE' &&
          (error.message.contains('P0007') ||
              error.message.toLowerCase().contains('không đủ tồn kho'))) {
        throw ApiException(
          message:
              'Sản phẩm vừa hết hoặc không đủ số lượng. Vui lòng kiểm tra lại tồn kho.',
          statusCode: error.statusCode,
          errorCode: 'MOBILE_STOCK_UNAVAILABLE',
        );
      }
      rethrow;
    } finally {
      _ordering.remove(id);
    }
  }

  /// Hủy đơn hàng với lý do cụ thể
  Future<Map<String, dynamic>> cancelOrder(String id, {String? reason}) async {
    final response = await _client.post(
      ApiConfig.orderCancel(id),
      body: {if (reason != null && reason.isNotEmpty) 'reason': reason},
    );
    return response;
  }

  /// Cập nhật trạng thái đơn hàng (Store Owner / Staff: CONFIRMED, PREPARING, READY_FOR_DELIVERY, SHIPPING, DELIVERED, COMPLETED)
  Future<Map<String, dynamic>> updateOrderStatus(
    String id, {
    required String status,
    String? note,
  }) async {
    final response = await _client.patch(
      ApiConfig.orderStatus(id),
      body: {
        'status': status,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : response;
  }

  /// Tính phí giao hàng Goong 5km freeship trực tiếp từ Backend
  Future<Map<String, dynamic>> getDeliveryQuote({
    required dynamic storeId,
    String? deliveryAddress,
    double? latitude,
    double? longitude,
  }) async {
    final response = await _client.post(
      ApiConfig.ordersDeliveryQuote,
      body: {
        'storeId': storeId,
        if (deliveryAddress != null && deliveryAddress.isNotEmpty)
          'deliveryAddress': deliveryAddress,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
    return response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : response;
  }

  /// Giả lập sự kiện nút bấm vật lý tạo đơn hàng
  Future<Map<String, dynamic>> simulateButtonPress({
    required String deviceId,
    String eventType = 'SINGLE_PRESS',
  }) async {
    final response = await _client.post(
      ApiConfig.ordersSimulatePress,
      body: {'deviceId': deviceId, 'eventType': eventType},
    );
    return response;
  }
}
