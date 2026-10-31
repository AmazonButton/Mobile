import 'dart:async';
import '../../services/address_service.dart';
import '../../models/address_prediction.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/address_model.dart';
import '../../providers/address_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/address_api_service.dart';
import '../../services/goong_service.dart';

class AddressFormSheet extends StatefulWidget {
  final AddressModel? initialAddress;
  final Function(AddressModel savedAddress)? onSaved;

  const AddressFormSheet({super.key, this.initialAddress, this.onSaved});

  /// Phương thức tĩnh mở bottom sheet thêm/sửa địa chỉ tiện lợi
  static Future<AddressModel?> show(
    BuildContext context, {
    AddressModel? initialAddress,
    Function(AddressModel savedAddress)? onSaved,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<AddressModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          AddressFormSheet(initialAddress: initialAddress, onSaved: onSaved),
    );
  }

  @override
  State<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _detailController;
  late TextEditingController _wardController;
  late TextEditingController _districtController;
  late TextEditingController _provinceController;

  late bool _isDefault;
  late String _selectedLabel;
  bool _isSubmitting = false;

  final List<String> _labelOptions = ['Nhà riêng', 'Cơ quan', 'Khác'];

  Timer? _searchTimer;
  int _searchVersion = 0;
  bool _searching = false;
  String? _searchError;
  List<AddressPrediction> _predictions = [];

