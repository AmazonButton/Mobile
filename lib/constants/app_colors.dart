import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary = Color(0xFF1B3A5C);
  static const Color primaryDark = Color(0xFF0F2540);
  static const Color primaryLight = Color(0xFF2A5580);
  static const Color primaryUltraLight = Color(0xFFE8EFF6);

  // Accent (FPT Orange)
  static const Color accent = Color(0xFFF5862B);
  static const Color accentHover = Color(0xFFE07520);
  static const Color accentLight = Color(0xFFFFF3E8);
  static const Color accentGlow = Color(0x40F5862B);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFEFF6FF);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleLight = Color(0xFFF5F3FF);

  // Neutrals
  static const Color bgPage = Color(0xFFF8FAFC);
  static const Color bgCard = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textWhite = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);

  // Sidebar Gradient
  static const LinearGradient sidebarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1B3A5C), Color(0xFF0F2540)],
  );

  // Shadows
  static const List<BoxShadow> shadowSm = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(color: Color(0x12000000), blurRadius: 6, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> shadowLg = [
    BoxShadow(color: Color(0x14000000), blurRadius: 15, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> shadowXl = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 25, offset: Offset(0, 20)),
    BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, 8)),
  ];
}
