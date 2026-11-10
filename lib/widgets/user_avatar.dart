import 'dart:io';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String initials;
  final String? url;
  final File? file;
  final double size;
  const UserAvatar({
    super.key,
    required this.initials,
    this.url,
    this.file,
    this.size = 44,
  });
  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: const Color(0xFFEFF6FF),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * .35,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2563EB),
          ),
        ),
      ),
    );
    final uri = Uri.tryParse(url ?? '');
    final valid =
        uri != null &&
        {'https', 'http'}.contains(uri.scheme) &&
        uri.host.isNotEmpty;
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: file != null
            ? Image.file(
                file!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              )
            : valid
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              )
            : fallback,
      ),
    );
  }
}
