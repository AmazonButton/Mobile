import '../widgets/smart_order_tour.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/resident_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/customer_bank_account.dart';
import '../services/customer_bank_api_service.dart';
import '../services/api_client.dart';
import '../utils/formatters.dart';

String _bankError(Object error) => error is ApiException
    ? error.message
    : 'Không thể tải thông tin ngân hàng. Vui lòng thử lại.';

class CustomerBankAccountsScreen extends StatefulWidget {
  final CustomerBankApiService? service;
  const CustomerBankAccountsScreen({super.key, this.service, this.tour});
  final SmartOrderTour? tour;
  @override
  State<CustomerBankAccountsScreen> createState() =>
      _CustomerBankAccountsScreenState();
}

class _CustomerBankAccountsScreenState
    extends State<CustomerBankAccountsScreen> {
  late final _api = widget.service ?? CustomerBankApiService();
  late Future<List<CustomerBankAccount>> _accounts;
  @override
  void initState() {
    super.initState();
    _accounts = _api.getAccounts();
  }

  Future<void> _reload() async {
    final next = _api.getAccounts();
    setState(() {
      _accounts = next;
    });
    try {
      await next;
    } catch (_) {
      /* FutureBuilder owns the error. */
    }
  }

  Future<void> _add() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Theme(
        data: residentTheme(context),
        child: _AddBankAccountSheet(api: _api),
      ),
    );
    if (mounted && saved == true) await _reload();
  }

  Future<void> _verify(CustomerBankAccount account) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CustomerBankVerificationScreen(
          account: account,
          service: _api,
          initiate: !account.isVerified,
        ),
      ),
    );
    if (mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    widget.tour?.trackRoute(context, TourStep.bankInfo);
    return ResidentScaffold(
      appBar: AppBar(
        title: const Text('Tài khoản hoàn cọc'),
        actions: [
          IconButton(
            tooltip: 'Lịch sử xác minh',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => _BankHistoryScreen(api: _api),
              ),
            ),
          ),
        ],
      ),
      actions: [
        FilledButton.icon(
          onPressed: _add,
          icon: const Icon(Icons.add),
          label: const Text('Thêm tài khoản'),
        ),
      ],
      body: FutureBuilder<List<CustomerBankAccount>>(
        future: _accounts,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_bankError(snapshot.error!)),
                  TextButton(onPressed: _reload, child: const Text('Thử lại')),
                ],
              ),
            );
          }
          final accounts = snapshot.data ?? [];
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    'Nhận lại tiền cọc khi hoàn tất thủ tục trả nút.',
                    key: widget.tour?.key(TourStep.bankInfo),
                    style: const TextStyle(fontSize: 16, color: residentMuted),
                  ),
                ),
                if (accounts.isEmpty)
                  const ResidentPanel(
                    child: Text('Bạn chưa đăng ký tài khoản nhận hoàn cọc.'),
                  ),
                for (final account in accounts)
                  ResidentPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const ResidentIcon(
                            Icons.account_balance_outlined,
                          ),
                          title: Text(
                            account.bankName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(account.maskedNumber),
                              Text(account.accountName),
                            ],
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (account.isDefault)
                              const ResidentBadge('Tài khoản mặc định'),
                            ResidentBadge(
                              account.isVerified
                                  ? 'Đã xác minh chính chủ'
                                  : 'Chưa xác minh chính chủ',
                              success: account.isVerified,
                              waiting: !account.isVerified,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (!account.isVerified)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F0FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Xác minh tài khoản ngân hàng',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  spacing: 12,
                                  runSpacing: 6,
                                  children: [
                                    Text('Số tiền xác minh'),
                                    Text(
                                      '2.000đ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Hoàn tất bước xác minh để kiểm tra tài khoản nhận hoàn cọc.',
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: () => _verify(account),
                                  child: const Text('Xác minh tài khoản'),
                                ),
                              ],
                            ),
                          ),
                        if (account.isVerified)
                          TextButton(
                            onPressed: () => _verify(account),
                            child: Text(
                              account.isVerified
                                  ? 'Xem trạng thái xác minh'
                                  : 'Xác minh tài khoản',
                            ),
                          ),
                      ],
                    ),
                  ),
                ResidentPanel(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history),
                    title: const Text('Lịch sử xác minh'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => _BankHistoryScreen(api: _api),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AddBankAccountSheet extends StatefulWidget {
  final CustomerBankApiService api;
  const _AddBankAccountSheet({required this.api});
  @override
  State<_AddBankAccountSheet> createState() => _AddBankAccountSheetState();
}

class _AddBankAccountSheetState extends State<_AddBankAccountSheet> {
  final _form = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _name = TextEditingController();
  late Future<List<Map<String, dynamic>>> _banks;
  Map<String, dynamic>? _bank;
  bool _saving = false;
  bool _default = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _banks = widget.api.getBanks();
  }

  @override
  void dispose() {
    _number.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.addAccount(
        bankBin: _bank!['bin'].toString(),
        bankName: _bank!['name'].toString(),
        accountNumber: _number.text.trim(),
        accountName: _name.text,
        isDefault: _default,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _error = _bankError(error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ResidentHero(
                icon: Icons.account_balance_outlined,
                eyebrow: 'Hoàn cọc',
                title: 'Thêm tài khoản hoàn cọc',
                description: 'Nhập thông tin tài khoản ngân hàng chính chủ.',
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _banks,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return TextButton(
                      onPressed: () => setState(() {
                        _banks = widget.api.getBanks();
                      }),
                      child: const Text('Tải lại danh sách ngân hàng'),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const LinearProgressIndicator();
                  }
                  return DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Ngân hàng'),
                    items: [
                      for (final bank in snapshot.data!)
                        DropdownMenuItem(
                          value: bank['bin'].toString(),
                          child: Text(
                            bank['shortName']?.toString() ??
                                bank['name'].toString(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: _saving
                        ? null
                        : (bin) => setState(
                            () => _bank = snapshot.data!.firstWhere(
                              (bank) => bank['bin'].toString() == bin,
                            ),
                          ),
                    validator: (_) =>
                        _bank == null ? 'Vui lòng chọn ngân hàng' : null,
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('bank-number'),
                controller: _number,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Số tài khoản'),
                validator: (value) =>
                    RegExp(r'^\d{6,20}$').hasMatch(value?.trim() ?? '')
                    ? null
                    : 'Số tài khoản phải gồm 6 đến 20 chữ số',
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('bank-name'),
                controller: _name,
                enabled: !_saving,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Tên chủ tài khoản',
                  helperText: 'Nhập tên chính chủ, viết hoa không dấu',
                ),
                validator: (value) => value?.trim().isNotEmpty == true
                    ? null
                    : 'Vui lòng nhập tên chủ tài khoản',
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dùng làm tài khoản nhận hoàn cọc mặc định'),
                value: _default,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _default = value ?? true),
              ),
              if (_error != null) ResidentNotice(_error!, error: true),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving || _bank == null ? null : _save,
                child: Text(_saving ? 'Đang lưu...' : 'Lưu tài khoản'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class CustomerBankVerificationScreen extends StatefulWidget {
  final CustomerBankAccount account;
  final CustomerBankApiService? service;
  final bool initiate;
  const CustomerBankVerificationScreen({
    super.key,
    required this.account,
    this.service,
    this.initiate = false,
  });
  @override
  State<CustomerBankVerificationScreen> createState() =>
      _CustomerBankVerificationScreenState();
}

class _CustomerBankVerificationScreenState
    extends State<CustomerBankVerificationScreen>
    with WidgetsBindingObserver {
  late final _api = widget.service ?? CustomerBankApiService();
  BankVerificationState? _state;
  Map<String, dynamic>? _session;
  String? _error;
  bool _starting = false, _checking = false, _opening = false;
  Timer? _timer;
  int _polls = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.initiate) {
      _start();
    } else {
      _refresh();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
      _poll();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _timer?.cancel();
    }
  }

  void _poll() {
    _timer?.cancel();
    _polls = 0;
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted ||
          ++_polls > 60 ||
          (_state?.isVerified == true &&
              {'REFUNDED', 'NONE'}.contains(_state?.refundStatus))) {
        timer.cancel();
        return;
      }
      _refresh();
    });
  }

  Future<void> _refresh() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final state = await _api.getStatus(widget.account.id);
      if (mounted) setState(() => _state = state);
    } catch (error) {
      if (mounted) {
        setState(() => _error = _bankError(error));
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _start() async {
    if (_starting) return;
    setState(() {
      _starting = true;
      _error = null;
      _session = null;
    });
    try {
      final session = await _api.initiateVerification(widget.account.id);
      if (!mounted) return;
      setState(() => _session = session);
      await _refresh();
      if (mounted) _poll();
    } catch (error) {
      if (mounted) {
        setState(() => _error = _bankError(error));
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _openPayment() async {
    if (_opening) return;
    final uri = Uri.tryParse(_session?['checkoutUrl']?.toString() ?? '');
    if (uri == null ||
        uri.scheme != 'https' ||
        !(uri.host == 'payos.vn' || uri.host.endsWith('.payos.vn'))) {
      setState(
        () => _error = 'Liên kết thanh toán chưa hợp lệ. Vui lòng thử lại.',
      );
      return;
    }
    setState(() => _opening = true);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('Cannot open checkout');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Không thể mở trang thanh toán. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPay =
        _session != null &&
        num.tryParse(_session!['amount'].toString()) == 2000 &&
        _state?.isVerified != true &&
        _state?.expired != true &&
        !{'PAID', 'PENDING_RECONCILIATION'}.contains(_state?.paymentStatus);
    return ResidentScaffold(
      appBar: AppBar(title: const Text('Xác minh tài khoản')),
      actions: [
        if (canPay)
          FilledButton(
            onPressed: _starting || _opening ? null : _openPayment,
            child: const Text('Mở thanh toán xác minh 2.000đ'),
          ),
        if (_state?.isVerified != true)
          OutlinedButton(
            onPressed: _starting ? null : _start,
            child: const Text('Tạo / lấy lại phiên xác minh'),
          ),
        TextButton(
          onPressed: _checking ? null : _refresh,
          child: const Text('Kiểm tra trạng thái'),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ResidentNotice(_error!, error: true),
            ),
          const ResidentHero(
            icon: Icons.account_balance_outlined,
            eyebrow: 'Khoản xác minh',
            title: '2.000 ₫',
            description:
                'Chuyển đúng số tiền qua PayOS từ tài khoản cần xác minh.',
          ),
          ResidentPanel(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const ResidentIcon(Icons.account_balance_outlined),
              title: Text(widget.account.bankName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.account.maskedNumber),
                  Text(widget.account.accountName),
                ],
              ),
            ),
          ),
          if (_starting || _checking) const LinearProgressIndicator(),
          if (_state != null) ...[
            ResidentPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResidentBadge(
                    _state!.verificationLabel,
                    key: const Key('bank-verification-status'),
                    success: _state!.isVerified,
                    waiting: !_state!.isVerified,
                  ),
                  if (_state!.rejectionReason != null)
                    Text(_state!.rejectionReason!),
                  const Divider(height: 24),
                  const Text(
                    'Hoàn khoản xác minh',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(BankVerificationState.refundLabel(_state!.refundStatus)),
                  Text(
                    'Khoản xác minh đã hoàn: ${CurrencyFormatter.format(_state!.refundedAmount)}',
                  ),
                  if (_state!.pendingRefundAmount > 0)
                    Text(
                      'Khoản xác minh đang chờ hoàn: ${CurrencyFormatter.format(_state!.pendingRefundAmount)}',
                    ),
                ],
              ),
            ),
          ],
          const ResidentNotice(
            'Khoản xác minh 2.000đ được xử lý riêng. Tiền cọc nút chỉ được hoàn sau khi cửa hàng xác nhận đã nhận lại nút.',
          ),
        ],
      ),
    );
  }
}

