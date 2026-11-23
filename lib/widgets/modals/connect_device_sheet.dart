import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/device_provider.dart';
import '../../services/api_client.dart';
import '../../services/ble_pairing_bridge.dart';
import '../../services/devices_api_service.dart';
import '../sample_a.dart';
import '../smart_order_tour.dart';
import 'wifi_provisioning_sheet.dart';

class ConnectDeviceSheet extends StatefulWidget {
  const ConnectDeviceSheet({super.key, this.tour});
  final SmartOrderTour? tour;

  static Future<bool?> showAndRefresh(
    BuildContext context, {
    SmartOrderTour? tour,
  }) async {
    final provider = context.read<DeviceProvider?>();
    final saved = await show(context, tour: tour);
    if (saved == true && context.mounted) {
      await provider?.refreshDevices();
    }
    return saved;
  }

  static Future<bool?> show(BuildContext context, {SmartOrderTour? tour}) =>
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => ConnectDeviceSheet(tour: tour),
      );

  @override
  State<ConnectDeviceSheet> createState() => _ConnectDeviceSheetState();
}

class _ConnectDeviceSheetState extends State<ConnectDeviceSheet> {
  static const _draftKey = 'sob_last_pairing_device_code';
  static const _brandBlue = Color(0xFF287DA8);

  final _code = TextEditingController();
  final _pairToken = TextEditingController();

  int _step = 1; // 1: Nhận diện nút, 2: Xác nhận & cấu hình, 3: Đã lưu trên hệ thống
  bool _busy = false;
  bool _bleScanning = false;
  String? _error;
  String? _notice;

  String? _identifiedDeviceId;
  bool _isClaimed = false;
  bool _viaBle = false;
  bool _wifiConfigured = false;
  String? _configuredSsid;
  Map<String, dynamic>? _lookupData;
  BluetoothDevice? _connectedBleDevice;

  // Danh sách thiết bị BLE thật phát hiện trên Android/iOS
  final List<Map<String, dynamic>> _nativeBleDevices = [];
  StreamSubscription<List<ScanResult>>? _bleScanSub;

  @override
  void initState() {
    super.initState();
    _loadDraftCode();
  }

