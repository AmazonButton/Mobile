import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_colors.dart';

/// Visual tokens scoped to the replacement screens, so Home keeps its styling.
abstract final class SampleA {
  static const primary = AppColors.primary;
  static const primaryDark = AppColors.primaryDark;
  static const pale = AppColors.primaryUltraLight;
  static const ink = AppColors.textPrimary;
  static const muted = AppColors.textSecondary;
  static const border = AppColors.border;
  static const background = Colors.white;
  static const success = Color(0xFF216B45);
  static const warning = Color(0xFF925B09);
  static const danger = Color(0xFFB33B2E);
  static const dangerLight = Color(0xFFFFF0EC);
  static const warningLight = Color(0xFFFFF5DF);

  static const title = TextStyle(
    fontFamily: 'SampleA Vietnam',
    fontSize: 26,
    fontWeight: FontWeight.w800,
    height: 1.25,
    color: ink,
    letterSpacing: -0.6,
  );
  static const section = TextStyle(
    fontFamily: 'SampleA Vietnam',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.35,
    color: ink,
  );
  static const body = TextStyle(
    fontFamily: 'SampleA Vietnam',
    fontSize: 16,
    height: 1.4,
    color: ink,
  );
  static const caption = TextStyle(
    fontFamily: 'SampleA Vietnam',
    fontSize: 14,
    height: 1.4,
    color: muted,
  );
}

class ACard extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final bool border;
  const ACard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(12),
    this.border = true,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: border ? Border.all(color: SampleA.border, width: 2) : null,
    ),
    child: child,
  );
}

enum AButtonKind { primary, secondary, danger }

class AButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AButtonKind kind;
  final IconData? icon;
  final bool busy;
  const AButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = AButtonKind.primary,
    this.icon,
    this.busy = false,
  });
  @override
  State<AButton> createState() => _AButtonState();
}

class _AButtonState extends State<AButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final primary = widget.kind == AButtonKind.primary;
    final danger = widget.kind == AButtonKind.danger;
    final enabled = widget.onPressed != null && !widget.busy;
    final foreground = primary
        ? Colors.white
        : danger
        ? SampleA.danger
        : SampleA.primary;
    final background = !enabled
        ? SampleA.border
        : primary
        ? SampleA.primary
        : danger
        ? SampleA.dangerLight
        : Colors.white;
    final edge = primary
        ? SampleA.primaryDark
        : danger
        ? const Color(0xFFE7C7C0)
        : SampleA.border;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Listener(
        onPointerDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: Transform.translate(
          offset: Offset(0, _pressed && enabled ? 4 : 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: _pressed || !enabled
                  ? []
                  : [BoxShadow(color: edge, offset: const Offset(0, 4))],
            ),
            child: FilledButton(
              onPressed: enabled
                  ? () {
                      HapticFeedback.lightImpact();
                      widget.onPressed!();
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: background,
                disabledBackgroundColor: background,
                foregroundColor: foreground,
                disabledForegroundColor: SampleA.muted,
                minimumSize: const Size(48, 48),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: edge, width: 2),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'SampleA Vietnam',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.busy) ...[
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                  ] else if (widget.icon != null) ...[
                    Icon(widget.icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(widget.label, textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  const AIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });
  @override
  Widget build(BuildContext context) => IconButton.outlined(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon, size: 24),
    style: IconButton.styleFrom(
      foregroundColor: SampleA.primary,
      minimumSize: const Size(48, 48),
      side: const BorderSide(color: SampleA.border, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

class AStatus extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color background;
  const AStatus({
    super.key,
    required this.label,
    required this.icon,
    this.color = SampleA.primary,
    this.background = SampleA.pale,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'SampleA Vietnam',
              fontSize: 14,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
}

class AProductImage extends StatelessWidget {
  final String product;
  final String? imageUrl;
  final double size;
  const AProductImage({
    super.key,
    required this.product,
    this.imageUrl,
    this.size = 64,
  });
  @override
  Widget build(BuildContext context) {
    final water = RegExp(
      r'nước|lavie|aquafina|water',
      caseSensitive: false,
    ).hasMatch(product);
    final fallback = water
        ? Image.asset(
            'assets/sample_a/water.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
          )
        : Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: SampleA.pale,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 30,
              color: SampleA.primary,
            ),
          );
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl == null || imageUrl!.isEmpty
            ? fallback
            : CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.contain,
                placeholder: (_, _) => fallback,
                errorWidget: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

class ABuddy extends StatelessWidget {
  final double size;
  const ABuddy({super.key, this.size = 120});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(
      'assets/sample_a/buddy.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    ),
  );
}

class SampleANavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  const SampleANavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: SampleA.border)),
    ),
    child: NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: SampleA.pale,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: 'SampleA Vietnam',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? SampleA.primary
                : SampleA.muted,
          ),
        ),
        iconTheme: const WidgetStatePropertyAll(
          IconThemeData(color: SampleA.primary, size: 24),
        ),
      ),
      child: NavigationBar(
        height: 76,
        elevation: 0,
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.house),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.slidersHorizontal),
            label: 'Thiết bị',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.receiptText),
            label: 'Đơn hàng',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.userRound),
            label: 'Tài khoản',
          ),
        ],
      ),
    ),
  );
}
