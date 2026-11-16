class PageResult<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int? totalItems;
  final bool hasNextPage;
  const PageResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.hasNextPage,
    this.totalItems,
  });

  factory PageResult.fromResponse(
    dynamic response,
    T Function(Map<String, dynamic>) decode, {
    required int requestedPage,
    required int pageSize,
  }) {
    if (response is! Map) {
      throw const FormatException('Phản hồi danh sách không hợp lệ');
    }
    final data = response['data'];
    final rows = data is List
        ? data
        : data is Map
        ? data['items'] ?? data['data']
        : null;
    if (rows is! List) throw const FormatException('Không thể đọc danh sách');
    final metadata = response['pagination'] is Map
        ? response['pagination'] as Map
        : data is Map
        ? data
        : const {};
    int? number(dynamic value) =>
        value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
    final current = number(metadata['page']) ?? requestedPage;
    final size = number(metadata['pageSize'] ?? metadata['limit']) ?? pageSize;
    final total = number(metadata['totalItems'] ?? metadata['total']);
    final pages = number(metadata['totalPages']);
    final hasNext = metadata['hasNextPage'] is bool
        ? metadata['hasNextPage'] as bool
        : pages != null
        ? current < pages
        : total != null
        ? current * size < total
        : false;
    if (current != requestedPage || size <= 0 || (hasNext && rows.isEmpty)) {
      throw const FormatException(
        'Thông tin phân trang không hợp lệ. Vui lòng tải lại.',
      );
    }
    return PageResult(
      items: rows
          .map<T>((row) => decode(Map<String, dynamic>.from(row as Map)))
          .toList(),
      page: current,
      pageSize: size,
      totalItems: total,
      hasNextPage: hasNext,
    );
  }
}
