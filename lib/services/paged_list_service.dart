import '../models/page_result.dart';
import 'api_client.dart';

/// Supports the current envelope and legacy {data:{items,...}} lists.
/// Fetches page 1 first and loads remaining pages (up to [maxPages]) in parallel
/// to eliminate slow sequential network waterfalls.
Future<List<Map<String, dynamic>>> getAllApiPages(
  String path, {
  Map<String, dynamic> query = const {},
  int maxPages = 3,
}) async {
  final result = <String, Map<String, dynamic>>{};
  final withoutId = <Map<String, dynamic>>[];

  void collect(List<Map<String, dynamic>> items) {
    for (final row in items) {
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
  }

  final firstResponse = await ApiClient().get(
    path,
    queryParams: {...query, 'page': 1, 'pageSize': 50, 'limit': 50},
  );
  final firstBatch = PageResult<Map<String, dynamic>>.fromResponse(
    firstResponse,
    (row) => row,
    requestedPage: 1,
    pageSize: 50,
  );
  collect(firstBatch.items);

  if (!firstBatch.hasNextPage || maxPages <= 1) {
    return [...result.values, ...withoutId];
  }

  final totalItems = firstBatch.totalItems;
  final effectivePageSize = firstBatch.items.isNotEmpty
      ? firstBatch.items.length
      : firstBatch.pageSize;
  final estimatedPages = totalItems != null && effectivePageSize > 0
      ? ((totalItems + effectivePageSize - 1) ~/ effectivePageSize)
      : maxPages;
  final lastPage = estimatedPages < maxPages ? estimatedPages : maxPages;

  if (lastPage >= 2) {
    final futures = <Future<PageResult<Map<String, dynamic>>?>>[];
    for (var p = 2; p <= lastPage; p++) {
      futures.add(
        ApiClient()
            .get(path, queryParams: {...query, 'page': p, 'pageSize': 50, 'limit': 50})
            .then(
              (resp) => PageResult<Map<String, dynamic>>.fromResponse(
                resp,
                (row) => row,
                requestedPage: p,
                pageSize: 50,
              ),
            )
            .catchError((_) => null),
      );
    }
    final batches = await Future.wait(futures);
    for (final b in batches) {
      if (b != null) collect(b.items);
    }
  }

  return [...result.values, ...withoutId];
}
