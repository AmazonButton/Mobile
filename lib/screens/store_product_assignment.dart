import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../models/button_product_model.dart';
import '../providers/device_provider.dart';
import '../widgets/sample_a.dart';

class StoreProductAssignment extends StatefulWidget {
  final DeviceProvider provider;
  final String storeId, storeName;
  final ButtonProductModel product;
  final String? imageUrl;
  const StoreProductAssignment({
    super.key,
    required this.provider,
    required this.storeId,
    required this.storeName,
    required this.product,
    this.imageUrl,
  });
  @override
  State<StoreProductAssignment> createState() => _StoreProductAssignmentState();
}

class _StoreProductAssignmentState extends State<StoreProductAssignment> {
  late Future<List<DeviceModel>> _devices;
  DeviceModel? _selected;
  int _quantity = 1;
  bool _reviewing = false;
  @override
  void initState() {
    super.initState();
    _devices = _load();
  }

  Future<List<DeviceModel>> _load() async {
    await widget.provider.loadDevices().timeout(const Duration(seconds: 15));
    if (widget.provider.errorMessage != null) {
      throw StateError('Không thể tải nút');
    }
    return widget.provider.devices
        .where((d) => d.storeId == widget.storeId)
        .toList();
  }

  Future<void> _review() async {
    final selected = _selected;
    if (selected == null || _reviewing) return;
    setState(() => _reviewing = true);
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AssignmentReviewScreen(
          product: widget.product,
          device: selected,
          storeName: widget.storeName,
          quantity: _quantity,
          imageUrl: widget.imageUrl,
          onConfirm: () async {
            if (!widget.provider.devices.any(
              (d) => d.id == selected.id && d.storeId == widget.storeId,
            )) {
              throw StateError('Nút không còn thuộc cửa hàng này');
            }
            await widget.provider.updateDeviceProduct(
              selected.id,
              widget.product,
              quantity: _quantity,
            );
          },
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _reviewing = false);
    if (saved == true) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Gán sản phẩm vào nút', style: SampleA.section),
            const SizedBox(height: 12),
            Row(
              children: [
                AProductImage(
                  product: widget.product.name,
                  imageUrl: widget.imageUrl,
                  size: 64,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: SampleA.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.product.priceFormatted,
                        style: SampleA.body.copyWith(
                          color: SampleA.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(child: Text('Số lượng', style: SampleA.body)),
                IconButton(
                  tooltip: 'Giảm số lượng',
                  onPressed: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                  icon: const Icon(Icons.remove, color: SampleA.primary),
                ),
                Text('$_quantity', style: SampleA.body),
                IconButton(
                  tooltip: 'Tăng số lượng',
                  onPressed: () => setState(() => _quantity++),
                  icon: const Icon(Icons.add, color: SampleA.primary),
                ),
              ],
            ),
            const Divider(),
            Text(
              'Chỉ hiển thị nút thuộc ${widget.storeName}.',
              style: SampleA.caption,
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<DeviceModel>>(
              future: _devices,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Column(
                    children: [
                      const Text('Không thể tải nút bấm. Vui lòng thử lại.'),
                      TextButton(
                        onPressed: () => setState(() {
                          _selected = null;
                          _devices = _load();
                        }),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  );
                }
                final devices = snapshot.data ?? [];
                if (devices.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Bạn chưa sở hữu nút bấm của cửa hàng này.'),
                  );
                }
                return Column(
                  children: devices
                      .map(
                        (d) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: _selected?.id == d.id
                                ? SampleA.pale
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: SampleA.border),
                            ),
                            child: ListTile(
                              selected: _selected?.id == d.id,
                              leading: Icon(
                                _selected?.id == d.id
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: _selected?.id == d.id
                                    ? SampleA.primary
                                    : SampleA.muted,
                              ),
                              title: Text(
                                d.name,
                                style: SampleA.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                d.product == 'Chưa gán sản phẩm'
                                    ? d.product
                                    : 'Đang gán: ${d.product}',
                              ),
                              onTap: () => setState(() => _selected = d),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 12),
            AButton(
              label: 'Tiếp tục',
              onPressed: _selected == null || _reviewing ? null : _review,
            ),
          ],
        ),
      ),
    ),
  );
}

class AssignmentReviewScreen extends StatefulWidget {
  final ButtonProductModel product;
  final DeviceModel device;
  final String storeName;
  final int quantity;
  final String? imageUrl;
  final Future<void> Function() onConfirm;
  const AssignmentReviewScreen({
    super.key,
    required this.product,
    required this.device,
    required this.storeName,
    required this.quantity,
    required this.onConfirm,
    this.imageUrl,
  });
  @override
  State<AssignmentReviewScreen> createState() => _AssignmentReviewScreenState();
}

class _AssignmentReviewScreenState extends State<AssignmentReviewScreen> {
  bool _saving = false;
  String? _error;
  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onConfirm();
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Chưa thể gán sản phẩm. Vui lòng thử lại.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Kiểm tra thông tin'),
        backgroundColor: Colors.white,
      ),
      body: AContent(
        maxWidth: SampleA.detailWidth,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: AProductImage(
                product: widget.product.name,
                imageUrl: widget.imageUrl,
                size: 190,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.product.name,
              style: SampleA.title.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ACard(
              child: Column(
                children: [
                  _row('Cửa hàng', widget.storeName),
                  const Divider(),
                  _row('Nút được chọn', widget.device.name),
                  const Divider(),
                  _row('Số lượng', '${widget.quantity}'),
                  const Divider(),
                  _row(
                    'Giá hiện tại / sản phẩm',
                    widget.product.priceFormatted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const ACard(
              color: SampleA.pale,
              border: false,
              child: Text(
                'Thao tác này gán sản phẩm vào nút. Chưa tạo đơn hàng.',
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: SampleA.danger),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: AButton(
                  label: 'Xác nhận gán',
                  busy: _saving,
                  onPressed: _save,
                ),
              ),
              TextButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _row(String label, String value) =>
      AInfoRow(label: label, value: value);
}
