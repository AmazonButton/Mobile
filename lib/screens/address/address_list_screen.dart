import '../../widgets/sample_a.dart';
import '../../widgets/smart_order_tour.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/address_model.dart';
import '../../providers/address_provider.dart';
import '../../services/address_api_service.dart';
import '../../services/user_profile_service.dart';
import 'address_form_sheet.dart';

class AddressListScreen extends StatefulWidget {
  final bool selectMode; // true nếu mở để chọn địa chỉ nhận hàng rồi đóng lại

  const AddressListScreen({super.key, this.selectMode = false, this.tour});
  final SmartOrderTour? tour;

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  final AddressApiService _apiService = AddressApiService();
  final UserProfileService _userService = UserProfileService();
  List<AddressModel> _fallbackAddresses = [];
  bool _isLocalLoading = false;

  AddressProvider? get _addressProvider {
    try {
      return Provider.of<AddressProvider>(context);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (_addressProvider != null) {
      await _addressProvider!.loadAddresses();
      if (mounted && _addressProvider!.errorMessage != null) {
        _showFloatingToast(_addressProvider!.errorMessage!);
      }
    } else {
      setState(() => _isLocalLoading = true);
      final list = await _apiService.getAddresses();
      if (mounted) {
        setState(() {
          _fallbackAddresses = list;
          _isLocalLoading = false;
        });
      }
    }
  }

  void _showFloatingToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openAddModal() async {
    HapticFeedback.lightImpact();
    final result = await AddressFormSheet.show(context);
    if (result != null && mounted) {
      _showFloatingToast('Đã thêm địa chỉ: ${result.shortDisplay}');
      _loadData();
    }
  }

  void _openEditModal(AddressModel address) async {
    HapticFeedback.lightImpact();
    final result = await AddressFormSheet.show(
      context,
      initialAddress: address,
    );
    if (result != null && mounted) {
      _showFloatingToast('Đã cập nhật địa chỉ');
      _loadData();
    }
  }

  void _confirmDelete(AddressModel address) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                LucideIcons.trash2,
                size: 20,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Xóa địa chỉ?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa địa chỉ "${address.addressDetail}" không?\nHành động này không thể hoàn tác.',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text(
              'Hủy',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dlgCtx);
              HapticFeedback.heavyImpact();

              if (_addressProvider != null) {
                final ok = await _addressProvider!.deleteAddress(address.id);
                if (!ok) {
                  if (mounted) {
                    _showFloatingToast(
                      _addressProvider!.errorMessage ?? 'Không thể xóa địa chỉ',
                    );
                  }
                  return;
                }
              } else {
                await _apiService.deleteAddress(address.id);
                _loadData();
              }

              if (mounted) {
                _showFloatingToast('Đã xóa địa chỉ thành công');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Xóa',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setDefault(AddressModel address) async {
    HapticFeedback.lightImpact();
    if (_addressProvider != null) {
      final ok = await _addressProvider!.setDefaultAddress(address.id);
      if (!ok) {
        if (mounted) {
          _showFloatingToast(
            _addressProvider!.errorMessage ?? 'Không thể đặt địa chỉ mặc định',
          );
        }
        return;
      }
    } else {
      await _apiService.setDefaultAddress(address.id);
      _userService.updateAddress(address.fullAddress);
      _loadData();
    }
    _showFloatingToast('Đã đặt làm địa chỉ mặc định');
  }

  void _selectAndReturn(AddressModel address) {
    HapticFeedback.mediumImpact();
    if (_addressProvider != null) {
      _addressProvider!.selectDeliveryAddress(address);
    } else {
      _userService.updateAddress(address.fullAddress);
    }

    if (widget.selectMode && Navigator.canPop(context)) {
      Navigator.pop(context, address);
    } else {
      _showFloatingToast('Đã chọn: ${address.shortDisplay}');
    }
  }

  @override
  Widget build(BuildContext context) {
    widget.tour?.trackRoute(context, TourStep.addressAdd);
    final addresses = _addressProvider?.addresses ?? _fallbackAddresses;
    final isLoading = _addressProvider?.isLoading ?? _isLocalLoading;
    final selectedId = _addressProvider?.selectedAddress?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.chevronLeft,
            color: Color(0xFF1E293B),
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Địa chỉ giao hàng',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _openAddModal,
            icon: const Icon(
              LucideIcons.plus,
              color: SampleA.primary,
              size: 22,
            ),
            tooltip: 'Thêm địa chỉ mới',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: AContent(
        maxWidth: SampleA.detailWidth,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: SampleA.primary,
            child: isLoading && addresses.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: SampleA.primary,
                      strokeWidth: 2.5,
                    ),
                  )
                : addresses.isEmpty
                ? _buildEmptyState()
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    children: [
                      // List of address cards
                      ...addresses.map((item) {
                        final isSelected = selectedId == item.id;
                        return _buildAddressCard(item, isSelected);
                      }),

                      const SizedBox(height: 80), // Padding for bottom button
                    ],
                  ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: widget.tour?.key(TourStep.addressAdd),
              onPressed: _openAddModal,
              icon: const Icon(LucideIcons.plus, size: 18, color: Colors.white),
              label: const Text(
                'Thêm địa chỉ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: SampleA.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard(AddressModel item, bool isSelected) {
    final labelIcon = item.label == 'Cơ quan'
        ? LucideIcons.building2
        : item.label == 'Khác'
        ? LucideIcons.mapPin
        : LucideIcons.home;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SampleA.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _selectAndReturn(item),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 36, right: 10),
                  child: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected
                        ? SampleA.primary
                        : const Color(0xFF64748B),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(labelIcon, size: 22),
                          Text(
                            item.label,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (item.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: SampleA.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Mặc định',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${item.recipientName} · ${item.phone}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.addressDetail,
                        style: const TextStyle(fontSize: 15, height: 1.4),
                      ),
                      Text(
                        [item.ward, item.district, item.province]
                            .whereType<String>()
                            .where((s) => s.isNotEmpty)
                            .join(', '),
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (!item.isDefault)
                            TextButton(
                              onPressed: () => _setDefault(item),
                              child: const Text('Đặt làm mặc định'),
                            ),
                          TextButton(
                            onPressed: () => _confirmDelete(item),
                            child: const Text(
                              'Xóa',
                              style: TextStyle(color: Color(0xFFEF4444)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Sửa',
                  onPressed: () => _openEditModal(item),
                  icon: const Icon(LucideIcons.pencil, size: 19),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
    children: const [
      Icon(LucideIcons.mapPinOff, size: 64, color: SampleA.primary),
      SizedBox(height: 20),
      Text(
        'Chưa có địa chỉ nào',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      SizedBox(height: 12),
      Text(
        'Thêm địa chỉ giao hàng để cửa hàng biết nơi nhận đơn của bạn.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 15, height: 1.4, color: Color(0xFF64748B)),
      ),
    ],
  );
}
