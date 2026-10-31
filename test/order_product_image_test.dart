import 'package:flutter_test/flutter_test.dart';
import '../lib/models/order_model.dart';
void main() {
  test('Reads product images safely', () {
    for (final images in [[], null, [''], [{'imageUrl': ''}]]) {
      expect(OrderModel.fromJson({'items': [{'product': {'images': images}}]}).items.single.imageUrl, isNull);
    }
    for (final images in [
      ['https://example.com/product.png'],
      [{'imageUrl': 'https://example.com/product.png'}],
      [{'imageUrl': 'https://example.com/other.png'}, {'imageUrl': 'https://example.com/product.png', 'isPrimary': true}],
    ]) {
      expect(OrderModel.fromJson({'items': [{'imageUrl': '', 'product': {'images': images}}]}).items.single.imageUrl, 'https://example.com/product.png');
    }
  });
}
