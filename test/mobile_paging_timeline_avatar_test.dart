import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:smart_order_button/models/order_model.dart';
import 'package:smart_order_button/models/page_result.dart';
import 'package:smart_order_button/providers/order_provider.dart';
import 'package:smart_order_button/providers/user_provider.dart';
import 'package:smart_order_button/screens/orders/widgets/order_detail_bottom_sheet.dart';
import 'package:smart_order_button/screens/orders_screen.dart';
import 'package:smart_order_button/services/api_client.dart';
import 'package:smart_order_button/services/devices_api_service.dart';
import 'package:smart_order_button/services/notification_service.dart';
import 'package:smart_order_button/services/order_updates.dart';
import 'package:smart_order_button/services/orders_api_service.dart';
import 'package:smart_order_button/services/products_api_service.dart';
import 'package:smart_order_button/services/stores_api_service.dart';
import 'package:smart_order_button/services/user_profile_service.dart';
import 'package:smart_order_button/widgets/user_avatar.dart';

class _Pager implements OrdersApiService {
  final Future<PageResult<OrderModel>> Function(int, String?) fetch;
  _Pager(this.fetch);
  @override
  Future<PageResult<OrderModel>> getOrdersPage({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? paymentStatus,
    DateTime? fromDate,
    DateTime? toDate,
  }) => fetch(page, status);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ApiClient api;
  http.Response response(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
  OrderModel order(String id, [String state = 'PENDING']) =>
      OrderModel.fromJson({'orderId': id, 'orderStatus': state});
  PageResult<OrderModel> page(List<OrderModel> items, int page, bool more) =>
      PageResult(
        items: items,
        page: page,
        pageSize: 20,
        hasNextPage: more,
        totalItems: 3,
      );
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    api = ApiClient();
    await api.setTokens(accessToken: 'test-only');
    UserProfileService().reset();
  });
  tearDown(() async {
    api.testClient = http.Client();
    await api.clearTokens();
    UserProfileService().reset();
  });

  test('F08: stores follow canonical pagination when data is a list', () async {
    final seen = <String>[];
    api.testClient = MockClient((request) async {
      seen.add(request.url.queryParameters['page']!);
      expect(request.url.queryParameters['pageSize'], '100');
      final n = int.parse(seen.last);
      return response({
        'data': [
          {'storeId': '$n', 'name': 'Store $n'},
        ],
        'pagination': {
          'page': n,
          'pageSize': 100,
          'totalPages': 2,
          'hasNextPage': n < 2,
        },
      });
    });
    expect(
      (await StoresApiService().getStores()).map((row) => row['storeId']),
      ['1', '2'],
    );
    expect(seen, ['1', '2']);
  });

  test(
    'F08: products keep distinct IDs within the same store across pages',
    () async {
      api.testClient = MockClient((request) async {
        expect(request.url.queryParameters['storeId'], '7');
        final n = int.parse(request.url.queryParameters['page']!);
        return response({
          'data': [
            {'id': '$n', 'storeId': '7'},
          ],
          'pagination': {'page': n, 'totalPages': 2},
        });
      });
      expect(
        await ProductsApiService().getProducts(storeId: '7'),
        hasLength(2),
      );
    },
  );

  test(
    'F08: list parser supports legacy metadata and rejects a repeated page',
    () {
      final batch = PageResult<Map<String, dynamic>>.fromResponse(
        {
          'data': {
            'items': [
              {'id': '1'},
            ],
            'page': 1,
            'totalPages': 2,
          },
        },
        (row) => row,
        requestedPage: 1,
        pageSize: 20,
      );
      expect(batch.hasNextPage, isTrue);
      expect(
        () => PageResult<Map<String, dynamic>>.fromResponse(
          {
            'data': [],
            'pagination': {'page': 1, 'hasNextPage': true},
          },
          (row) => row,
          requestedPage: 2,
          pageSize: 20,
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'F08: devices fetch later pages instead of keeping only the first page',
    () async {
      final seen = <int>[];
      api.testClient = MockClient((request) async {
        if (request.url.path.endsWith('/products')) {
          return response({'data': []});
        }
        final n = int.parse(request.url.queryParameters['page']!);
        seen.add(n);
        return response({
          'data': [
            {'deviceId': 'ESP-$n', 'name': 'Button $n'},
          ],
          'pagination': {'page': n, 'totalPages': 2},
        });
      });
      expect((await DevicesApiService().getDevices()).map((d) => d.id), [
        'ESP-1',
        'ESP-2',
      ]);
      expect(seen, [1, 2]);
    },
  );

  testWidgets(
    'F08: an empty active tab can load further pages containing active orders',
    (tester) async {
      final provider = OrderProvider(
        apiService: _Pager(
          (n, _) async => n == 1
              ? page([order('1', 'COMPLETED')], 1, true)
              : page([order('2', 'PREPARING')], 2, false),
        ),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<OrderProvider>.value(
          value: provider,
          child: const MaterialApp(home: OrdersScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tải thêm đơn hàng'), findsOneWidget);
      await tester.tap(find.text('Tải thêm đơn hàng'));
      await tester.pumpAndSettle();
      expect(find.text('Đang chuẩn bị'), findsOneWidget);
      expect(provider.orders, hasLength(2));
      await tester.pumpWidget(const SizedBox());
      provider.dispose();
    },
  );

  test(
    'F08: paged orders send server filters and preserve pagination',
    () async {
      api.testClient = MockClient((request) async {
        if (request.url.path.endsWith('/products')) {
          return response({'data': []});
        }
        expect(request.url.queryParameters, containsPair('page', '2'));
        expect(
          request.url.queryParameters,
          containsPair('status', 'PREPARING'),
        );
        expect(
          request.url.queryParameters,
          containsPair('paymentStatus', 'PAID'),
        );
        expect(
          request.url.queryParameters['fromDate'],
          startsWith('2026-11-01'),
        );
        return response({
          'data': [
            {'orderId': '42'},
          ],
          'pagination': {
            'page': 2,
            'pageSize': 20,
            'totalItems': 21,
            'hasNextPage': false,
          },
        });
      });
      final result = await OrdersApiService().getOrdersPage(
        page: 2,
        status: 'PREPARING',
        paymentStatus: 'PAID',
        fromDate: DateTime.utc(2026, 11, 1),
      );
      expect(result.totalItems, 21);
      expect(result.hasNextPage, isFalse);
    },
  );

  test(
    'F08: load-more deduplicates, keeps old data on failure and retries the same page',
    () async {
      var fail = true;
      final calls = <int>[];
      final provider = OrderProvider(
        apiService: _Pager((n, _) async {
          calls.add(n);
          if (n == 1) return page([order('1')], 1, true);
          if (fail) throw Exception('offline');
          return page([order('1'), order('2')], 2, false);
        }),
      );
      await provider.loadOrders();
      await provider.loadMore();
      expect(provider.orders, hasLength(1));
      expect(provider.loadMoreError, isNotNull);
      fail = false;
      await provider.loadMore();
      expect(provider.orders.map((order) => order.id), ['1', '2']);
      expect(calls, [1, 2, 2]);
      provider.dispose();
    },
  );

  test('F08: old response cannot overwrite newly applied filters', () async {
    final old = Completer<PageResult<OrderModel>>();
    final provider = OrderProvider(
      apiService: _Pager(
        (n, status) => status == null
            ? old.future
            : Future.value(page([order('new', status)], 1, false)),
      ),
    );
    final pending = provider.loadOrders();
    await provider.setFilters(status: 'SHIPPING');
    old.complete(page([order('old')], 1, false));
    await pending;
    expect(provider.orders.single.id, 'new');
    provider.dispose();
  });

  testWidgets(
    'F09: FCM triggers a refetch instead of trusting the payload status',
    (tester) async {
      var state = 'PENDING';
      var requests = 0;
      final provider = OrderProvider(
        apiService: _Pager((n, _) async {
          requests++;
          return page([order('42', state)], 1, false);
        }),
      );
      provider.startLiveUpdates();
      await provider.loadOrders();
      state = 'PREPARING';
      await NotificationService().showLocalNotification(
        const RemoteMessage(
          data: {
            'type': 'ORDER_STATUS_CHANGED',
            'orderId': '42',
            'status': 'SHIPPING',
          },
        ),
      );
      expect(provider.orders.single.rawStatus, 'PENDING');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(provider.orders.single.rawStatus, 'PREPARING');
      expect(requests, 2);
      provider.dispose();
    },
  );

  testWidgets(
    'F09: detail displays real dated events and updates on relevant notifications',
    (tester) async {
      var state = 'PREPARING';
      var timelines = 0;
      api.testClient = MockClient((request) async {
        if (request.url.path.endsWith('/timeline')) {
          timelines++;
          return response({
            'data': {
              'timeline': [
                {
                  'id': 'event',
                  'type': 'STATUS_CHANGE',
                  'status': state,
                  'title': 'Store update',
                  'description': 'Cửa hàng đã nhận đơn',
                  'timestamp': '2026-11-04T03:00:00Z',
                },
              ],
            },
          });
        }
        return response({
          'data': {'orderId': '42', 'orderStatus': state},
        });
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: OrderDetailBottomSheet(order: order('42'))),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Lịch sử đơn hàng'), findsOneWidget);
      expect(find.text('Cửa hàng đã nhận đơn'), findsOneWidget);
      expect(find.textContaining('04/11/2026'), findsOneWidget);
      state = 'SHIPPING';
      OrderUpdates.notify('42');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Đang giao'), findsWidgets);
      expect(timelines, 2);
      await tester.pumpWidget(const SizedBox());
    },
  );

  test(
    'F09: logout clears live order state and discards an in-flight response',
    () async {
      final result = Completer<PageResult<OrderModel>>();
      final provider = OrderProvider(
        apiService: _Pager((_, _) => result.future),
      );
      provider.startLiveUpdates();
      final loading = provider.loadOrders();
      await api.clearTokens();
      await Future<void>.delayed(Duration.zero);
      result.complete(page([order('old-user-order')], 1, false));
      await loading;
      expect(provider.orders, isEmpty);
      expect(provider.isLoading, isFalse);
      provider.dispose();
    },
  );

  testWidgets('F09: timeline error is visible without inventing dated events', (
    tester,
  ) async {
    api.testClient = MockClient(
      (request) async => request.url.path.endsWith('/timeline')
          ? response({'message': 'offline'}, 500)
          : response({
              'data': {'orderId': '42', 'orderStatus': 'PENDING'},
            }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: OrderDetailBottomSheet(order: order('42'))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa tải được lịch sử đơn hàng.'), findsOneWidget);
    expect(find.text('Đã giao hàng'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  Future<File> imageFile() async {
    final dir = await Directory.systemTemp.createTemp('mobile-avatar-test-');
    final file = File('${dir.path}/avatar.png');
    await file.writeAsBytes(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aS1cAAAAASUVORK5CYII=',
      ),
    );
    addTearDown(() async {
      if (await file.exists()) await file.delete();
      await dir.delete();
    });
    return file;
  }

  test(
    'F11: upload followed by PATCH saves server URL and reloads on another provider',
    () async {
      final file = await imageFile();
      final calls = <String>[];
      api.testClient = MockClient((request) async {
        calls.add(request.method);
        if (request.url.path.endsWith('/media/upload')) {
          expect(
            request.headers['content-type'],
            contains('multipart/form-data'),
          );
          return response({
            'data': {'secureUrl': 'https://example.com/avatar.png'},
          });
        }
        if (request.method == 'PATCH') {
          expect(jsonDecode(request.body), {
            'avatarUrl': 'https://example.com/avatar.png',
          });
        }
        return response({
          'data': {'avatarUrl': 'https://example.com/avatar.png'},
        });
      });
      final provider = UserProvider();
      await provider.updateAvatar(file);
      expect(provider.avatarUrl, 'https://example.com/avatar.png');
      expect(provider.avatarFile, isNull);
      provider.reset();
      final other = UserProvider();
      await other.loadProfile();
      expect(other.avatarUrl, 'https://example.com/avatar.png');
      expect(calls, ['POST', 'PATCH', 'GET']);
      provider.dispose();
      other.dispose();
    },
  );

  test(
    'F11: denied upload preserves old avatar and never PATCHes a fake success',
    () async {
      final file = await imageFile();
      var requests = 0;
      UserProfileService().updateAvatarUrl('https://example.com/old.png');
      api.testClient = MockClient((request) async {
        requests++;
        expect(request.method, 'POST');
        return response({'message': 'Forbidden'}, 403);
      });
      final provider = UserProvider();
      await expectLater(
        provider.updateAvatar(file),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 403)),
      );
      expect(provider.avatarUrl, 'https://example.com/old.png');
      expect(requests, 1);
      expect(provider.savingAvatar, isFalse);
      provider.dispose();
    },
  );

  test('F11: URL save failure preserves the current server avatar', () async {
    final file = await imageFile();
    UserProfileService().updateAvatarUrl('https://example.com/old.png');
    api.testClient = MockClient(
      (request) async => request.method == 'POST'
          ? response({
              'data': {'secureUrl': 'https://example.com/new.png'},
            })
          : response({'message': 'Save rejected'}, 400),
    );
    final provider = UserProvider();
    await expectLater(
      provider.updateAvatar(file),
      throwsA(isA<ApiException>()),
    );
    expect(provider.avatarUrl, 'https://example.com/old.png');
    provider.dispose();
  });

  test(
    'F11: logout while uploading prevents stale avatar from entering another session',
    () async {
      final file = await imageFile();
      final started = Completer<void>();
      final done = Completer<http.Response>();
      api.testClient = MockClient((request) {
        expect(request.method, 'POST');
        started.complete();
        return done.future;
      });
      final provider = UserProvider();
      final uploading = provider.updateAvatar(file);
      await started.future;
      provider.reset();
      done.complete(
        response({
          'data': {'secureUrl': 'https://example.com/old-user.png'},
        }),
      );
      await uploading;
      expect(provider.avatarUrl, isNull);
      provider.dispose();
    },
  );

  testWidgets(
    'F11: invalid image URL renders initials without a local-file dependency',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(initials: 'AB', url: 'file:///private/avatar.png'),
          ),
        ),
      );
      expect(find.text('AB'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    },
  );
}
