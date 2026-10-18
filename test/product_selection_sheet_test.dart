import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_order_button/models/button_product_model.dart';
import 'package:smart_order_button/widgets/modals/product_selection_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProductSelectionSheet Canonical Component (Story 2.2)', () {
    testWidgets('Renders products list and allows selecting and saving a product', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      ButtonProductModel? savedProduct;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ProductSelectionSheet.show(
                    context: context,
                    buttonName: 'Nút Bếp',
                    currentProductName: 'Lavie 19L',
                    onSave: (product) {
                      savedProduct = product;
                    },
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      // Open bottom sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Verify sheet title
      expect(find.text('Cấu hình Nút Bếp'), findsOneWidget);

      // Verify categories appear
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Nước uống'), findsOneWidget);
      expect(find.text('Gas'), findsOneWidget);

      // Verify save button exists
      final saveButton = find.text('Lưu thay đổi');
      expect(saveButton, findsOneWidget);

      // Tap save button
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify callback received the selected product
      expect(savedProduct, isNotNull);
      expect(savedProduct!.shortName, 'Nước Lavie 20L');
    });

    testWidgets('Filters products by category filter', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ProductSelectionSheet.show(
                    context: context,
                    buttonName: 'Nút Phòng Khách',
                    currentProductName: 'Nước Aquafina 20L',
                    onSave: (_) {},
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Tap 'Gas' category chip
      await tester.tap(find.text('Gas'));
      await tester.pumpAndSettle();

      // Verify Gas products are shown
      expect(find.text('Bình Gas Saigon Petro 12kg'), findsWidgets);
    });
  });
}
