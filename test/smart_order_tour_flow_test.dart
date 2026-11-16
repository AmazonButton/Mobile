import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_order_button/widgets/smart_order_tour.dart';

void main() {
  testWidgets(
    'Continue only introduces features; completion persists per account',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      late SmartOrderTour tour;
      SmartOrderTour? existingTour;
      var writes = 0;
      var currentTab = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              tour = existingTour ??= SmartOrderTour(
                context: context,
                changeTab: (tab) => currentTab = tab,
              );
              return Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final step in [
                        TourStep.add,
                        TourStep.stores,
                        TourStep.orders,
                        TourStep.addresses,
                        TourStep.bank,
                        TourStep.deposit,
                        TourStep.identity,
                      ])
                        TextButton(
                          key: tour.key(step),
                          onPressed: () => writes++,
                          child: Text('Target ${step.name}'),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
      addTearDown(tour.dispose);
      await tour.accountChanged('first-user');
      Future<void> next() async {
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tiếp tục'));
      }

      await next();
      expect(tour.isAt(TourStep.add), isTrue);
      expect(currentTab, 1);
      await next();
      expect(tour.isAt(TourStep.stores), isTrue);
      expect(currentTab, 0);
      expect(find.text('Đã kết nối nút thành công'), findsNothing);
      await next();
      expect(tour.isAt(TourStep.orders), isTrue);
      expect(currentTab, 2);
      await next();
      expect(tour.isAt(TourStep.addresses), isTrue);
      await next();
      expect(tour.isAt(TourStep.deposit), isTrue);
      await next();
      expect(tour.isAt(TourStep.bank), isTrue);
      await next();
      expect(tour.isAt(TourStep.identity), isTrue);
      await next();
      await tester.pumpAndSettle();
      expect(writes, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('smartorder.spotlight.v1.first-user'),
        'completed',
      );
      await tour.accountChanged(null);
      await tour.accountChanged('first-user');
      expect(tour.isAt(TourStep.intro), isFalse);
      tour.replay();
      expect(tour.isAt(TourStep.intro), isTrue);
      tour.dismiss();
    },
  );

  testWidgets(
    'real add tap opens next guide automatically; Back never claims success',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      late SmartOrderTour tour;
      SmartOrderTour? existingTour;
      var opens = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              tour = existingTour ??= SmartOrderTour(
                context: context,
                changeTab: (_) {},
              );
              return Scaffold(
                body: Column(
                  children: [
                    TextButton(
                      key: tour.key(TourStep.add),
                      child: const Text('Real add'),
                      onPressed: () async {
                        opens++;
                        tour.openConnect();
                        final result = await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  key: tour.key(TourStep.code),
                                  onChanged: tour.codeChanged,
                                ),
                                TextButton(
                                  key: tour.key(TourStep.connect),
                                  onPressed: () {},
                                  child: const Text('Real connect'),
                                ),
                              ],
                            ),
                          ),
                        );
                        tour.connectClosed(result == true);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      addTearDown(tour.dispose);
      await tour.accountChanged('connect-user');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Real add'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 100));
      expect(opens, 1);
      expect(tour.isAt(TourStep.code), isTrue);
      expect(find.text('Nhập mã kết nối'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'invalid-code');
      await tester.pump(const Duration(milliseconds: 100));
      expect(tour.isAt(TourStep.connect), isTrue);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(tour.isAt(TourStep.add), isTrue);
      expect(find.text('Đã kết nối nút thành công'), findsNothing);
      tour.dismiss();
    },
  );

  testWidgets(
    'background removes guide and resumes a valid target on small screen',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late SmartOrderTour tour;
      SmartOrderTour? existingTour;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              tour = existingTour ??= SmartOrderTour(
                context: context,
                changeTab: (_) {},
              );
              return Scaffold(
                body: TextButton(
                  key: tour.key(TourStep.add),
                  onPressed: () {},
                  child: const Text('Add'),
                ),
              );
            },
          ),
        ),
      );
      addTearDown(tour.dispose);
      await tour.accountChanged('small');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      tour.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump();
      expect(find.text('Bỏ qua'), findsNothing);
      tour.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ qua'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Bỏ qua'));
      await tester.pumpAndSettle();
    },
  );
}
