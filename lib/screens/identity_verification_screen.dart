import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/resident_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/identity_verification.dart';
import '../services/identity_verification_service.dart';
import '../services/api_client.dart';

class IdentityVerificationScreen extends StatefulWidget {
  final IdentityVerificationService? service;
  final Future<bool> Function(Uri)? openUrl;
  const IdentityVerificationScreen({super.key, this.service, this.openUrl});
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

  @override
  Widget build(BuildContext context) {
    final current = _current;
    final approved = _sessions.any((s) => s.approved);
    return ResidentScaffold(
      appBar: AppBar(title: const Text('Xác minh danh tính')),
      actions: [
        if (!_loading && !_listReady)
          TextButton(
            onPressed: _busy ? null : () => _load(),
            child: const Text('Thử lại'),
          ),
        if (!_loading && _listReady) ...[
          if (!approved && current?.canContinue == true)
            FilledButton(
              onPressed: _busy ? null : _continue,
              child: const Text('Tiếp tục xác minh'),
            ),
          if (!approved &&
              (current == null || current.terminal || current.expired))
            FilledButton(
              onPressed: _busy ? null : _start,
              child: Text(
                current == null ? 'Bắt đầu xác minh' : 'Tạo phiên xác minh mới',
              ),
            ),
          OutlinedButton(
            onPressed: _busy
                ? null
                : () {
                    _pollUntil = DateTime.now().add(const Duration(minutes: 5));
                    _refreshCurrent(
                      decision: current != null && !current.terminal,
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
            ResidentHero(
              icon: Icons.verified_user_outlined,
              eyebrow: 'Bảo mật tài khoản',
              title: approved
                  ? 'Đã xác minh danh tính'
                  : current?.label ?? 'Chưa xác minh danh tính',
              description: approved
                  ? 'Kết quả đã được hệ thống xác nhận.'
                  : 'Chuẩn bị giấy tờ tùy thân để tiếp tục với Didit.',
            ),
            if (!approved)
              const ResidentPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quy trình xác minh',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text('1. Chuẩn bị giấy tờ tùy thân'),
                    SizedBox(height: 8),
                    Text('2. Làm theo hướng dẫn của Didit'),
                    SizedBox(height: 8),
                    Text('3. Quay lại ứng dụng để xem kết quả'),
                  ],
                ),
              ),
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
