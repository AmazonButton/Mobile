import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'customer_bank_accounts_screen.dart';
import '../widgets/smart_order_tour.dart';
import '../widgets/resident_ui.dart';
import '../models/customer_button_contract.dart';
import '../services/customer_buttons_api_service.dart';
import '../services/stores_api_service.dart';
import '../services/api_client.dart';
import '../providers/address_provider.dart';
import '../utils/formatters.dart';

class CustomerButtonsScreen extends StatefulWidget {
  final CustomerButtonsApiService? service;
  final SmartOrderTour? tour;
  final int initialTab;

  const CustomerButtonsScreen({
    super.key,
    this.service,
    this.tour,
    this.initialTab = 0,
  });

  @override
  State<CustomerButtonsScreen> createState() => _CustomerButtonsScreenState();
}

class _CustomerButtonsScreenState extends State<CustomerButtonsScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final _service = widget.service ?? CustomerButtonsApiService();
  late final _storesService = StoresApiService();

  late TabController _tabController;
  late Future<List<CustomerButtonContract>> _contracts;
  late Future<List<dynamic>> _packages;

  final Set<String> _pendingReturns = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _contracts = _service.getMyButtons();
    _packages = _storesService.getRentalPackages();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) _reload();
  }

  Future<void> _reload() async {
    final nextContracts = _service.getMyButtons();
    final nextPackages = _storesService.getRentalPackages();
    setState(() {
      _contracts = nextContracts;
      _packages = nextPackages;
    });
    try {
      await Future.wait([nextContracts, nextPackages]);
    } catch (_) {
      /* FutureBuilders handle error states */
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

  void _openRentSheet(Map<String, dynamic> pkg) {
    HapticFeedback.lightImpact();
    final userAddress = context.read<AddressProvider>().currentAddressDisplay;
    final addressCtrl = TextEditingController(text: userAddress);
    int months = 1;

    final pkgName = pkg['packageName'] ?? pkg['name'] ?? 'Gói nút bấm';
    final monthlyPrice = (pkg['price'] ?? pkg['rentalPrice'] ?? 0) as num;
    final deposit = (pkg['depositFee'] ?? pkg['depositAmount'] ?? 0) as num;
    final buttonCount = pkg['buttonQuantity'] ?? pkg['numberOfButtons'] ?? 1;
    final packageId = (pkg['packageId'] ?? pkg['id']).toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final totalRent = monthlyPrice * months;
          final totalAmount = totalRent + deposit;

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 18,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          LucideIcons.cpu,
                          color: Color(0xFF2563EB),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pkgName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Bao gồm $buttonCount nút bấm thông minh IoT',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Thời hạn thuê
                  const Text(
                    'Thời hạn thuê',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [1, 3, 6, 12].map((m) {
                      final selected = months == m;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () => setModalState(() => months = m),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '$m tháng',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  if (m >= 6) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      m == 12 ? '-20%' : '-10%',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: selected
                                            ? Colors.white.withOpacity(0.9)
                                            : const Color(0xFF16A34A),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // Địa chỉ nhận nút
                  const Text(
                    'Địa chỉ giao nhận nút',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: addressCtrl,
                    decoration: InputDecoration(
                      hintText: 'Nhập số nhà, tên đường, khu vực...',
                      prefixIcon: const Icon(
                        LucideIcons.mapPin,
                        size: 18,
                        color: Color(0xFF2563EB),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Chi tiết thanh toán
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Cước thuê ($months tháng)'),
                            Text(
                              CurrencyFormatter.format(totalRent),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tiền cọc thiết bị (hoàn lại)'),
                            Text(
                              CurrencyFormatter.format(deposit),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng thanh toán',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(totalAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nút xác nhận đặt thuê
                  ElevatedButton(
                    onPressed: _busy
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            setState(() => _busy = true);
                            try {
                              await _storesService.orderRentalPackage(
                                packageId: packageId,
                                months: months,
                                deliveryAddress: addressCtrl.text.trim(),
                              );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Color(0xFF16A34A),
                                  content: Text(
                                    '🎉 Đã tạo hợp đồng thuê nút thành công! Vui lòng kiểm tra hồ sơ.',
                                  ),
                                ),
                              );
                              _tabController.animateTo(1);
                              _reload();
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFFDC2626),
                                  content: Text(
                                    e is ApiException
                                        ? e.message
                                        : 'Không thể đặt thuê gói. Vui lòng thử lại sau.',
                                  ),
                                ),
                              );
                            } finally {
                              if (mounted) setState(() => _busy = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Xác nhận đặt thuê nút',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    widget.tour?.trackRoute(context, TourStep.amount);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Thuê nút & Tiền cọc',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _busy ? null : _reload,
            icon: const Icon(LucideIcons.refreshCw, size: 20, color: Color(0xFF2563EB)),
          ),
          IconButton(
            tooltip: 'Tài khoản hoàn cọc',
            icon: const Icon(LucideIcons.landmark, size: 20, color: Color(0xFF64748B)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const CustomerBankAccountsScreen(),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF2563EB),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: 'Gói thuê nút IoT'),
            Tab(text: 'Hợp đồng của tôi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── TAB 1: GÓI THUÊ NÚT IOT ──
          FutureBuilder<List<dynamic>>(
            future: _packages,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Shimmer.fromColors(
                  baseColor: const Color(0xFFF1F5F9),
                  highlightColor: Colors.white,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 3,
                    itemBuilder: (_, __) => Container(
                      height: 180,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                );
              }

              final packages = (snapshot.data ?? [])
                  .whereType<Map>()
                  .map((p) => Map<String, dynamic>.from(p))
                  .toList();

              if (packages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.cpu, size: 36, color: Color(0xFF2563EB)),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Chưa có gói thuê nút khả dụng',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Hệ thống đang cập nhật các gói nút bấm IoT mới.',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      TextButton(onPressed: _reload, child: const Text('Tải lại')),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _reload,
                color: const Color(0xFF2563EB),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: packages.length,
                  itemBuilder: (context, index) {
                    final pkg = packages[index];
                    final name = pkg['packageName'] ?? pkg['name'] ?? 'Gói nút thông minh';
                    final desc = pkg['description'] ?? 'Trải nghiệm đặt hàng một chạm ngay tại nhà';
                    final price = (pkg['price'] ?? pkg['rentalPrice'] ?? 0) as num;
                    final deposit = (pkg['depositFee'] ?? pkg['depositAmount'] ?? 0) as num;
                    final count = pkg['buttonQuantity'] ?? pkg['numberOfButtons'] ?? 1;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.radio, size: 12, color: Color(0xFF2563EB)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$count Nút bấm IoT',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Bảo hành trọn đời',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              desc,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Cước thuê hàng tháng',
                                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${CurrencyFormatter.format(price)}/tháng',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'Tiền cọc (hoàn lại 100%)',
                                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        CurrencyFormatter.format(deposit),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: _busy ? null : () => _openRentSheet(pkg),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.shoppingCart, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Thuê gói nút này',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // ── TAB 2: HỢP ĐỒNG CỦA TÔI & TIỀN CỌC ──
          FutureBuilder<List<CustomerButtonContract>>(
            future: _contracts,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                  ),
                );
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
                color: const Color(0xFF2563EB),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    const ResidentNotice(
                      'Theo dõi nút và tiền cọc của bạn. Cửa hàng xác nhận nhận lại nút trước khi xử lý hoàn cọc.',
                    ),
                    if (contracts.isEmpty)
                      ResidentPanel(
                        child: Column(
                          children: [
                            const Text('Bạn chưa có hợp đồng thuê nút nào.'),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _tabController.animateTo(0),
                              icon: const Icon(LucideIcons.plus, size: 16),
                              label: const Text('Xem các gói thuê nút ngay'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    for (final contract in contracts)
                      ResidentPanel(
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
                                  style: const TextStyle(fontWeight: FontWeight.w700),
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: _pendingReturns.contains(
                                  '${contract.id}:${button.id}',
                                )
                                    ? const Text(
                                        'Đã gửi yêu cầu — chờ cửa hàng nhận lại',
                                      )
                                    : null,
                              ),
                              if (contract.canRequestReturn)
                                OutlinedButton(
                                  onPressed: _busy ||
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
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2563EB),
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
        ],
      ),
    );
  }
}
