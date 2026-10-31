import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/stock_service.dart';
import '../sample_a.dart';
import 'a_stock_status.dart';

class DeviceCard extends StatelessWidget {
  final String id, name, room, product, price, badgeText, signal, state;
  final int batteryLevel;
  final String? imageUrl;
  final bool isOnline, showOrderButton;
  final VoidCallback? onTap, onSettings, onOrder;
  const DeviceCard({
    super.key,
    required this.id,
    required this.name,
    required this.room,
    required this.product,
    required this.price,
    required this.batteryLevel,
    this.imageUrl,
    this.badgeText = '20L',
    this.signal = 'Rất tốt',
    this.isOnline = true,
    this.onTap,
    this.onSettings,
    this.onOrder,
    this.state = 'idle',
    this.showOrderButton = true,
  });
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: StockService.instance,
    builder: (context, _) {
      final problem = StockService.instance.problem(id);
      return ACard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    AProductImage(
                      product: product,
                      imageUrl: imageUrl,
                      size: 48,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines:
                                MediaQuery.textScalerOf(context).scale(16) > 21
                                ? null
                                : 2,
                            overflow: TextOverflow.ellipsis,
                            style: SampleA.body.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(product, style: SampleA.caption),
                          const SizedBox(height: 6),
                          AStatus(
                            label: !isOnline
                                ? 'Mất kết nối'
                                : batteryLevel <= 20
                                ? 'Pin yếu · $batteryLevel%'
                                : 'Sẵn sàng',
                            icon: !isOnline
                                ? LucideIcons.wifiOff
                                : batteryLevel <= 20
                                ? LucideIcons.batteryLow
                                : LucideIcons.check,
                            color: !isOnline
                                ? SampleA.danger
                                : batteryLevel <= 20
                                ? SampleA.warning
                                : SampleA.primary,
                            background: !isOnline
                                ? SampleA.dangerLight
                                : batteryLevel <= 20
                                ? SampleA.warningLight
                                : SampleA.pale,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cài đặt $name',
                      onPressed: onSettings,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      icon: const Icon(
                        LucideIcons.settings,
                        size: 20,
                        color: SampleA.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final priceWidget = Text(price, style: SampleA.section);
                final action = AButton(
                  label: !isOnline ? 'Kết nối lại' : 'Đặt lại',
                  onPressed: !isOnline
                      ? onSettings
                      : problem == null
                      ? onOrder
                      : null,
                  kind: !isOnline ? AButtonKind.secondary : AButtonKind.primary,
                  busy: state == 'ordering',
                );
                return constraints.maxWidth < 250 ||
                        MediaQuery.textScalerOf(context).scale(16) > 21
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          priceWidget,
                          const SizedBox(height: 12),
                          action,
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: priceWidget),
                          const SizedBox(width: 12),
                          SizedBox(width: 128, child: action),
                        ],
                      );
              },
            ),
            if (isOnline)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: AStockStatus(deviceId: id),
              ),
          ],
        ),
      );
    },
  );
}
