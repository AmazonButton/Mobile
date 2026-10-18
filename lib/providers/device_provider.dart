import 'package:flutter/material.dart';
import '../models/button_product_model.dart';
import '../models/device_model.dart';
import '../services/devices_api_service.dart';

class DeviceProvider extends ChangeNotifier {
  final DevicesApiService _apiService;

  List<DeviceModel> _devices;
  bool _isLoading = false;
  String? _errorMessage;

  DeviceProvider({DevicesApiService? apiService, List<DeviceModel>? initialDevices})
      : _apiService = apiService ?? DevicesApiService(),
        _devices = initialDevices ?? List.from(DeviceModel.sampleDevices);

  List<DeviceModel> get devices => List.unmodifiable(_devices);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DeviceModel? getDeviceById(String id) {
    try {
      return _devices.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Tải danh sách thiết bị từ backend
  Future<void> loadDevices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _apiService.getDevices();
      _devices = fetched;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      // Nếu có lỗi kết nối, giữ lại danh sách thiết bị hiện tại nếu có
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cập nhật sản phẩm gán cho nút bấm và đồng bộ ngay lập tức sang các màn hình
  Future<void> updateDeviceProduct(String deviceId, ButtonProductModel product) async {
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index == -1) return;

    final current = _devices[index];
    final badge = product.shortName.contains('Gas')
        ? '12kg'
        : product.shortName.contains('500ml')
            ? '24 chai'
            : '20L';

    final updated = current.copyWith(
      product: product.shortName,
      price: product.priceFormatted,
      badgeText: badge,
    );

    _devices[index] = updated;
    notifyListeners();

    try {
      await _apiService.updateCustomerConfig(
        deviceId,
        productId: product.id,
      );
    } catch (_) {
      // Best-effort remote update
    }
  }

  /// Cập nhật tên và phòng của nút bấm
  Future<void> updateDeviceInfo(String deviceId, {String? name, String? room}) async {
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index == -1) return;

    final current = _devices[index];
    final updated = current.copyWith(
      name: name ?? current.name,
      room: room ?? current.room,
    );

    _devices[index] = updated;
    notifyListeners();

    try {
      await _apiService.updateCustomerConfig(
        deviceId,
        buttonName: name,
        roomLocation: room,
      );
    } catch (_) {
      // Best-effort remote update
    }
  }

  /// Làm mới danh sách thiết bị
  Future<void> refreshDevices() => loadDevices();
}
