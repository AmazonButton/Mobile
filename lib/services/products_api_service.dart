import 'paged_list_service.dart';
import 'api_client.dart';
import 'api_config.dart';

class ProductsApiService {
  static final ProductsApiService _instance = ProductsApiService._internal();
  factory ProductsApiService() => _instance;
  ProductsApiService._internal();

  final ApiClient _client = ApiClient();
  static Map<String, Map>? _cachedProductMap;
  static DateTime? _cachedProductMapAt;
  static Future<Map<String, Map>>? _inFlightMap;
  static const Duration _cacheTtl = Duration(minutes: 3);

  /// Cached product map by ID (3-min TTL + in-flight deduplication) to avoid
  /// re-fetching all product pages on every order/device load.
  Future<Map<String, Map>> getProductMapCached({bool forceRefresh = false}) {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedProductMap != null &&
        _cachedProductMapAt != null &&
        now.difference(_cachedProductMapAt!) < _cacheTtl) {
      return Future.value(_cachedProductMap!);
    }
    if (!forceRefresh && _inFlightMap != null) {
      return _inFlightMap!;
    }
    final future = () async {
      try {
        final products = await getProducts();
        final map = <String, Map>{};
        for (final product in products) {
          if (product is Map) {
            final id = product['productId'] ?? product['id'];
            if (id != null) map[id.toString()] = product;
          }
        }
        _cachedProductMap = map;
        _cachedProductMapAt = DateTime.now();
        return map;
      } finally {
        _inFlightMap = null;
      }
    }();
    _inFlightMap = future;
    return future;
  }

  /// Xem danh sách sản phẩm và tồn kho của cửa hàng
  Future<List<dynamic>> getProducts({
    String? storeId,
    String? category,
    String? search,
  }) async {
    final query = <String, dynamic>{};
    if (storeId != null && storeId.isNotEmpty) query['storeId'] = storeId;
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (search != null && search.isNotEmpty) query['search'] = search;

    return getAllApiPages(ApiConfig.products, query: query);
  }

  /// Lấy thông tin chi tiết một sản phẩm
  Future<Map<String, dynamic>> getProductById(String id) async {
    final response = await _client.get(ApiConfig.productDetail(id));
    return response['data'] ?? response;
  }

  /// Lấy danh sách ưu đãi / giảm giá đang áp dụng cho sản phẩm (đồng bộ với Web)
  Future<List<Map<String, dynamic>>> getProductDiscounts(String id) async {
    try {
      final response = await _client.get('${ApiConfig.productDetail(id)}/discounts');
      final data = response['data'];
      if (data is List) {
        return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
