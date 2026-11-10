import 'customer_bank_accounts_screen.dart';
import 'package:flutter/material.dart';
import '../widgets/resident_ui.dart';
import '../models/customer_button_contract.dart';
import '../services/customer_buttons_api_service.dart';
import '../services/api_client.dart';
import '../utils/formatters.dart';

class CustomerButtonsScreen extends StatefulWidget {
  final CustomerButtonsApiService? service;
  const CustomerButtonsScreen({super.key, this.service});
  @override
  State<CustomerButtonsScreen> createState() => _CustomerButtonsScreenState();
}

class _CustomerButtonsScreenState extends State<CustomerButtonsScreen>
    with WidgetsBindingObserver {
  late final _service = widget.service ?? CustomerButtonsApiService();
  late Future<List<CustomerButtonContract>> _contracts;
  final Set<String> _pendingReturns = {};
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _contracts = _service.getMyButtons();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) _reload();
  }

  Future<void> _reload() async {
    final next = _service.getMyButtons();
    setState(() {
      _contracts = next;
    });
    try {
      await next;
    } catch (_) {
      /* FutureBuilder displays the error. */
    }
  }

  Future<void> _requestReturn(
    CustomerButtonContract contract,
    CustomerContractButton button,
  ) async {
    final key = '${contract.id}:${button.id}';
    if (_busy || _pendingReturns.contains(key)) return;
    final confirmed = await showResidentConfirmation(
      context,
      title: 'Trả lại nút?',
      message:
          'Gửi yêu cầu trả ${button.name}. Tiền cọc chỉ được hoàn sau khi cửa hàng xác nhận đã nhận lại nút.',
      confirmLabel: 'Gửi yêu cầu',
      cancelLabel: 'Quay lại',
      destructive: true,
    );
    if (!mounted ||
        confirmed != true ||
        _busy ||
        _pendingReturns.contains(key)) {
      return;
    }
    setState(() => _busy = true);
    try {
      await _service.requestReturn(
        contractId: contract.id,
        buttonId: button.id,
      );
      if (!mounted) return;
      setState(() => _pendingReturns.add(key));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã gửi yêu cầu. Vui lòng trả nút cho cửa hàng và chờ xác nhận tiếp nhận.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException
                  ? error.message
                  : 'Không thể gửi yêu cầu trả nút. Vui lòng tải lại và thử lại.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ResidentScaffold(
    appBar: AppBar(
      title: const Text('Nút và tiền cọc'),
      actions: [
        IconButton(
          tooltip: 'Làm mới',
          onPressed: _busy ? null : _reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    actions: [
      OutlinedButton.icon(
        icon: const Icon(Icons.account_balance_outlined),
        label: const Text('Tài khoản nhận hoàn cọc'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const CustomerBankAccountsScreen(),
          ),
        ),
      ),
    ],
    body: FutureBuilder<List<CustomerButtonContract>>(
      future: _contracts,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Không thể tải thông tin nút và tiền cọc.'),
                TextButton(onPressed: _reload, child: const Text('Thử lại')),
              ],
            ),
          );
        }
        final contracts = snapshot.data ?? [];
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              const ResidentNotice(
                'Bạn chỉ cọc tiền nút. Cửa hàng xác nhận nhận lại nút trước khi xử lý hoàn cọc.',
              ),
              if (contracts.isEmpty)
                const ResidentPanel(
                  child: Text(
                    'Bạn chưa có hồ sơ nhận nút. Vui lòng liên hệ cửa hàng.',
                  ),
                ),
              for (final contract in contracts)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ResidentHero(
                      icon: Icons.smart_button_outlined,
                      eyebrow: 'Tiền cọc theo hồ sơ',
                      title: CurrencyFormatter.format(contract.depositAmount),
                      description: 'Hồ sơ ${contract.code}',
                      strong: true,
                    ),
                    ResidentPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nút của bạn',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ResidentBadge(
                            contract.statusLabel,
                            success: contract.status == 'RETURNED',
                            waiting:
                                contract.canOrder == false &&
                                contract.status != 'RETURNED',
                          ),
                          if (contract.canOrder == false &&
                              contract.status == 'ACTIVE')
                            const ResidentNotice(
                              'Nút đang tạm ngừng sử dụng. Vui lòng liên hệ cửa hàng.',
                            ),
                          if (contract.status == 'RETURNED')
                            const ResidentNotice(
                              'Cửa hàng đã nhận lại nút. Khoản hoàn cọc sẽ được chuyển về tài khoản ngân hàng đã xác minh sau khi được duyệt.',
                            ),
                          for (final button in contract.buttons)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const ResidentIcon(
                                Icons.smart_button_outlined,
                              ),
                              title: Text(button.name),
                              subtitle:
                                  _pendingReturns.contains(
                                    '${contract.id}:${button.id}',
                                  )
                                  ? const Text(
                                      'Đã gửi yêu cầu — chờ cửa hàng nhận lại',
                                    )
                                  : null,
                              trailing: contract.canRequestReturn
                                  ? TextButton(
                                      onPressed:
                                          _busy ||
                                              _pendingReturns.contains(
                                                '${contract.id}:${button.id}',
                                              )
                                          ? null
                                          : () => _requestReturn(
                                              contract,
                                              button,
                                            ),
                                      child: const Text('Trả nút'),
                                    )
                                  : null,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    ),
  );
}
