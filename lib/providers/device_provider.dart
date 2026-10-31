import '../services/stock_service.dart';
import 'package:flutter/material.dart';
import '../models/button_product_model.dart';
import '../models/device_model.dart';
import '../services/devices_api_service.dart';

class DeviceProvider extends ChangeNotifier {
  final DevicesApiService _apiService;

  List<DeviceModel> _devices;
  bool _isLoading = false;
  String? _errorMessage;

  DeviceProvider({
    DevicesApiService? apiService,
    List<DeviceModel>? initialDevices,
  }) : _apiService = apiService ?? DevicesApiService(),
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
      await Future.wait(
        fetched.map((d) => StockService.instance.refreshDevice(d.id)),
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      // Nếu có lỗi kết nối, giữ lại danh sách thiết bị hiện tại nếu có
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Đổi cửa hàng và nhận lại cấu hình nút đã xóa sản phẩm cũ từ backend.
  Future<void> updateDeviceStore(String deviceId, String storeId) async {
    if (!_devices.any((device) => device.id == deviceId)) {
      throw StateError('Không tìm thấy thiết bị');
    }
    final response = await _apiService.updateCustomerConfig(
      deviceId,
      storeId: storeId,
    );
    final updated = DeviceModel.fromJson(response);
    final index = _devices.indexWhere((device) => device.id == deviceId);
    if (index == -1) return;
    _devices[index] = updated;
    notifyListeners();
  }

  /// Chỉ cập nhật sản phẩm trên giao diện sau khi backend xác nhận.
  Future<void> updateDeviceProduct(
    String deviceId,
    ButtonProductModel product, {
    int quantity = 1,
  }) async {
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index == -1) throw StateError('Không tìm thấy thiết bị');

    final response = await _apiService.updateCustomerConfig(
      deviceId,
      productId: product.id,
      quantity: quantity,
    );
    final currentIndex = _devices.indexWhere((d) => d.id == deviceId);
    if (currentIndex == -1) return;
    _devices[currentIndex] = DeviceModel.fromJson(response);
    await StockService.instance.refreshDevice(deviceId);
    notifyListeners();
  }

  /// Cập nhật sản phẩm tùy chỉnh (tên & giá) cho nút bấm (dùng cho gợi ý kệ hàng, chọn nhanh)
  Future<void> updateDeviceProductByName(
    String deviceId,
    String productName,
    String price, {
    String? badgeText,
  }) async {
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index == -1) return;

    final current = _devices[index];
    final badge =
        badgeText ??
        (productName.contains('Gas')
            ? '12kg'
            : (productName.contains('500ml') ||
                  productName.contains('chai') ||
                  productName.contains('lon'))
            ? '24 món'
            : '20L');

    final updated = current.copyWith(
      product: productName,
      price: price.endsWith('đ') ? price : '$priceđ',
      badgeText: badge,
    );

    _devices[index] = updated;
    notifyListeners();

    try {
      await _apiService.updateCustomerConfig(
        deviceId,
        buttonName: current.name,
      );
    } catch (_) {
      // Best-effort remote update
    }
  }

  /// Đổi tên sau khi máy chủ xác nhận, giữ nguyên cấu hình đặt hàng.
  Future<void> renameDevice(String deviceId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 100) {
      throw ArgumentError('Tên nút phải có từ 1 đến 100 ký tự');
    }
    if (getDeviceById(deviceId) == null) {
      throw StateError('Không tìm thấy thiết bị');
    }
    final response = await _apiService.updateCustomerConfig(
      deviceId,
      buttonName: trimmed,
    );
    final savedName = response['buttonName'] ?? response['name'] ?? response['customName'];
    if (savedName is! String || savedName.trim().isEmpty) {
      throw const FormatException('Phản hồi không có tên nút đã lưu');
    }
    final index = _devices.indexWhere((device) => device.id == deviceId);
    if (index == -1) return;
    _devices[index] = _devices[index].copyWith(name: savedName);
    notifyListeners();
  }

  /// Cập nhật tên và phòng của nút bấm
  Future<void> updateDeviceInfo(
    String deviceId, {
    String? name,
    String? room,
  }) async {
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
