import 'api_client.dart';
import 'api_config.dart';

class ProductsApiService {
  static final ProductsApiService _instance = ProductsApiService._internal();
  factory ProductsApiService() => _instance;
  ProductsApiService._internal();

  final ApiClient _client = ApiClient();

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

    final response = await _client.get(ApiConfig.products, queryParams: query);
    final data = response['data'] ?? response;
    if (data is List) {
      return data;
    }
    return [];
  }

  /// Lấy thông tin chi tiết một sản phẩm
  Future<Map<String, dynamic>> getProductById(String id) async {
    final response = await _client.get(ApiConfig.productDetail(id));
    return response['data'] ?? response;
  }
}
