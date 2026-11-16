class OrderTimelineEntry {
  final String id, type, title, description;
  final String? status, podImageUrl;
  final DateTime? timestamp;
  const OrderTimelineEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.status,
    this.timestamp,
    this.podImageUrl,
  });
  factory OrderTimelineEntry.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] is Map
        ? json['metadata'] as Map
        : const {};
    final url = metadata['podImageUrl']?.toString();
    final uri = Uri.tryParse(url ?? '');
    return OrderTimelineEntry(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Cập nhật đơn hàng',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString(),
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? ''),
      podImageUrl:
          uri != null &&
              {'http', 'https'}.contains(uri.scheme) &&
              uri.host.isNotEmpty
          ? url
          : null,
    );
  }
}
