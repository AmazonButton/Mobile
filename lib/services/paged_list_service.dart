import '../models/page_result.dart';
import 'api_client.dart';

/// Supports the current envelope and legacy {data:{items,...}} lists.
Future<List<Map<String, dynamic>>> getAllApiPages(
  String path, {
  Map<String, dynamic> query = const {},
}) async {
  final result = <String, Map<String, dynamic>>{};
  final withoutId = <Map<String, dynamic>>[];
  var page = 1;
  while (true) {
    final response = await ApiClient().get(
      path,
      queryParams: {...query, 'page': page, 'pageSize': 100},
    );
    final batch = PageResult<Map<String, dynamic>>.fromResponse(
      response,
      (row) => row,
      requestedPage: page,
      pageSize: 100,
    );
    for (final row in batch.items) {
      final id =
          row['orderId'] ??
          row['productId'] ??
          row['buttonId'] ??
          row['id'] ??
          row['storeId'];
      if (id == null) {
        withoutId.add(row);
      } else {
        result[id.toString()] = row;
      }
    }
    if (!batch.hasNextPage) return [...result.values, ...withoutId];
    page++;
  }
}
