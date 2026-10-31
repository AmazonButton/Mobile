import 'package:flutter/material.dart';
import '../services/stock_service.dart';

class DeviceStockStatus extends StatefulWidget {
  final String deviceId;
  const DeviceStockStatus({super.key, required this.deviceId});
  @override
  State<DeviceStockStatus> createState() => _DeviceStockStatusState();
}

class _DeviceStockStatusState extends State<DeviceStockStatus> {
  bool _loading = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
  }

  @override
  void didUpdateWidget(DeviceStockStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deviceId != widget.deviceId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refresh();
      });
    }
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() => _loading = true);
    await StockService.instance.refreshDevice(widget.deviceId);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: StockService.instance,
    builder: (context, _) {
      final service = StockService.instance;
      final items = service.configurations[widget.deviceId];
      final problem = service.problem(widget.deviceId);
      if (items != null && items.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (items != null && items.isNotEmpty)
            Text(
              'Số lượng mỗi lần đặt: ${items.first['quantity']}',
              style: const TextStyle(fontSize: 12),
            ),
          if (problem != null)
            Text(
              problem,
              style: const TextStyle(fontSize: 12, color: Colors.deepOrange),
            )
          else if (items != null)
            for (final item in items)
              Text(
                service.stock(item['productId'].toString())?.label() ??
                    'Chưa kiểm tra được tồn kho',
                style: const TextStyle(fontSize: 12),
              ),
          if (problem != null)
            TextButton(
              onPressed: _loading ? null : _refresh,
              child: Text(_loading ? 'Đang kiểm tra…' : 'Thử lại'),
            ),
        ],
      );
    },
  );
}
