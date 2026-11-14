import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/smart_order_tour.dart';
import '../widgets/resident_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/identity_verification.dart';
import '../services/identity_verification_service.dart';
import '../services/api_client.dart';

class IdentityVerificationScreen extends StatefulWidget {
  final IdentityVerificationService? service;
  final Future<bool> Function(Uri)? openUrl;
  const IdentityVerificationScreen({
    super.key,
    this.service,
    this.openUrl,
    this.tour,
  });
  final SmartOrderTour? tour;
  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends State<IdentityVerificationScreen>
    with WidgetsBindingObserver {
  late final _api = widget.service ?? IdentityVerificationService();
  List<IdentityVerification> _sessions = [];
  bool _listReady = false, _confirming = false;
  bool _loading = true, _busy = false, _more = false, _paused = false;
  int _page = 0;
  String? _error;
  Timer? _timer;
  DateTime? _pollUntil;
  IdentityVerification? get _current =>
      _sessions.isEmpty ? null : _sessions.first;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _paused = state != AppLifecycleState.resumed;
    _timer?.cancel();
    if (!_paused) {
      _refreshCurrent();
    }
  }

  String _message(Object error) => error is ApiException
      ? error.message
      : 'Không thể tải thông tin xác minh. Vui lòng thử lại.';

  void _schedule() {
    _timer?.cancel();
    final session = _current;
    if (_paused ||
        session == null ||
        session.terminal ||
        session.expired ||
        _pollUntil == null ||
        !DateTime.now().isBefore(_pollUntil!)) {
      return;
    }
    _timer = Timer(const Duration(seconds: 10), () => _refreshCurrent());
  }

