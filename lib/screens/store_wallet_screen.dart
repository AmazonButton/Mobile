import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/user_provider.dart';
import '../services/api_client.dart';
import '../services/stores_api_service.dart';
import '../widgets/app_motion.dart';
import '../widgets/sample_a.dart';

/// Màn hình Ví doanh thu & Rút tiền dành riêng cho Chủ cửa hàng (STORE_OWNER).
class StoreWalletScreen extends StatefulWidget {
  const StoreWalletScreen({super.key});

  @override
  State<StoreWalletScreen> createState() => _StoreWalletScreenState();
}

class _StoreWalletScreenState extends State<StoreWalletScreen> {
  final _storesApi = StoresApiService();

  static const List<Map<String, String>> _vnBanks = [
    {'bin': '970436', 'name': 'Vietcombank'},
    {'bin': '970407', 'name': 'Techcombank'},
    {'bin': '970422', 'name': 'MB Bank'},
    {'bin': '970415', 'name': 'VietinBank'},
    {'bin': '970418', 'name': 'BIDV'},
    {'bin': '970405', 'name': 'Agribank'},
    {'bin': '970416', 'name': 'ACB'},
    {'bin': '970432', 'name': 'VPBank'},
    {'bin': '970423', 'name': 'TPBank'},
    {'bin': '970403', 'name': 'Sacombank'},
    {'bin': '970437', 'name': 'HDBank'},
    {'bin': '970441', 'name': 'VIB'},
    {'bin': '970443', 'name': 'SHB'},
    {'bin': '970448', 'name': 'OCB'},
    {'bin': '970426', 'name': 'MSB'},
    {'bin': '970431', 'name': 'Eximbank'},
    {'bin': '970440', 'name': 'SeABank'},
    {'bin': '970449', 'name': 'LPBank'},
    {'bin': '970428', 'name': 'Nam A Bank'},
    {'bin': 'CUSTOM', 'name': 'Ngân hàng khác (nhập mã BIN)'},
  ];

  Map<String, dynamic>? _wallet;
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;
  String? _error;

