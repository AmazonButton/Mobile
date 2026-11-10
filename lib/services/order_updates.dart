import 'dart:async';

/// Notifications invalidate cached state; the API supplies the authoritative order.
abstract final class OrderUpdates {
  static final _controller = StreamController<String?>.broadcast();
  static final _sessionEnds = StreamController<void>.broadcast();
  static Stream<String?> get events => _controller.stream;
  static Stream<void> get sessionEnds => _sessionEnds.stream;
  static void notify([String? orderId]) => _controller.add(orderId);
  static void endSession() => _sessionEnds.add(null);
}
