import 'sample_a.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TourStep {
  intro(
    'Làm quen với SmartOrder',
    'Cùng thêm nút, khám phá cửa hàng và theo dõi đơn hàng của bạn.',
    0,
  ),
  add(
    'Thêm thiết bị',
    'Chạm vào Thêm thiết bị để kết nối thiết bị SmartOrder của bạn.',
    1,
  ),
  code(
    'Nhập mã kết nối',
    'Nhập mã trên thiết bị. Bạn có thể đi tiếp nếu chưa có nút.',
    1,
  ),
  connect(
    'Kết nối thiết bị',
    'Chạm Kết nối để kiểm tra mã. Nếu có lỗi, bạn có thể sửa mã và thử lại.',
    1,
  ),
  connected(
    'Đã kết nối nút thành công',
    'Bạn có thể xem nút của mình trong tab Thiết bị.',
    1,
  ),
  stores(
    'Khám phá cửa hàng',
    'Chạm vào cửa hàng để xem sản phẩm. Chưa có thao tác mua hàng ở bước này.',
    2,
  ),
  catalog(
    'Sản phẩm của cửa hàng',
    'Bạn có thể tìm sản phẩm và gán vào nút của cùng cửa hàng. Hướng dẫn dừng ở bước xem; Tiếp tục để tìm hiểu đơn hàng.',
    2,
  ),
  orders(
    'Theo dõi đơn hàng',
    'Xem Đang xử lý hoặc Lịch sử. Mở chi tiết để xem tiến trình; thanh toán chỉ bắt đầu khi bạn chủ động chọn.',
    3,
  ),
  addresses(
    'Địa chỉ giao hàng',
    'Chạm để xem nơi nhận hàng và địa chỉ mặc định của bạn.',
    4,
  ),
  addressAdd(
    'Thêm địa chỉ',
    'Chạm Thêm địa chỉ để nhập nơi nhận hàng. Chỉ lưu khi bạn tự xác nhận trong biểu mẫu.',
    4,
  ),
  deposit('Nút và tiền cọc', 'Chạm để mở hồ sơ nhận nút và xem tiền cọc.', 5),
  amount(
    'Tiền cọc theo hồ sơ',
    'Xem số tiền cọc và trạng thái hồ sơ nhận nút tại đây.',
    5,
  ),
  refund(
    'Tài khoản nhận hoàn cọc',
    'Mục này quản lý tài khoản ngân hàng dùng để nhận hoàn cọc.',
    5,
  ),
  bank(
    'Tài khoản hoàn cọc',
    'Chạm để xem tài khoản nhận hoàn cọc và trạng thái xác minh.',
    6,
  ),
  bankInfo(
    'Nhận hoàn cọc an toàn',
    'Thêm tài khoản nếu chưa có. Xác minh chỉ bắt đầu khi bạn chủ động chọn; hướng dẫn không tự tạo thanh toán.',
    6,
  ),
  identity(
    'Xác minh CCCD',
    'Chạm Xác minh danh tính để xem trạng thái và các bước xác minh.',
    7,
  ),
  identityAction(
    'Thao tác xác minh',
    'Bạn có thể dùng nút được làm sáng để bắt đầu, tiếp tục hoặc kiểm tra kết quả xác minh.',
    7,
  );

  const TourStep(this.title, this.message, this.chapter);
  final String title;
  final String message;
  final int chapter;
}

class SmartOrderTour with WidgetsBindingObserver {
  SmartOrderTour({required this.context, required this.changeTab}) {
    WidgetsBinding.instance.addObserver(this);
  }

  final BuildContext context;
  final ValueChanged<int> changeTab;
  final Map<TourStep, GlobalKey> _keys = {};
  GlobalKey key(TourStep step) => _keys.putIfAbsent(step, GlobalKey.new);

  TourStep? _step;
  OverlayEntry? _entry;
  Timer? _timer;
  ModalRoute<dynamic>? _guidedRoute;
  String? _account;
  int _session = 0;
  bool _disposed = false;
  bool _paused = false;
  bool _busy = false;
  Size? _scrollViewport;
  DateTime _deadline = DateTime.now();
  Rect? _rect;
  bool _fallback = false;

  bool isAt(TourStep step) => _step == step;

