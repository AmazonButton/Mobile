class ProductStock {
  final int available;
  final int threshold;
  const ProductStock(this.available, this.threshold);
  static ProductStock? fromJson(dynamic value) {
    if (value is! Map) return null;
    int? integer(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '');
    final onHand = integer(value['quantityOnHand']);
    final reserved = integer(value['reservedQuantity']);
    if (onHand == null || reserved == null || onHand < 0 || reserved < 0) {
      return null;
    }
    return ProductStock(
      (onHand - reserved).clamp(0, onHand),
      integer(value['minStockAlert']) ?? 5,
    );
  }

  String label([int quantity = 1]) {
    if (available == 0) return 'Hết hàng';
    if (available < quantity) return 'Còn $available, cần $quantity';
    if (available <= threshold) return 'Sắp hết · Còn $available';
    return 'Còn $available sản phẩm';
  }
}
