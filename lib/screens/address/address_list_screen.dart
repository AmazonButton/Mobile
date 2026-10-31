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

  const AddressListScreen({super.key, this.selectMode = false});

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
                  if (mounted)
                    _showFloatingToast(
                      _addressProvider!.errorMessage ?? 'Không thể xóa địa chỉ',
                    );
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
        if (mounted)
          _showFloatingToast(
            _addressProvider!.errorMessage ?? 'Không thể đặt địa chỉ mặc định',
          );
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
          'Địa chỉ nhận hàng',
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
              color: Color(0xFF2563EB),
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF2563EB),
          child: isLoading && addresses.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2563EB),
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
                    // Hint banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            LucideIcons.info,
                            size: 18,
                            color: Color(0xFF2563EB),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Đơn hàng tạo từ nút bấm thông minh sẽ tự động giao về địa chỉ mặc định.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1E40AF),
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ĐỊA CHỈ ĐÃ LƯU (${addresses.length})',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (widget.selectMode)
                          const Text(
                            'Chạm để chọn giao hàng',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

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
      bottomSheet: Container(
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
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _openAddModal,
            icon: const Icon(LucideIcons.plus, size: 18, color: Colors.white),
            label: const Text(
              'Thêm địa chỉ nhận hàng mới',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard(AddressModel item, bool isSelected) {
    IconData labelIcon = LucideIcons.home;
    if (item.label == 'Cơ quan') labelIcon = LucideIcons.briefcase;
    if (item.label == 'Khác') labelIcon = LucideIcons.mapPin;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: item.isDefault
              ? const Color(0xFF2563EB).withValues(alpha: 0.5)
              : const Color(0xFFE2E8F0),
          width: item.isDefault ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _selectAndReturn(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Label chip + Recipient info + Default badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Label Chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            labelIcon,
                            size: 12,
                            color: const Color(0xFF475569),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Recipient Name
                    Expanded(
                      child: Text(
                        item.recipientName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Default Badge
                    if (item.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFA7F3D0),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.check,
                              size: 12,
                              color: Color(0xFF059669),
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Mặc định',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Phone number
                Row(
                  children: [
                    const Icon(
                      LucideIcons.phone,
                      size: 13,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.phone,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Detailed address
                Text(
                  item.addressDetail,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                    height: 1.3,
                  ),
                ),

                // Ward, District, City
                if (item.ward != null ||
                    item.district != null ||
                    item.province != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (item.ward != null && item.ward!.isNotEmpty) item.ward,
                      if (item.district != null && item.district!.isNotEmpty)
                        item.district,
                      if (item.province != null && item.province!.isNotEmpty)
                        item.province,
                    ].join(', '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      height: 1.3,
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // Bottom Actions Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Set default action
                    if (!item.isDefault)
                      InkWell(
                        onTap: () => _setDefault(item),
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.circleDot,
                                size: 14,
                                color: Color(0xFF64748B),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Đặt làm mặc định',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.checkCheck,
                            size: 15,
                            color: Color(0xFF2563EB),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Địa chỉ nhận hàng mặc định',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),

                    // Edit & Delete Buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit
                        InkWell(
                          onTap: () => _openEditModal(item),
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.pencil,
                                  size: 14,
                                  color: Color(0xFF2563EB),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Sửa',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Delete
                        InkWell(
                          onTap: () => _confirmDelete(item),
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.trash2,
                                  size: 14,
                                  color: Color(0xFFEF4444),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Xóa',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.mapPinOff,
                size: 38,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chưa có địa chỉ nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thêm địa chỉ giao hàng để đặt nước, đổi bình gas nhanh chóng chỉ với 1 chạm nút thông minh.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openAddModal,
              icon: const Icon(LucideIcons.plus, size: 18, color: Colors.white),
              label: const Text(
                'Thêm địa chỉ đầu tiên',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