  Future<void> _loadDraftCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_draftKey);
      if (saved != null && saved.trim().isNotEmpty && mounted) {
        _code.text = saved.trim();
      }
    } catch (_) {}
  }

  Future<void> _saveDraftCode(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_draftKey, code.trim());
    } catch (_) {}
  }

  @override
  void dispose() {
    _bleScanSub?.cancel();
    if (!kIsWeb) {
      try {
        FlutterBluePlus.stopScan();
      } catch (_) {}
      try {
        _connectedBleDevice?.disconnect();
      } catch (_) {}
    } else {
      disconnectWebBle();
    }
    _code.dispose();
    _pairToken.dispose();
    super.dispose();
  }

  /// Bước 1A: Khôi phục / kiểm tra ghép nối đã gửi
  Future<void> _restoreOrCheckPairing() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = (_code.text.trim().isNotEmpty
              ? _code.text.trim()
              : (prefs.getString(_draftKey) ?? ''))
          .trim();

      if (savedCode.isNotEmpty) {
        _code.text = savedCode;
        await _verifyCodeOnServer(savedCode, viaBle: _viaBle);
        return;
      }

      // Nếu chưa có mã lưu sẵn, tải lại danh sách nút của tài khoản từ hệ thống
      final devices = await DevicesApiService().getDevices();
      if (!mounted) return;
      if (devices.isNotEmpty) {
        setState(() {
          _notice =
              'Tài khoản đang có ${devices.length} nút bấm đã đồng bộ trên hệ thống. Bấm "Tìm & kết nối Bluetooth" hoặc nhập mã nút để kiểm tra.';
        });
      } else {
        setState(() {
          _notice =
              'Chưa có phiên ghép nối nào được lưu trước đó. Hãy bấm "Tìm & kết nối Bluetooth" để quét nút của bạn.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException
              ? e.message
              : 'Không thể khôi phục phiên ghép nối lúc này.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Bước 1B: Tìm & kết nối Bluetooth THẬT (Web Bluetooth trên Web, FlutterBluePlus trên Android/iOS)
  Future<void> _startBluetoothConnect() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });

    try {
      if (kIsWeb) {
        // Gọi trực tiếp Web Bluetooth API của trình duyệt (Chrome/Edge) để mở hộp thoại chọn thiết bị ESP32 thật
        final foundId = await scanWebBleDevice();
        if (!mounted) return;
        if (foundId == null || foundId.isEmpty) {
          setState(() {
            _busy = false;
            _notice = 'Bạn đã đóng hộp thoại chọn thiết bị Bluetooth.';
          });
          return;
        }
        _code.text = foundId;
        await _saveDraftCode(foundId);
        await _verifyCodeOnServer(foundId, viaBle: true);
      } else {
        // Android / iOS: Quét BLE thật qua FlutterBluePlus
        final supported = await FlutterBluePlus.isSupported;
        if (!supported) {
          throw StateError('Thiết bị này không hỗ trợ Bluetooth Low Energy (BLE).');
        }
        await _bleScanSub?.cancel();
        setState(() {
          _bleScanning = true;
          _nativeBleDevices.clear();
          _busy = false;
          _notice =
              'Đang quét sóng Bluetooth quanh đây... Hãy bấm nhanh 5 lần vào nút để bật chế độ phát sóng (LED nháy xanh).';
        });

        final seen = <String, Map<String, dynamic>>{};
        _bleScanSub = FlutterBluePlus.scanResults.listen((results) {
          var changed = false;
          for (final r in results) {
            final advName = r.advertisementData.advName.trim();
            final pName = r.device.platformName.trim();
            final name = advName.isNotEmpty ? advName : pName;
            final upper = name.toUpperCase();
            final hasPrefix = upper.startsWith('BTN') ||
                upper.startsWith('SMARTORDER') ||
                upper.startsWith('SMARTBUTTON') ||
                upper.startsWith('ESP') ||
                upper.startsWith('SOB');
            final hasService = r.advertisementData.serviceUuids.any(
              (u) => u.toString().toLowerCase().contains('fff0'),
            );
            if (hasPrefix || hasService) {
              final key = r.device.remoteId.str;
              seen[key] = {
                'deviceId': name.isNotEmpty ? name : key,
                'name': name.isNotEmpty ? name : 'SmartOrder Button ($key)',
                'rssi': r.rssi,
                'bleDevice': r.device,
              };
              changed = true;
            }
          }
          if (changed && mounted) {
            setState(() {
              _nativeBleDevices
                ..clear()
                ..addAll(seen.values);
            });
          }
        });

        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
        if (mounted) {
          setState(() {
            _bleScanning = false;
            if (_nativeBleDevices.isEmpty) {
              _error =
                  'Chưa tìm thấy nút bấm Bluetooth nào gần đây. Hãy đảm bảo đã bật Bluetooth và bấm nhanh 5 lần vào nút vật lý.';
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _bleScanning = false;
          _error = e.toString().replaceFirst('Exception: ', '').replaceFirst('Bad state: ', '');
        });
      }
    }
  }

  /// Kết nối trực tiếp vào 1 thiết bị BLE thật tìm thấy trên Android/iOS, đọc GATT FFF1
  Future<void> _connectNativeBleDevice(BluetoothDevice bleDevice, String fallbackName) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = 'Đang kết nối Bluetooth và đọc mã thiết bị thật từ phần cứng...';
    });

    try {
      await FlutterBluePlus.stopScan();
      await bleDevice.connect(timeout: const Duration(seconds: 6));
      _connectedBleDevice = bleDevice;

      var realCode = fallbackName;
      final services = await bleDevice.discoverServices();
      for (final s in services) {
        if (s.uuid.toString().toLowerCase().contains('fff0')) {
          for (final c in s.characteristics) {
            if (c.uuid.toString().toLowerCase().contains('fff1')) {
              final bytes = await c.read();
              final text = utf8.decode(bytes).trim();
              if (text.isNotEmpty) {
                try {
                  final decoded = json.decode(text);
                  if (decoded is Map && decoded['deviceId'] != null) {
                    realCode = decoded['deviceId'].toString().trim();
                  } else {
                    realCode = text;
                  }
                } catch (_) {
                  realCode = text;
                }
              }
            }
          }
        }
      }

      _code.text = realCode;
      await _saveDraftCode(realCode);
      await _verifyCodeOnServer(realCode, viaBle: true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Không thể đọc dữ liệu từ nút Bluetooth: $e';
        });
      }
    }
  }

  /// Bước 1C: Đối chiếu mã nút với Backend (POST /devices/lookup-code)
  Future<void> _verifyCodeOnServer(String rawCode, {bool viaBle = false}) async {
    final code = rawCode.trim();
    if (code.isEmpty) {
      setState(() {
        _busy = false;
        _error = 'Vui lòng nhập mã nút bấm hoặc bấm "Tìm & kết nối Bluetooth".';
      });
      return;
    }

    widget.tour?.setBusy(true);
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _saveDraftCode(code);
      Map<String, dynamic> lookup;
      try {
        lookup = await DevicesApiService().lookupCode(code);
      } catch (e) {
        // Nếu đã đọc thật qua Bluetooth nhưng nút chưa đăng ký hoặc lỗi lookup,
        // vẫn báo rõ cho người dùng biết mã thật vừa đọc được từ phần cứng.
        if (viaBle) {
          if (!mounted) return;
          widget.tour?.setBusy(false);
          setState(() {
            _busy = false;
            _identifiedDeviceId = code;
            _viaBle = true;
            _isClaimed = false;
            _lookupData = {'deviceId': code};
            _step = 2;
            _notice =
                'Đã đọc mã thật $code qua Bluetooth. Bạn có thể nạp Wi-Fi 2.4GHz trực tiếp cho nút hoặc kiểm tra lại trên hệ thống.';
          });
          return;
        }
        rethrow;
      }

      final verifiedId = lookup['deviceId']?.toString().trim().isNotEmpty == true
          ? lookup['deviceId'].toString().trim()
          : code;

      if (!mounted) return;
      widget.tour?.setBusy(false);
      setState(() {
        _busy = false;
        _identifiedDeviceId = verifiedId;
        _isClaimed = lookup['isClaimed'] == true;
        _viaBle = viaBle;
        _lookupData = lookup;
        _step = 2;
        _notice = viaBle
            ? 'Đã đọc mã thật $verifiedId qua Bluetooth và đối chiếu thành công trên hệ thống.'
            : 'Đã tìm thấy nút $verifiedId trên hệ thống. Xác nhận cấu hình để hoàn tất.';
      });
    } catch (e) {
      widget.tour?.setBusy(false);
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e is ApiException
              ? e.message
              : e is StateError
                  ? e.message.toString()
                  : 'Không tìm thấy mã nút trên hệ thống. Vui lòng kiểm tra lại mã.';
        });
      }
    }
  }

  /// Bước 2A: Mở bảng nạp Wi-Fi 2.4GHz qua BLE thật (GATT FFF2)
  Future<void> _openWifiProvisioning() async {
    final id = _identifiedDeviceId ?? _code.text.trim();
    await WifiProvisioningSheet.show(
      context: context,
      initialSsid: _configuredSsid ?? '',
      deviceId: id,
      bleDevice: _connectedBleDevice,
      onConnected: (newSsid) {
        if (!mounted) return;
        setState(() {
          _wifiConfigured = true;
          _configuredSsid = newSsid;
          _notice = 'Đã gửi cấu hình Wi-Fi "$newSsid" tới nút $id qua Bluetooth!';
        });
      },
    );
  }

  /// Bước 2B: Xác nhận & lưu nút lên hệ thống → Bước 3
  Future<void> _confirmAndSaveDevice() async {
    final id = _identifiedDeviceId ?? _code.text.trim();
    if (id.isEmpty || _busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (!_isClaimed) {
        final payload = <String, dynamic>{'code': id};
        if (_pairToken.text.trim().isNotEmpty) {
          payload['pairingCode'] = _pairToken.text.trim();
        }
        try {
          await DevicesApiService().configureByCode(payload);
        } catch (e) {
          // Nếu nút đã gán sẵn hoặc chỉ cấu hình Wi-Fi qua BLE, tiếp tục đồng bộ
          debugPrint('[ConnectDeviceSheet] configureByCode note: $e');
          if (!_viaBle && !_wifiConfigured) rethrow;
        }
      }

      try {
        await DevicesApiService().getDeviceModelById(id);
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _busy = false;
        _step = 3;
        _notice = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e is ApiException
              ? e.message
              : 'Không thể lưu thiết bị lên hệ thống. Vui lòng kiểm tra lại mã ghép nối.';
        });
      }
    }
  }

  Widget _buildStepPill(int index, String label) {
    final active = _step == index;
    final done = _step > index;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFE0F2FE)
            : done
                ? const Color(0xFFECFDF5)
                : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active
              ? _brandBlue.withValues(alpha: 0.35)
              : done
                  ? const Color(0xFF10B981).withValues(alpha: 0.35)
                  : Colors.transparent,
        ),
      ),
      child: Text(
        '$index. $label',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: active || done ? FontWeight.w700 : FontWeight.w600,
          color: active
              ? _brandBlue
              : done
                  ? const Color(0xFF047857)
                  : const Color(0xFF64748B),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_busy,
        child: ASheetScroll(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header matching Web "Kết nối nút bấm thông minh"
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kết nối nút bấm thông minh',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Đọc mã thật trên nút và đối chiếu với hệ thống.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _busy ? null : () => Navigator.pop(context, _step == 3),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        size: 18,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3 Step Pills
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStepPill(1, 'Nhận diện nút'),
                  _buildStepPill(2, 'Xác nhận & cấu hình'),
                  _buildStepPill(3, 'Đã lưu trên hệ thống'),
                ],
              ),
              const SizedBox(height: 18),

              // Notice banner
              if (_notice != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(LucideIcons.info, size: 17, color: _brandBlue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _notice!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF0C4A6E),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Error banner
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(LucideIcons.alertCircle, size: 17, color: Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFFDC2626),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ================= STEP 1: NHẬN DIỆN NÚT =================
              if (_step == 1) ...[
                // Secondary button: Khôi phục / kiểm tra ghép nối đã gửi
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: _busy ? null : _restoreOrCheckPairing,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E293B),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    child: const Text(
                      'Khôi phục / kiểm tra ghép nối đã gửi',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Primary CTA: Tìm & kết nối Bluetooth
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: (_busy || _bleScanning) ? null : _startBluetoothConnect,
                    icon: (_busy || _bleScanning)
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(LucideIcons.bluetooth, size: 19),
                    label: Text(
                      _bleScanning
                          ? 'Đang quét sóng Bluetooth...'
                          : _busy
                              ? 'Đang kết nối Bluetooth...'
                              : 'Tìm & kết nối Bluetooth',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                // Native Android/iOS real BLE scan results
                if (!kIsWeb && _nativeBleDevices.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Thiết bị Bluetooth phát hiện quanh đây:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._nativeBleDevices.map((dev) {
                    final bleDev = dev['bleDevice'] as BluetoothDevice;
                    final dName = dev['name'] as String;
                    final dId = dev['deviceId'] as String;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.45)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              LucideIcons.bluetoothConnected,
                              color: Color(0xFF059669),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'Sóng: ${dev['rssi']} dBm',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _busy
                                ? null
                                : () => _connectNativeBleDevice(bleDev, dId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _brandBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Kết nối',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 18),
                const Text(
                  'Hoặc kiểm tra mã nút đã có',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: widget.tour?.key(TourStep.code),
                  controller: _code,
                  onChanged: (value) => widget.tour?.codeChanged(value),
                  enabled: !_busy,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (val) => _verifyCodeOnServer(val, viaBle: false),
                  decoration: InputDecoration(
                    hintText: 'Nhập mã nút (VD: SOB-000003)',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _brandBlue, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    key: widget.tour?.key(TourStep.connect),
                    onPressed: _busy ? null : () => _verifyCodeOnServer(_code.text, viaBle: false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text(
                      'Kiểm tra nút trên hệ thống',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],

              // ================= STEP 2: XÁC NHẬN & CẤU HÌNH =================
              if (_step == 2) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(LucideIcons.cpu, color: _brandBlue, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _identifiedDeviceId ?? _code.text.trim(),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _viaBle
                                      ? 'Đã kết nối Bluetooth thật • Sẵn sàng nạp Wi-Fi'
                                      : _isClaimed
                                          ? 'Đã thuộc tài khoản của bạn trên hệ thống'
                                          : 'Sẵn sàng ghép nối vào tài khoản',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_lookupData?['storeName'] != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Cửa hàng: ${_lookupData!['storeName']}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Nạp Wi-Fi 2.4GHz qua BLE
                OutlinedButton.icon(
                  onPressed: _busy ? null : _openWifiProvisioning,
                  icon: Icon(
                    _wifiConfigured ? LucideIcons.checkCircle2 : LucideIcons.wifi,
                    size: 18,
                    color: _wifiConfigured ? const Color(0xFF059669) : _brandBlue,
                  ),
                  label: Text(
                    _wifiConfigured
                        ? 'Đã nạp Wi-Fi: $_configuredSsid (Đổi mạng khác)'
                        : 'Cấu hình Wi-Fi 2.4GHz qua Bluetooth',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: BorderSide(
                      color: _wifiConfigured
                          ? const Color(0xFF10B981)
                          : _brandBlue.withValues(alpha: 0.45),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _step = 1;
                                _error = null;
                                _notice = null;
                              }),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF475569),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Quay lại'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _busy ? null : _confirmAndSaveDevice,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brandBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Xác nhận & lưu thiết bị',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // ================= STEP 3: ĐÃ LƯU TRÊN HỆ THỐNG =================
              if (_step == 3) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        LucideIcons.checkCircle2,
                        size: 44,
                        color: Color(0xFF059669),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Đã lưu nút bấm trên hệ thống!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF065F46),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mã thiết bị: ${_identifiedDeviceId ?? _code.text.trim()}${_configuredSsid != null ? ' • Wi-Fi: $_configuredSsid' : ''}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF047857),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Hoàn tất',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}
