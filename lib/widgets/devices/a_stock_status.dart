import 'package:flutter/material.dart';
import '../../services/stock_service.dart';
import '../sample_a.dart';

class AStockStatus extends StatefulWidget {
  final String deviceId;
  const AStockStatus({super.key, required this.deviceId});
  @override
  State<AStockStatus> createState() => _AStockStatusState();
}

class _AStockStatusState extends State<AStockStatus> {
  bool _loading = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
  }

  @override
  void didUpdateWidget(AStockStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deviceId != widget.deviceId) _refresh();
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
      final problem = StockService.instance.problem(widget.deviceId);
      if (problem == null ||
          StockService.instance.configurations[widget.deviceId]?.isEmpty ==
              true) {
        return const SizedBox.shrink();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            problem,
            style: SampleA.caption.copyWith(color: SampleA.warning),
          ),
          const SizedBox(height: 8),
          AButton(
            label: 'Kiểm tra tồn kho',
            busy: _loading,
            onPressed: _refresh,
            kind: AButtonKind.secondary,
          ),
        ],
      );
    },
  );
}
