import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/address_prediction.dart';
import '../services/user_profile_service.dart';
import '../services/address_service.dart';
import 'package:provider/provider.dart';
import '../providers/address_provider.dart';
import '../screens/address/address_list_screen.dart';

class AddressPickerSheet extends StatefulWidget {
  final Function(String selectedAddress)? onAddressSelected;

  const AddressPickerSheet({
    super.key,
    this.onAddressSelected,
  });

  /// Hàm tiện ích tĩnh để mở modal từ bất kỳ màn hình nào
  static Future<String?> show(
    BuildContext context, {
    Function(String selectedAddress)? onAddressSelected,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddressPickerSheet(
        onAddressSelected: onAddressSelected,
      ),
    );
  }

  @override
  State<AddressPickerSheet> createState() => _AddressPickerSheetState();
}

class _AddressPickerSheetState extends State<AddressPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final UserProfileService _userService = UserProfileService();

  Timer? _debounceTimer;
  bool _isLoading = false;
  String _activeTab = 'recent'; // 'recent' | 'suggest' | 'saved'

  List<AddressPrediction> _searchResults = [];
  List<String> _recentAddresses = [];

  final List<Map<String, String>> _savedAddresses = [
    {
      'title': 'Nhà riêng',
      'address': 'P.1204 - Tòa S2.05, Vinhomes Grand Park',
      'icon': 'home',
    },
    {
      'title': 'Cơ quan / Văn phòng',
      'address': 'Tòa Landmark 81, 720A Điện Biên Phủ, P. 22, Q. Bình Thạnh',
      'icon': 'briefcase',
    },
    {
      'title': 'Căn hộ cho thuê',
      'address': 'P.0405 - Tòa Masteri M2, Vinhomes Grand Park',
      'icon': 'building',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentAddresses();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadRecentAddresses() async {
    final list = await AddressService.getRecentAddresses();
    if (mounted) {
      setState(() {
        _recentAddresses = list;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Debounce 350ms tự động gọi API Autocomplete
    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      final results = await AddressService.search(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    });
  }

  void _selectAddress(String fullAddress) async {
    HapticFeedback.mediumImpact();
    await AddressService.saveRecentAddress(fullAddress);
    _userService.updateAddress(fullAddress);
    if (mounted) {
      try {
        final addrProv = Provider.of<AddressProvider>(context, listen: false);
        final match = addrProv.addresses.where((a) => a.fullAddress == fullAddress || fullAddress.contains(a.addressDetail)).firstOrNull;
        if (match != null) {
          addrProv.selectDeliveryAddress(match);
        }
      } catch (_) {}
    }

    if (widget.onAddressSelected != null) {
      widget.onAddressSelected!(fullAddress);
    }

    if (mounted) {
      Navigator.pop(context, fullAddress);
    }
  }

  void _promptRoomNumberIfNeeded(AddressPrediction pred) {
    HapticFeedback.lightImpact();

    // Nếu địa chỉ đã có số phòng sẵn thì chọn luôn
    if (pred.room != null ||
        pred.primaryText.toLowerCase().contains('p.') ||
        !pred.primaryText.toLowerCase().contains('tòa')) {
      _selectAddress(pred.fullAddress);
      return;
    }

    final roomController = TextEditingController();

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
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.building,
                  size: 20, color: Color(0xFF2563EB)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Số căn hộ / Tầng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Giao đến: ${pred.primaryText}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: roomController,
              autofocus: true,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                hintText: 'VD: P.1204 hoặc 1204',
                prefixIcon: const Icon(LucideIcons.home, size: 18),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dlgCtx);
              _selectAddress(pred.fullAddress);
            },
            child: const Text('Bỏ qua',
                style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              final roomText = roomController.text.trim();
              Navigator.pop(dlgCtx);
              if (roomText.isNotEmpty) {
                final formattedRoom = roomText.toUpperCase().startsWith('P.')
                    ? roomText.toUpperCase()
                    : 'P.$roomText';
                _selectAddress('$formattedRoom - ${pred.fullAddress}');
              } else {
                _selectAddress(pred.fullAddress);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Xác nhận',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.88,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. Drag bar handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Header Title with Close Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chọn vị trí giao hàng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.x,
                        size: 18, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Search Bar with Clear Button & Loading indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _searchFocus.hasFocus
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                textInputAction: TextInputAction.search,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Nhập số phòng, tòa nhà, tên đường...',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(
                    LucideIcons.search,
                    size: 19,
                    color: Color(0xFF64748B),
                  ),
                  suffixIcon: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        )
                      : _searchController.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                              },
                              child: const Icon(
                                LucideIcons.xCircle,
                                size: 18,
                                color: Color(0xFF94A3B8),
                              ),
                            )
                          : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 4. Quick Filter Chips (Dùng gần đây, Đề xuất, Đã lưu)
          if (_searchController.text.trim().isEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildTabChip('recent', 'Dùng gần đây', LucideIcons.clock),
                  const SizedBox(width: 8),
                  _buildTabChip('suggest', 'Đề xuất', LucideIcons.sparkles),
                  const SizedBox(width: 8),
                  _buildTabChip('saved', 'Đã lưu', LucideIcons.bookmark),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 5. GPS Current Location Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: InkWell(
                onTap: () {
                  _selectAddress('P.1204 - Tòa S2.05, Vinhomes Grand Park');
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.locateFixed,
                          size: 18,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vị trí hiện tại (GPS)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Vinhomes Grand Park, P. Long Thạnh Mỹ, TP. Thủ Đức',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                        size: 18,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ],

          // 6. Dynamic Content Body (Autocomplete results OR Tabs)
          Expanded(
            child: _searchController.text.trim().isNotEmpty
                ? _buildSearchResults()
                : _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(String key, String label, IconData icon) {
    final isSelected = _activeTab == key;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _activeTab = key;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading && _searchResults.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Color(0xFF2563EB),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.mapPinOff,
                size: 40, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            const Text(
              'Không tìm thấy địa chỉ phù hợp',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Thử tìm theo số tòa (VD: S2.05) hoặc tên chung cư',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
      itemBuilder: (ctx, index) {
        final pred = _searchResults[index];
        return InkWell(
          onTap: () => _promptRoomNumberIfNeeded(pred),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.building,
                    size: 16,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              pred.primaryText,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (pred.tag != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                pred.tag!,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        pred.secondaryText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 200.ms);
      },
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 'saved':
        return _buildSavedTab();
      case 'suggest':
        return _buildSuggestTab();
      case 'recent':
      default:
        return _buildRecentTab();
    }
  }

  Widget _buildRecentTab() {
    if (_recentAddresses.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có địa chỉ gần đây',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      itemCount: _recentAddresses.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
      itemBuilder: (ctx, index) {
        final addr = _recentAddresses[index];
        return InkWell(
          onTap: () => _selectAddress(addr),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.history,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    addr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash2,
                      size: 16, color: Color(0xFF94A3B8)),
                  onPressed: () async {
                    await AddressService.removeRecentAddress(addr);
                    _loadRecentAddresses();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedTab() {
    AddressProvider? addrProv;
    try {
      addrProv = Provider.of<AddressProvider>(context);
    } catch (_) {}

    final realAddresses = addrProv?.addresses ?? [];

    if (realAddresses.isNotEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        itemCount: realAddresses.length + 1,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
        itemBuilder: (ctx, index) {
          if (index == realAddresses.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 14),
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddressListScreen()),
                  );
                },
                icon: const Icon(LucideIcons.settings, size: 16, color: Color(0xFF2563EB)),
                label: const Text(
                  'Quản lý sổ địa chỉ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFDBEAFE)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            );
          }

          final item = realAddresses[index];
          IconData icon = LucideIcons.home;
          if (item.label == 'Cơ quan') icon = LucideIcons.briefcase;
          if (item.label == 'Khác') icon = LucideIcons.mapPin;

          return InkWell(
            onTap: () => _selectAddress(item.fullAddress),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.isDefault
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 16, color: item.isDefault ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              item.recipientName.isNotEmpty ? item.recipientName : item.label,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            if (item.isDefault) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Mặc định',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.addressDetail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.chevronRight,
                      size: 16, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          );
        },
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      itemCount: _savedAddresses.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
      itemBuilder: (ctx, index) {
        final item = _savedAddresses[index];
        IconData icon = LucideIcons.bookmark;
        if (item['icon'] == 'home') icon = LucideIcons.home;
        if (item['icon'] == 'briefcase') icon = LucideIcons.briefcase;
        if (item['icon'] == 'building') icon = LucideIcons.building;

        return InkWell(
          onTap: () => _selectAddress(item['address']!),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: const Color(0xFF2563EB)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title']!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['address']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight,
                    size: 16, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestTab() {
    final suggestions = [
      'Tòa S2.05 - Vinhomes Grand Park',
      'Tòa S1.01 - Vinhomes Grand Park',
      'Tòa Masteri M2 - Masteri Centre Point',
      'Vincom Mega Mall Grand Park',
      'Tòa S7.01 - The Origami',
      'Tòa Landmark 81 - Bình Thạnh',
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      itemCount: suggestions.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
      itemBuilder: (ctx, index) {
        final item = suggestions[index];
        return InkWell(
          onTap: () => _selectAddress(item),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.sparkles,
                      size: 16, color: Color(0xFFD97706)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                const Icon(LucideIcons.arrowUpRight,
                    size: 16, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        );
      },
    );
  }
}