  void _searchAddress(String query) {
    _searchTimer?.cancel();
    final version = ++_searchVersion;
    setState(() {
      _predictions = [];
      _searchError = null;
      _searching = query.trim().length >= 2;
    });
    if (!_searching) return;
    _searchTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        final results = await AddressService.autocomplete(query);
        if (!mounted || version != _searchVersion) return;
        setState(() {
          _predictions = results.take(5).toList();
          _searching = false;
          if (results.isEmpty)
            _searchError =
                'Không tìm thấy gợi ý. Bạn có thể nhập địa chỉ thủ công.';
        });
      } catch (_) {
        if (!mounted || version != _searchVersion) return;
        setState(() {
          _searching = false;
          _searchError = const String.fromEnvironment('GOONG_API_KEY').isEmpty
              ? 'Chưa cấu hình tìm kiếm địa chỉ. Vui lòng khởi động lại ứng dụng với cấu hình Goong.'
              : 'Chưa tải được gợi ý. Bạn có thể nhập địa chỉ thủ công.';
        });
      }
    });
  }

  void _selectPrediction(AddressPrediction prediction) {
    _searchTimer?.cancel();
    ++_searchVersion;
    setState(() {
      _detailController.text = prediction.fullAddress;
      _wardController.clear();
      _districtController.clear();
      _provinceController.clear();
      _predictions = [];
      _searching = false;
      _searchError = null;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  void initState() {
    super.initState();
    final a = widget.initialAddress;

    // Lấy thông tin user hiện tại nếu là thêm mới
    String defaultName = '';
    String defaultPhone = '';
    try {
      final userProv = Provider.of<UserProvider>(context, listen: false);
      defaultName = userProv.name;
      defaultPhone = userProv.phone;
    } catch (_) {}

    _nameController = TextEditingController(
      text: a?.recipientName ?? (defaultName.isNotEmpty ? defaultName : ''),
    );
    _phoneController = TextEditingController(
      text: a?.phone ?? (defaultPhone.isNotEmpty ? defaultPhone : ''),
    );
    _detailController = TextEditingController(text: a?.addressDetail ?? '');
    _wardController = TextEditingController(text: a?.ward ?? '');
    _districtController = TextEditingController(text: a?.district ?? '');
    _provinceController = TextEditingController(text: a?.province ?? '');

    _isDefault = a?.isDefault ?? false;
    _selectedLabel = a?.label ?? 'Nhà riêng';
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    ++_searchVersion;
    _nameController.dispose();
    _phoneController.dispose();
    _detailController.dispose();
    _wardController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.initialAddress != null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.vibrate();
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final point = await GoongService().geocode(
      [
        _detailController.text,
        _wardController.text,
        _districtController.text,
        _provinceController.text,
      ].where((s) => s.trim().isNotEmpty).join(', '),
    );
    if (!mounted) return;
    final address = AddressModel(
      latitude: point?.$1,
      longitude: point?.$2,
      id: widget.initialAddress?.id ?? '',
      recipientName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      addressDetail: _detailController.text.trim(),
      ward: _wardController.text.trim(),
      district: _districtController.text.trim(),
      province: _provinceController.text.trim(),
      isDefault: _isDefault,
      label: _selectedLabel,
    );

    try {
      AddressProvider? provider;
      try {
        provider = Provider.of<AddressProvider>(context, listen: false);
      } catch (_) {}

      AddressModel? saved;
      if (provider != null) {
        if (_isEditing) {
          final ok = await provider.updateAddress(address);
          if (ok) saved = address;
        } else {
          saved = await provider.addAddress(address);
        }
      } else {
        // Fallback trực tiếp qua AddressService nếu không có provider
        saved = _isEditing
            ? await AddressApiService().updateAddress(address)
            : await AddressApiService().createAddress(address);
      }

      if (saved == null)
        throw Exception(provider?.errorMessage ?? "Không thể lưu địa chỉ");
      if (mounted) {
        widget.onSaved?.call(saved);
        Navigator.pop(context, saved);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu địa chỉ: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.90),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Modal Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _isEditing ? LucideIcons.pencil : LucideIcons.mapPin,
                          size: 18,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isEditing ? 'Sửa địa chỉ' : 'Thêm địa chỉ nhận hàng',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      LucideIcons.x,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFFF1F5F9), height: 24),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Nhãn địa chỉ (Home, Work, Other)
                      const Text(
                        'LOẠI ĐỊA CHỈ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: _labelOptions.map((label) {
                          final isSelected = _selectedLabel == label;
                          IconData iconData = LucideIcons.home;
                          if (label == 'Cơ quan')
                            iconData = LucideIcons.briefcase;
                          if (label == 'Khác') iconData = LucideIcons.mapPin;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              avatar: Icon(
                                iconData,
                                size: 14,
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF64748B),
                              ),
                              label: Text(label),
                              selected: isSelected,
                              selectedColor: const Color(0xFFEFF6FF),
                              backgroundColor: const Color(0xFFF8FAFC),
                              labelStyle: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF475569),
                              ),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFE2E8F0),
                                width: isSelected ? 1.5 : 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              onSelected: (val) {
                                if (val) setState(() => _selectedLabel = label);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // 2. Họ và tên người nhận
                      const Text(
                        'NGƯỜI NHẬN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _nameController,
                        hint: 'Họ và tên người nhận hàng',
                        prefixIcon: LucideIcons.user,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Vui lòng nhập tên người nhận';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // 3. Số điện thoại
                      const Text(
                        'SỐ ĐIỆN THOẠI',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _phoneController,
                        hint: 'Số điện thoại nhận hàng (10 số)',
                        prefixIcon: LucideIcons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Vui lòng nhập số điện thoại';
                          }
                          final clean = v.replaceAll(RegExp(r'\D'), '');
                          if (clean.length < 9 || clean.length > 11) {
                            return 'Số điện thoại không hợp lệ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // 4. Số phòng, Tòa nhà, Địa chỉ chi tiết
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'SỐ NHÀ / CĂN HỘ / TÒA NHÀ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'VD: P.1204 - Tòa S2.05',
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _detailController,
                        onChanged: _searchAddress,
                        hint: 'Nhập số phòng, tòa nhà, tên đường...',
                        prefixIcon: LucideIcons.building,
                        maxLines: 2,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Vui lòng nhập số nhà / căn hộ chi tiết';
                          }
                          return null;
                        },
                      ),

                      if (_searching)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: LinearProgressIndicator(),
                        ),
                      if (_searchError != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            _searchError!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      if (_predictions.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: _predictions
                                .map(
                                  (prediction) => ListTile(
                                    dense: true,
                                    leading: const Icon(
                                      Icons.location_on_outlined,
                                      color: Color(0xFF2563EB),
                                    ),
                                    title: Text(prediction.primaryText),
                                    subtitle: Text(prediction.secondaryText),
                                    onTap: () => _selectPrediction(prediction),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      const SizedBox(height: 20),

                      // 5. Phường / Xã, Quận / Huyện, Tỉnh / Thành
                      const Text(
                        'KHU VỰC HÀNH CHÍNH',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _wardController,
                        hint: 'Phường / Xã',
                        prefixIcon: LucideIcons.map,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _districtController,
                              hint: 'Quận / Huyện',
                              prefixIcon: LucideIcons.navigation,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              controller: _provinceController,
                              hint: 'Tỉnh / TP',
                              prefixIcon: LucideIcons.globe,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // 6. Đặt làm mặc định toggle
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  LucideIcons.checkCircle2,
                                  size: 18,
                                  color: Color(0xFF2563EB),
                                ),
                                SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Đặt làm địa chỉ mặc định',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Ưu tiên khi bấm nút đặt hàng',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Switch(
                              value: _isDefault,
                              activeThumbColor: const Color(0xFF2563EB),
                              onChanged: (val) {
                                setState(() => _isDefault = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            disabledBackgroundColor: const Color(0xFF94A3B8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  _isEditing
                                      ? 'Cập nhật địa chỉ'
                                      : 'Lưu địa chỉ mới',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          icon: Icon(prefixIcon, size: 18, color: const Color(0xFF64748B)),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          errorStyle: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
        ),
      ),
    );
  }
}
