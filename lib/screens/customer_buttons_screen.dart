import 'customer_bank_accounts_screen.dart';
import 'package:flutter/material.dart';
import '../widgets/smart_order_tour.dart';
import '../widgets/resident_ui.dart';
import '../models/customer_button_contract.dart';
import '../services/customer_buttons_api_service.dart';
import '../services/api_client.dart';
import '../utils/formatters.dart';

class CustomerButtonsScreen extends StatefulWidget {
  final CustomerButtonsApiService? service;
  const CustomerButtonsScreen({super.key, this.service, this.tour});
  final SmartOrderTour? tour;
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
  Widget build(BuildContext context) {
    widget.tour?.trackRoute(context, TourStep.amount);
    return ResidentScaffold(
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
          key: widget.tour?.key(TourStep.refund),
          icon: const Icon(Icons.account_balance_outlined),
          label: const Text('Tài khoản nhận hoàn cọc'),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const CustomerBankAccountsScreen(),
              ),
            );
            if (mounted) widget.tour?.refundViewed();
          },
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
                  Text(
                    'Không thể tải thông tin nút và tiền cọc.',
                    key: widget.tour?.key(TourStep.amount),
                  ),
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
                  'Theo dõi nút và tiền cọc của bạn. Cửa hàng xác nhận nhận lại nút trước khi xử lý hoàn cọc.',
                ),
                if (contracts.isEmpty)
                  ResidentPanel(
                    key: widget.tour?.key(TourStep.amount),
                    child: const Text(
                      'Bạn chưa có hồ sơ nhận nút. Vui lòng liên hệ cửa hàng.',
                    ),
                  ),
                for (final contract in contracts)
                  ResidentPanel(
                    key: identical(contract, contracts.first)
                        ? widget.tour?.key(TourStep.amount)
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Text(
                              'Hồ sơ ${contract.code}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            ResidentBadge(
                              contract.statusLabel,
                              success: contract.status == 'RETURNED',
                              waiting:
                                  contract.canOrder == false &&
                                  contract.status != 'RETURNED',
                            ),
                          ],
                        ),
                        for (final button in contract.buttons) ...[
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const ResidentIcon(
                              Icons.smart_button_outlined,
                            ),
                            title: Text(
                              button.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle:
                                _pendingReturns.contains(
                                  '${contract.id}:${button.id}',
                                )
                                ? const Text(
                                    'Đã gửi yêu cầu — chờ cửa hàng nhận lại',
                                  )
                                : null,
                          ),
                          if (contract.canRequestReturn)
                            OutlinedButton(
                              onPressed:
                                  _busy ||
                                      _pendingReturns.contains(
                                        '${contract.id}:${button.id}',
                                      )
                                  ? null
                                  : () => _requestReturn(contract, button),
                              child: const Text('Yêu cầu trả nút'),
                            ),
                        ],
                        const Divider(height: 24),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            const Text('Tiền cọc theo hồ sơ'),
                            Text(
                              CurrencyFormatter.format(contract.depositAmount),
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
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
                      ],
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