class _BankHistoryScreen extends StatefulWidget {
  final CustomerBankApiService api;
  const _BankHistoryScreen({required this.api});
  @override
  State<_BankHistoryScreen> createState() => _BankHistoryScreenState();
}

class _BankHistoryScreenState extends State<_BankHistoryScreen> {
  final List<Map> _items = [];
  int _page = 1;
  bool _loading = false, _hasMore = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.api.getHistory(page: _page);
      if (!mounted) return;
      final rows = (result['data'] as List).cast<Map>();
      final total = int.tryParse(
        result['pagination']?['total']?.toString() ?? '',
      );
      setState(() {
        _items.addAll(rows);
        _page++;
        _hasMore = total != null ? _items.length < total : rows.length == 20;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = _bankError(error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => ResidentScaffold(
    appBar: AppBar(title: const Text('Lịch sử xác minh')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (final item in _items)
          ResidentPanel(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const ResidentIcon(Icons.history),
              title: Text(
                item['verificationStatus'] == 'VERIFIED'
                    ? 'Đã xác minh chính chủ'
                    : 'Chưa xác minh',
              ),
              subtitle: Text(
                '${item['createdAt'] ?? ''}\n${BankVerificationState.refundLabel(item['refundStatus']?.toString() ?? 'NONE')}',
              ),
            ),
          ),
        if (_items.isEmpty && !_loading && _error == null)
          const ResidentPanel(child: Text('Chưa có lịch sử xác minh.')),
        if (_error != null) ResidentNotice(_error!, error: true),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (_hasMore && !_loading)
          TextButton(
            onPressed: _load,
            child: Text(_error == null ? 'Tải thêm' : 'Thử lại'),
          ),
      ],
    ),
  );
}