  Future<void> _load({bool more = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final batch = await _api.list(page: more ? _page + 1 : 1);
      if (!mounted) return;
      setState(() {
        final all = {
          if (more)
            for (final s in _sessions) s.id: s,
          for (final s in batch.items) s.id: s,
        };
        _sessions = all.values.toList()
          ..sort((a, b) => BigInt.parse(b.id).compareTo(BigInt.parse(a.id)));
        _page = batch.page;
        _more = batch.hasNextPage;
        _listReady = true;
      });
      _pollUntil ??= DateTime.now().add(const Duration(minutes: 5));
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _busy = false;
        });
        _schedule();
      }
    }
  }

  void _replace(IdentityVerification session) {
    setState(() {
      _sessions = [session, ..._sessions.where((s) => s.id != session.id)]
        ..sort((a, b) => BigInt.parse(b.id).compareTo(BigInt.parse(a.id)));
    });
  }

  Future<void> _refreshCurrent({bool decision = false}) async {
    final current = _current;
    if (_busy) {
      _schedule();
      return;
    }
    if (current == null) {
      await _load();
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = decision
          ? await _api.checkDecision(current.id)
          : await _api.get(current.id);
      if (mounted) _replace(session);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _schedule();
      }
    }
  }

  Future<void> _open(IdentityVerification session) async {
    final uri = session.launchUri;
    if (!session.canContinue || uri == null) {
      if (mounted) {
        setState(
          () => _error =
              'Liên kết xác minh không khả dụng hoặc phiên đã kết thúc. Vui lòng kiểm tra lại trạng thái.',
        );
      }
      return;
    }
    final opened =
        await (widget.openUrl?.call(uri) ??
            launchUrl(uri, mode: LaunchMode.externalApplication));
    if (!opened) throw StateError('Không mở được trình duyệt');
    // Browser completion is never treated as approval.
    _pollUntil = DateTime.now().add(const Duration(minutes: 5));
  }

  Future<void> _continue() async {
    if (_busy || _current == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _open(_current!);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Không mở được trang xác minh. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _schedule();
      }
    }
  }

  Future<void> _start() async {
    if (_busy || _confirming || !_listReady) return;
    _confirming = true;
    final consent = await showResidentConfirmation(
      context,
      title: 'Xác minh danh tính',
      message:
          'Bạn sẽ chuyển sang Didit để cung cấp giấy tờ tùy thân và xác minh khuôn mặt. Hãy đọc thông tin xử lý dữ liệu trên trang Didit trước khi tiếp tục. Ứng dụng không lưu ảnh giấy tờ vào bộ nhớ máy.',
      confirmLabel: 'Tiếp tục với Didit',
      cancelLabel: 'Để sau',
    );
    _confirming = false;
    if (!mounted || consent != true || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await _api.create();
      if (!mounted) return;
      _replace(session);
      _pollUntil = DateTime.now().add(const Duration(minutes: 5));
      if (session.canContinue) await _open(session);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Không thể mở phiên xác minh. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _schedule();
      }
    }
  }

  Future<void> _guidedAction(Future<void> Function() action) async {
    widget.tour?.setBusy(true);
    try {
      await action();
    } finally {
      widget.tour?.setBusy(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    widget.tour?.trackRoute(context, TourStep.identityAction);
    final current = _current;
    final approved = _sessions.any((s) => s.approved);
    final canContinue = !approved && current?.canContinue == true;
    final canStart =
        !approved && (current == null || current.terminal || current.expired);
    final guideKey = widget.tour?.key(TourStep.identityAction);
    return ResidentScaffold(
      appBar: AppBar(title: const Text('Xác minh danh tính')),
      actions: [
        if (!_loading && !_listReady)
          TextButton(
            onPressed: _busy ? null : () => _load(),
            child: const Text('Thử lại'),
          ),
        if (!_loading && _listReady) ...[
          if (canContinue)
            FilledButton(
              key: guideKey,
              onPressed: _busy ? null : () => _guidedAction(_continue),
              child: const Text('Tiếp tục xác minh'),
            ),
          if (canStart)
            FilledButton(
              key: canContinue ? null : guideKey,
              onPressed: _busy ? null : () => _guidedAction(_start),
              child: Text(
                current == null ? 'Bắt đầu xác minh' : 'Tạo phiên xác minh mới',
              ),
            ),
          OutlinedButton(
            key: !canContinue && !canStart ? guideKey : null,
            onPressed: _busy
                ? null
                : () {
                    _pollUntil = DateTime.now().add(const Duration(minutes: 5));
                    _guidedAction(
                      () => _refreshCurrent(
                        decision: current != null && !current.terminal,
                      ),
                    );
                  },
            child: const Text('Kiểm tra trạng thái'),
          ),
        ],
      ],
      body: RefreshIndicator(
        onRefresh: () => _load(),
        child: ListView(
          padding: const EdgeInsets.all(24),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Center(
              child: Container(
                width: 112,
                height: 112,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE6F0FF),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  size: 64,
                  color: residentBlue,
                ),
              ),
            ),
            Text(
              approved ? 'Đã xác minh danh tính' : 'Xác minh tài khoản của bạn',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Center(
              child: ResidentBadge(
                approved
                    ? 'Đã xác minh'
                    : _loading
                    ? 'Đang tải trạng thái'
                    : !_listReady
                    ? 'Chưa tải được trạng thái'
                    : current?.label ?? 'Chưa xác minh',
                success: approved,
                waiting: !approved,
              ),
            ),
            const SizedBox(height: 22),
            if (!approved) ...[
              const ResidentPanel(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.badge_outlined),
                      title: Text('Chuẩn bị giấy tờ tùy thân'),
                    ),
                    Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.light_mode_outlined),
                      title: Text('Chọn nơi đủ ánh sáng'),
                    ),
                    Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.format_list_bulleted),
                      title: Text('Làm theo hướng dẫn trên Didit'),
                    ),
                  ],
                ),
              ),
              const ResidentNotice(
                'Bạn sẽ chuyển sang Didit để thực hiện xác minh.',
              ),
            ],
            if (_loading || _busy)
              const Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(),
              ),
            if (_error != null) ResidentNotice(_error!, error: true),
            if (!_loading && _listReady) ...[
              const SizedBox(height: 24),
              const Text(
                'Lịch sử xác minh',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_sessions.isEmpty)
                const ResidentPanel(child: Text('Chưa có lịch sử xác minh.')),
              for (final session in _sessions)
                ResidentPanel(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const ResidentIcon(Icons.history),
                    title: Text(session.label),
                    subtitle: Text(
                      'Phiên #${session.id}${session.createdAt == null ? '' : ' · ${MaterialLocalizations.of(context).formatMediumDate(session.createdAt!.toLocal())}'}',
                    ),
                  ),
                ),
              if (_more)
                TextButton(
                  onPressed: _busy ? null : () => _load(more: true),
                  child: const Text('Tải thêm lịch sử'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