  Future<void> accountChanged(String? account) async {
    if (_disposed || _account == account) return;
    _account = account;
    final session = ++_session;
    _close();
    if (account == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!_disposed &&
          session == _session &&
          _step == null &&
          !prefs.containsKey('smartorder.spotlight.v1.$account')) {
        replay();
      }
    } catch (_) {
      // Keep normal navigation available if local storage fails.
    }
  }

  void replay() {
    _close();
    changeTab(0);
    _go(TourStep.intro);
  }

  void dismiss() => _close();

  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _paused = state != AppLifecycleState.resumed;
    if (_paused) {
      _removeOverlay();
    } else {
      _deadline = DateTime.now().add(const Duration(seconds: 2));
      _update();
    }
  }

  void _close() {
    _timer?.cancel();
    _timer = null;
    _step = null;
    _guidedRoute = null;
    _busy = false;
    _removeOverlay();
  }

  void _removeOverlay() {
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
  }

  Future<void> _finish(bool skipped) async {
    final account = _account;
    _close();
    if (account == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'smartorder.spotlight.v1.$account',
        skipped ? 'skipped' : 'completed',
      );
    } catch (_) {
      // The overlay is already closed.
    }
  }

  void _go(TourStep step) {
    _removeOverlay();
    _step = step;
    _busy = false;
    _scrollViewport = null;
    _fallback = false;
    _rect = null;
    _deadline = DateTime.now().add(const Duration(seconds: 2));
    _timer ??= Timer.periodic(
      const Duration(milliseconds: 80),
      (_) => _update(),
    );
  }

  void trackRoute(BuildContext context, TourStep step) {
    if (isAt(step)) _guidedRoute = ModalRoute.of(context);
  }

  void openConnect() {
    if (isAt(TourStep.add)) _go(TourStep.code);
  }

  void codeChanged(String code) {
    if (isAt(TourStep.code) && code.trim().isNotEmpty) _go(TourStep.connect);
    if (isAt(TourStep.connect) && code.trim().isEmpty) _go(TourStep.code);
  }

  void setBusy(bool busy) {
    if (!isAt(TourStep.connect) && !isAt(TourStep.identityAction)) return;
    _busy = busy;
    if (busy) _removeOverlay();
    if (!busy) _deadline = DateTime.now().add(const Duration(seconds: 2));
  }

  void connectClosed(bool success) {
    if (!isAt(TourStep.code) && !isAt(TourStep.connect)) return;
    _guidedRoute = null;
    _go(success ? TourStep.connected : TourStep.add);
  }

  void openCatalog() {
    if (isAt(TourStep.stores)) _go(TourStep.catalog);
  }

  void catalogClosed() {
    if (!isAt(TourStep.catalog)) return;
    _guidedRoute = null;
    changeTab(2);
    _go(TourStep.orders);
  }

  void openAddresses() {
    if (isAt(TourStep.addresses)) _go(TourStep.addressAdd);
  }

  void addressesClosed() {
    if (!isAt(TourStep.addressAdd)) return;
    _guidedRoute = null;
    _go(TourStep.deposit);
  }

  void openBank() {
    if (isAt(TourStep.bank)) _go(TourStep.bankInfo);
  }

  void bankClosed() {
    if (!isAt(TourStep.bankInfo)) return;
    _guidedRoute = null;
    _go(TourStep.identity);
  }

  void openDeposit() {
    if (isAt(TourStep.deposit)) _go(TourStep.amount);
  }

  void depositClosed() {
    if (!isAt(TourStep.amount) && !isAt(TourStep.refund)) return;
    _guidedRoute = null;
    _go(TourStep.bank);
  }

  void refundViewed() {
    if (isAt(TourStep.refund)) {
      _leaveGuidedRoute();
      _go(TourStep.bank);
    }
  }

  void openIdentity() {
    if (isAt(TourStep.identity)) _go(TourStep.identityAction);
  }

  void identityClosed() {
    if (isAt(TourStep.identityAction)) _finish(false);
  }

  void _next() {
    switch (_step) {
      case TourStep.intro:
        changeTab(1);
        _go(TourStep.add);
      case TourStep.add:
      case TourStep.code:
      case TourStep.connect:
      case TourStep.connected:
        _leaveGuidedRoute();
        changeTab(0);
        _go(TourStep.stores);
      case TourStep.stores:
      case TourStep.catalog:
        _leaveGuidedRoute();
        changeTab(2);
        _go(TourStep.orders);
      case TourStep.orders:
        changeTab(3);
        _go(TourStep.addresses);
      case TourStep.addresses:
      case TourStep.addressAdd:
        _leaveGuidedRoute();
        _go(TourStep.deposit);
      case TourStep.amount:
        _go(TourStep.refund);
      case TourStep.deposit:
      case TourStep.refund:
        _leaveGuidedRoute();
        _go(TourStep.bank);
      case TourStep.bank:
      case TourStep.bankInfo:
        _leaveGuidedRoute();
        _go(TourStep.identity);
      case TourStep.identity:
      case TourStep.identityAction:
        _finish(false);
      case null:
        break;
    }
  }

  void _leaveGuidedRoute() {
    final route = _guidedRoute;
    _guidedRoute = null;
    if (route?.isCurrent == true) route!.navigator!.pop();
  }

  void _update() {
    final step = _step;
    if (_disposed || step == null || _paused || _busy || !context.mounted) {
      return;
    }
    final overlay = Navigator.of(context).overlay;
    final box = overlay?.context.findRenderObject();
    if (overlay == null || box is! RenderBox || !box.hasSize) return;
    final target = _keys[step]?.currentContext;
    final shell = ModalRoute.of(context);
    final centered = step == TourStep.intro || step == TourStep.connected;
    final insideRoute = {
      TourStep.code,
      TourStep.connect,
      TourStep.amount,
      TourStep.refund,
      TourStep.identityAction,
      TourStep.catalog,
      TourStep.addressAdd,
      TourStep.bankInfo,
    }.contains(step);
    if ((!insideRoute && shell?.isCurrent != true) ||
        (target != null && ModalRoute.of(target)?.isCurrent != true) ||
        (_guidedRoute != null && !_guidedRoute!.isCurrent)) {
      _removeOverlay();
      return;
    }

    Rect? rect;
    if (target != null) {
      final route = ModalRoute.of(target);
      if (insideRoute && route != shell) _guidedRoute = route;
      final render = target.findRenderObject();
      if (render is RenderBox && render.attached && render.hasSize) {
        final origin = render.localToGlobal(Offset.zero, ancestor: box);
        final candidate = origin & render.size;
        final media = MediaQueryData.fromView(View.of(context));
        final visible = Rect.fromLTRB(
          0,
          media.padding.top,
          box.size.width,
          box.size.height -
              (media.viewInsets.bottom > 0
                  ? media.viewInsets.bottom
                  : media.padding.bottom),
        );
        // Scroll even if the target is geometrically visible but clipped by
        // the page's scroll viewport (for example by fixed bottom actions).
        if (_scrollViewport != visible.size &&
            Scrollable.maybeOf(target) != null) {
          _scrollViewport = visible.size;
          Scrollable.ensureVisible(target, alignment: .45);
        }
        final panelSpace =
            candidate.top - visible.top > 100 ||
            visible.bottom - candidate.bottom > 100;
        if (panelSpace &&
            visible.contains(candidate.topLeft) &&
            candidate.right <= visible.right &&
            candidate.bottom <= visible.bottom) {
          rect = candidate;
        }
      }
    }
    final fallback = !centered && rect == null;
    if (fallback && DateTime.now().isBefore(_deadline)) {
      _removeOverlay();
      return;
    }
    if (_entry == null) {
      _rect = rect;
      _fallback = fallback;
      _entry = OverlayEntry(
        builder: (context) => _Spotlight(
          key: ValueKey(_step),
          step: _step!,
          rect: _rect,
          fallback: _fallback,
          onSkip: () => _finish(true),
          onNext: _next,
        ),
      );
      overlay.insert(_entry!);
    } else if (rect != _rect || fallback != _fallback) {
      _rect = rect;
      _fallback = fallback;
      _entry!.markNeedsBuild();
    }
  }
}