  String? _bankField(String key) {
    final nested = _wallet?['bankAccount'];
    if (nested is Map && nested[key] != null) {
      final v = nested[key].toString().trim();
      if (v.isNotEmpty) return v;
    }
    final top = _wallet?[key]?.toString().trim();
    return (top != null && top.isNotEmpty) ? top : null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _storesApi.getStoreWallet(),
        _storesApi.getStoreTransactions().catchError((_) => <dynamic>[]),
      ]);
      if (!mounted) return;
      final wallet = results[0] is Map
          ? Map<String, dynamic>.from(results[0] as Map)
          : <String, dynamic>{};
      final txList = (results[1] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      setState(() {
        _wallet = wallet;
        _transactions = txList;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException
            ? e.message
            : 'Không thể tải ví doanh thu cửa hàng.';
        _loading = false;
      });
    }
  }

  num _numValue(dynamic v) => num.tryParse(v?.toString() ?? '') ?? 0;

  String _formatVnd(num value) {
    final neg = value < 0;
    final str = value.abs().round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final pos = str.length - i;
      buf.write(str[i]);
      if (pos > 1 && pos % 3 == 1) buf.write('.');
    }
    return '${neg ? '-' : ''}${buf.toString()} ₫';
  }

  String _formatDate(dynamic raw) {
    final dt = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (dt == null) return '';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$h:$min · $d/$m/${dt.year}';
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error
            ? const Color(0xFFDC2626)
            : const Color(0xFF047857),
        content: Text(message),
      ),
    );
  }

  Future<void> _openBankAccountSheet() async {
    HapticFeedback.lightImpact();
    final existingBin = _bankField('bankBin') ?? '';
    final existingName = _bankField('bankName') ?? '';
    final existingNumber = _bankField('bankAccountNumber') ?? '';
    final existingHolder = _bankField('bankAccountHolder') ?? '';

    String selectedBin = _vnBanks.any((b) => b['bin'] == existingBin)
        ? existingBin
        : (existingBin.isNotEmpty ? 'CUSTOM' : _vnBanks.first['bin']!);
    final matchedBank = _vnBanks.firstWhere(
      (b) => b['bin'] == selectedBin,
      orElse: () => _vnBanks.first,
    );

    final binCtrl = TextEditingController(
      text: selectedBin == 'CUSTOM' ? existingBin : selectedBin,
    );
    final bankCtrl = TextEditingController(
      text: existingName.isNotEmpty
          ? existingName
          : (selectedBin == 'CUSTOM' ? '' : matchedBank['name']!),
    );
    final cleanNumber = RegExp(r'^[0-9]{6,19}$').hasMatch(existingNumber)
        ? existingNumber
        : '';
    final accNumCtrl = TextEditingController(text: cleanNumber);
    final holderCtrl = TextEditingController(text: existingHolder);
    bool saving = false;
    String? sheetError;

    bool? saved;
    try {
      saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: Colors.white,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              4,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Tài khoản ngân hàng nhận tiền',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Dùng để đối soát và nhận tiền rút từ ví doanh thu cửa hàng.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),
                  if (sheetError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(11),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Text(
                        sheetError!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  ],
                  DropdownButtonFormField<String>(
                    initialValue: selectedBin,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Ngân hàng (Napas BIN)',
                      prefixIcon: Icon(LucideIcons.landmark, size: 18),
                    ),
                    items: _vnBanks
                        .map(
                          (b) => DropdownMenuItem<String>(
                            value: b['bin'],
                            child: Text(
                              b['bin'] == 'CUSTOM'
                                  ? b['name']!
                                  : '${b['name']} (${b['bin']})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setSheet(() {
                        selectedBin = val;
                        sheetError = null;
                        if (val != 'CUSTOM') {
                          final found = _vnBanks.firstWhere(
                            (b) => b['bin'] == val,
                          );
                          binCtrl.text = val;
                          bankCtrl.text = found['name']!;
                        } else {
                          binCtrl.clear();
                          bankCtrl.clear();
                        }
                      });
                    },
                  ),
                  if (selectedBin == 'CUSTOM') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: binCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'Mã BIN ngân hàng (6 chữ số)',
                        counterText: '',
                        prefixIcon: Icon(LucideIcons.hash, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bankCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tên ngân hàng',
                        prefixIcon: Icon(LucideIcons.landmark, size: 18),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: accNumCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Số tài khoản (6–19 chữ số)',
                      hintText: existingNumber.contains('*')
                          ? 'Nhập lại đầy đủ số tài khoản'
                          : null,
                      prefixIcon: const Icon(LucideIcons.creditCard, size: 18),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: holderCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Tên chủ tài khoản (không dấu)',
                      prefixIcon: Icon(LucideIcons.user, size: 18),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AButton(
                    label: 'Lưu tài khoản ngân hàng',
                    busy: saving,
                    onPressed: saving
                        ? null
                        : () async {
                            final bin = binCtrl.text.trim();
                            final name = bankCtrl.text.trim();
                            final accNum = accNumCtrl.text.trim();
                            final holder = holderCtrl.text.trim();
                            if (!RegExp(r'^[0-9]{6}$').hasMatch(bin)) {
                              setSheet(
                                () => sheetError =
                                    'Mã BIN ngân hàng phải gồm đúng 6 chữ số.',
                              );
                              return;
                            }
                            if (name.isEmpty) {
                              setSheet(
                                () => sheetError = 'Vui lòng nhập tên ngân hàng.',
                              );
                              return;
                            }
                            if (!RegExp(r'^[0-9]{6,19}$').hasMatch(accNum)) {
                              setSheet(
                                () => sheetError =
                                    'Số tài khoản phải gồm từ 6 đến 19 chữ số.',
                              );
                              return;
                            }
                            if (holder.isEmpty) {
                              setSheet(
                                () => sheetError =
                                    'Vui lòng nhập tên chủ tài khoản.',
                              );
                              return;
                            }
                            setSheet(() {
                              saving = true;
                              sheetError = null;
                            });
                            try {
                              await _storesApi.updateBankAccount(
                                bankBin: bin,
                                bankName: name,
                                bankAccountNumber: accNum,
                                bankAccountHolder: holder,
                              );
                              if (ctx.mounted) Navigator.pop(ctx, true);
                            } catch (e) {
                              if (ctx.mounted) {
                                setSheet(() {
                                  saving = false;
                                  sheetError = e is ApiException
                                      ? e.message
                                      : 'Không thể cập nhật ngân hàng.';
                                });
                              }
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      binCtrl.dispose();
      bankCtrl.dispose();
      accNumCtrl.dispose();
      holderCtrl.dispose();
    }
    if (saved == true) {
      _snack('Đã lưu tài khoản ngân hàng nhận tiền!');
      _load();
    }
  }

  Future<void> _openWithdrawSheet() async {
    HapticFeedback.lightImpact();
    final balance = _numValue(_wallet?['balance']);
    final amountCtrl = TextEditingController();
    bool submitting = false;
    String? sheetError;

    bool? ok;
    try {
      ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: Colors.white,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              4,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Yêu cầu rút tiền doanh thu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Số dư khả dụng: ${_formatVnd(balance)} · Tối thiểu 50.000 ₫',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF047857),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (sheetError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(11),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Text(
                        sheetError!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  ],
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số tiền muốn rút (VNĐ)',
                      hintText: 'VD: 500000',
                      prefixIcon: Icon(LucideIcons.banknote, size: 18),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AButton(
                    label: 'Gửi yêu cầu rút tiền',
                    busy: submitting,
                    onPressed: submitting
                        ? null
                        : () async {
                            final digits = amountCtrl.text.replaceAll(
                              RegExp(r'[^0-9]'),
                              '',
                            );
                            final amount = int.tryParse(digits);
                            if (amount == null || amount < 50000) {
                              setSheet(
                                () => sheetError =
                                    'Số tiền rút tối thiểu là 50.000 ₫ (số nguyên VNĐ).',
                              );
                              return;
                            }
                            if (amount > balance) {
                              setSheet(
                                () => sheetError =
                                    'Số tiền rút vượt quá số dư khả dụng.',
                              );
                              return;
                            }
                            setSheet(() {
                              submitting = true;
                              sheetError = null;
                            });
                            try {
                              await _storesApi.requestWithdrawal(amount);
                              if (ctx.mounted) Navigator.pop(ctx, true);
                            } catch (e) {
                              if (ctx.mounted) {
                                setSheet(() {
                                  submitting = false;
                                  sheetError = e is ApiException
                                      ? e.message
                                      : 'Không thể gửi yêu cầu rút tiền.';
                                });
                              }
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      amountCtrl.dispose();
    }
    if (ok == true) {
      _snack('Đã gửi yêu cầu rút tiền! Chờ hệ thống đối soát & chi trả.');
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeName = context.watch<UserProvider?>()?.storeName;
    final balance = _numValue(_wallet?['balance']);
    final frozen = _numValue(_wallet?['frozenBalance']);
    final bankName = _bankField('bankName');
    final bankMasked =
        _bankField('bankAccountNumberMasked') ??
        _bankField('bankAccountNumber');
    final allowAmbient = AppMotion.allowAmbient(context);
    final loadingSkeleton = Column(
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        const SizedBox(height: 16),
        for (int i = 0; i < 3; i++)
          Container(
            height: 76,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Ví doanh thu cửa hàng',
          style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _loading ? null : _load,
            icon: const Icon(LucideIcons.refreshCw, size: 19),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: AContent(
        maxWidth: SampleA.listWidth,
        child: RefreshIndicator(
          onRefresh: _load,
          color: const Color(0xFF047857),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (_loading)
                allowAmbient
                    ? Shimmer.fromColors(
                        baseColor: const Color(0xFFE2E8F0),
                        highlightColor: Colors.white,
                        child: loadingSkeleton,
                      )
                    : loadingSkeleton
              else if (_error != null)
                ACard(
                  child: Column(
                    children: [
                      const Icon(
                        LucideIcons.wallet,
                        size: 36,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: SampleA.body,
                      ),
                      const SizedBox(height: 14),
                      AButton(label: 'Thử lại', onPressed: _load),
                    ],
                  ),
                )
              else ...[
                // Emerald Revenue Hero Card
                StaggeredReveal(
                  index: 0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF064E3B),
                          Color(0xFF047857),
                          Color(0xFF0D9488),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF047857).withValues(alpha: 0.24),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const PulsingDot(
                                      color: Color(0xFF6EE7B7),
                                      size: 6,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        storeName?.isNotEmpty == true
                                            ? storeName!
                                            : 'Ví doanh thu đại lý',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Số dư khả dụng',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatVnd(balance),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            color: Colors.white,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.lock,
                              size: 13,
                              color: Color(0xFFA7F3D0),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Đang đối soát / tạm giữ: ${_formatVnd(frozen)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFD1FAE5),
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TactilePress(
                                scaleDown: 0.96,
                                borderRadius: BorderRadius.circular(13),
                                child: ElevatedButton.icon(
                                  onPressed: _openWithdrawSheet,
                                  icon: const Icon(
                                    LucideIcons.arrowUpRight,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Rút tiền',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF047857),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 11,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TactilePress(
                                scaleDown: 0.96,
                                borderRadius: BorderRadius.circular(13),
                                child: OutlinedButton.icon(
                                  onPressed: _openBankAccountSheet,
                                  icon: const Icon(
                                    LucideIcons.landmark,
                                    size: 15,
                                  ),
                                  label: const Text(
                                    'Ngân hàng',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.42,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 11,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Bank Account Status Banner
                StaggeredReveal(
                  index: 1,
                  child: TactilePress(
                    scaleDown: 0.985,
                    haptic: true,
                    borderRadius: BorderRadius.circular(16),
                    onTap: _openBankAccountSheet,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: AppMotion.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              LucideIcons.landmark,
                              size: 19,
                              color: Color(0xFF047857),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bankName != null && bankName.isNotEmpty
                                      ? '$bankName · ${bankMasked ?? ''}'
                                      : 'Chưa liên kết tài khoản ngân hàng',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Chạm để thiết lập hoặc cập nhật tài khoản nhận tiền',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            LucideIcons.chevronRight,
                            size: 17,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Lịch sử giao dịch ví',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${_transactions.length} giao dịch',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (_transactions.isEmpty)
                  const ACard(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Icon(
                            LucideIcons.receipt,
                            size: 32,
                            color: Color(0xFF94A3B8),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Chưa có biến động số dư nào',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Doanh thu từ các đơn hàng hoàn tất sẽ tự động ghi có tại đây.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._transactions.asMap().entries.map((entry) {
                    final tx = entry.value;
                    final amount = _numValue(tx['amount']);
                    final type = (tx['type'] ?? '').toString().toUpperCase();
                    final isDebit =
                        amount < 0 ||
                        ((type.contains('WITHDRAW') ||
                                type.contains('FEE') ||
                                type.contains('DEBIT') ||
                                type.contains('HOLD')) &&
                            !type.contains('REFUND') &&
                            !type.contains('RELEASE') &&
                            !type.contains('CREDIT'));
                    final isCredit = !isDebit && amount > 0;
                    final desc = (tx['description'] ?? type).toString();
                    final ref = tx['referenceId']?.toString() ?? '';
                    final when = _formatDate(tx['createdAt']);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: AppMotion.cardShadow,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isCredit
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(
                              isCredit
                                  ? LucideIcons.arrowDownLeft
                                  : LucideIcons.arrowUpRight,
                              size: 18,
                              color: isCredit
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  desc,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  [
                                    if (ref.isNotEmpty) ref,
                                    if (when.isNotEmpty) when,
                                  ].join(' · '),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${isCredit ? '+' : ''}${_formatVnd(amount)}',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              color: isCredit
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
