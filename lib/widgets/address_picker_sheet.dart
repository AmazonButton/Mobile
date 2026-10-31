import 'package:flutter/material.dart';
import '../models/address_model.dart';
import '../screens/address/address_list_screen.dart';

class AddressPickerSheet extends StatelessWidget {
  final Function(String)? onAddressSelected;
  const AddressPickerSheet({super.key, this.onAddressSelected});
  static Future<String?> show(
    BuildContext context, {
    Function(String)? onAddressSelected,
  }) async {
    final address = await Navigator.of(context).push<AddressModel>(
      MaterialPageRoute(
        builder: (_) => const AddressListScreen(selectMode: true),
      ),
    );
    if (address == null) return null;
    onAddressSelected?.call(address.fullAddress);
    return address.fullAddress;
  }

  @override
  Widget build(BuildContext context) =>
      const AddressListScreen(selectMode: true);
}