class _Spotlight extends StatelessWidget {
  const _Spotlight({
    super.key,
    required this.step,
    required this.rect,
    required this.fallback,
    required this.onSkip,
    required this.onNext,
  });

  final TourStep step;
  final Rect? rect;
  final bool fallback;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final motion = !media.disableAnimations;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final hole = rect;
        final top = media.padding.top + 12;
        final bottom =
            height -
            (media.viewInsets.bottom > 0
                ? media.viewInsets.bottom
                : media.padding.bottom) -
            12 -
            ({
                  TourStep.add,
                  TourStep.stores,
                  TourStep.orders,
                  TourStep.addresses,
                  TourStep.bank,
                  TourStep.deposit,
                  TourStep.identity,
                }.contains(step)
                ? 72
                : 0);
        final above = hole == null ? 0.0 : hole.top - top - 12;
        final below = hole == null ? 0.0 : bottom - hole.bottom - 12;
        final putBelow = below >= 190 || below >= above;
        final panelTop = hole != null && putBelow ? hole.bottom + 12 : top;
        final panelBottom = hole != null && !putBelow ? hole.top - 12 : bottom;
        final panelHeight = (panelBottom - panelTop).clamp(0.0, height);
        final showPanel = panelHeight >= 44;

        Widget blocker(Rect area) => Positioned.fromRect(
          rect: area,
          child: const Listener(
            behavior: HitTestBehavior.opaque,
            child: SizedBox.expand(),
          ),
        );

