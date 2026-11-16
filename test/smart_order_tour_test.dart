import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_order_button/widgets/smart_order_tour.dart';

void main() {
  testWidgets(
    'spotlight passes taps to the real target and stores skip by account',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      late SmartOrderTour tour;
      var targetTaps = 0;
      var otherTaps = 0;
      var tab = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              tour = SmartOrderTour(
                context: context,
                changeTab: (value) => tab = value,
              );
              return Scaffold(
                body: Column(
                  children: [
                    TextButton(
                      key: tour.key(TourStep.add),
                      onPressed: () => targetTaps++,
                      child: const Text('Add'),
                    ),
                    TextButton(
                      onPressed: () => otherTaps++,
                      child: const Text('Other'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      addTearDown(tour.dispose);
      await tour.accountChanged('101');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(tab, 1);
      await tester.tapAt(tester.getCenter(find.text('Other')));
      expect(otherTaps, 0);
      await tester.tap(find.text('Add'));
      expect(targetTaps, 1);
      await tester.tap(find.text('Bỏ qua'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other'));
      expect(otherTaps, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('smartorder.spotlight.v1.101'), 'skipped');
      await tour.accountChanged(null);
      await tour.accountChanged('101');
      expect(tour.isAt(TourStep.intro), isFalse);
      await tour.accountChanged('102');
      expect(tour.isAt(TourStep.intro), isTrue);
      tour.dismiss();
    },
  );
}