        return Stack(
          children: [
            if (!fallback) ...[
              Positioned.fill(
                child: IgnorePointer(child: CustomPaint(painter: _Shade(hole))),
              ),
              if (hole == null)
                blocker(Offset.zero & Size(width, height))
              else ...[
                blocker(Rect.fromLTRB(0, 0, width, hole.top)),
                blocker(Rect.fromLTRB(0, hole.bottom, width, height)),
                blocker(Rect.fromLTRB(0, hole.top, hole.left, hole.bottom)),
                blocker(
                  Rect.fromLTRB(hole.right, hole.top, width, hole.bottom),
                ),
                Positioned(
                  left: (hole.right - 32).clamp(
                    0.0,
                    (width - 32).clamp(0.0, width),
                  ),
                  top: (hole.center.dy - 10).clamp(
                    0.0,
                    (height - 32).clamp(0.0, height),
                  ),
                  child: IgnorePointer(
                    child: ExcludeSemantics(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: .6, end: 1),
                        duration: motion
                            ? const Duration(milliseconds: 650)
                            : Duration.zero,
                        curve: Curves.easeOutBack,
                        builder: (_, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: const Icon(
                          Icons.touch_app,
                          color: SampleA.primary,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
            if (showPanel)
              Positioned(
                left: 16,
                right: 16,
                top: panelTop,
                height: panelHeight,
                child: Align(
                  alignment: hole == null
                      ? Alignment.center
                      : putBelow
                      ? Alignment.topCenter
                      : Alignment.bottomCenter,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: motion
                        ? const Duration(milliseconds: 180)
                        : Duration.zero,
                    builder: (_, opacity, child) =>
                        Opacity(opacity: opacity, child: child),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Material(
                        elevation: 8,
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        clipBehavior: Clip.antiAlias,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(14),
                          child: Semantics(
                            liveRegion: true,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (step.chapter > 0)
                                  Text(
                                    'Chặng ${step.chapter}/7 · Bước ${TourStep.values.where((s) => s.chapter == step.chapter).toList().indexOf(step) + 1}/${TourStep.values.where((s) => s.chapter == step.chapter).length}',
                                  ),
                                Text(
                                  step.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  fallback
                                      ? 'Chưa thấy mục cần hướng dẫn. Bạn có thể tiếp tục hoặc bỏ qua.'
                                      : step.message,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    TextButton(
                                      onPressed: onSkip,
                                      child: const Text('Bỏ qua'),
                                    ),
                                    FilledButton(
                                      onPressed: onNext,
                                      child: const Text('Tiếp tục'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Shade extends CustomPainter {
  const _Shade(this.hole);
  final Rect? hole;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    final target = hole;
    if (target != null) {
      path.addRRect(
        RRect.fromRectAndRadius(target.inflate(3), const Radius.circular(10)),
      );
    }
    canvas.drawPath(path, Paint()..color = const Color(0xAA101828));
    if (target != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(target.inflate(3), const Radius.circular(10)),
        Paint()
          ..color = const Color(0xFF93C5FD)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_Shade oldDelegate) => oldDelegate.hole != hole;
}
