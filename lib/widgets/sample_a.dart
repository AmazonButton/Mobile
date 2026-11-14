import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_colors.dart';

/// Colors shared by device and order components, matching the homepage palette.
abstract final class SampleA {
  static const fontFamily = 'SampleA Vietnam';
  static const spaceXs = 4.0,
      spaceSm = 8.0,
      spaceMd = 12.0,
      spaceLg = 16.0,
      spaceXl = 24.0,
      spaceXxl = 32.0;
  static const cardRadius = 20.0, buttonRadius = 16.0, sheetRadius = 24.0;
  static const detailWidth = 600.0, listWidth = 960.0, formWidth = 480.0;
  static const pagePadding = EdgeInsets.all(spaceLg);

  static const primary = AppColors.primary;
  static const primaryDark = AppColors.primaryDark;
  static const pale = Color(0xFFEFF6FF);
  static const ink = Color(0xFF0F172A);
  static const muted = AppColors.textSecondary;
  static const border = AppColors.border;
  static const background = AppColors.bgPage;
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFD97706);
  static const danger = Color(0xFFEF4444);
  static const dangerLight = Color(0xFFFEF2F2);
  static const warningLight = Color(0xFFFFFBEB);

  static const title = TextStyle(
    fontFamily: SampleA.fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    height: 1.25,
    color: ink,
    letterSpacing: -0.6,
  );
  static const section = TextStyle(
    fontFamily: SampleA.fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.35,
    color: ink,
  );
  static const body = TextStyle(
    fontFamily: SampleA.fontFamily,
    fontSize: 16,
    height: 1.4,
    color: ink,
  );
  static const caption = TextStyle(
    fontFamily: SampleA.fontFamily,
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
      borderRadius: BorderRadius.circular(SampleA.cardRadius),
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
        ? const Color(0xFFFECACA)
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
              borderRadius: BorderRadius.circular(SampleA.buttonRadius),
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
                  borderRadius: BorderRadius.circular(SampleA.buttonRadius),
                  side: BorderSide(color: edge, width: 2),
                ),
                textStyle: const TextStyle(
                  fontFamily: SampleA.fontFamily,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SampleA.buttonRadius),
      ),
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
              fontFamily: SampleA.fontFamily,
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
              borderRadius: BorderRadius.circular(SampleA.buttonRadius),
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
            fontFamily: SampleA.fontFamily,
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

/// Layout only: retains the child's scrolling, state and callbacks.
class AContent extends StatelessWidget {
  const AContent({
    super.key,
    required this.child,
    this.maxWidth = SampleA.detailWidth,
  });
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

class ASectionHeader extends StatelessWidget {
  const ASectionHeader({super.key, required this.title, this.action});
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final heading = Text(title, style: SampleA.section);
      if (action == null) return heading;
      if (constraints.maxWidth < 360 ||
          MediaQuery.textScalerOf(context).scale(16) > 22) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [heading, action!],
        );
      }
      return Row(
        children: [
          Expanded(child: heading),
          const SizedBox(width: SampleA.spaceSm),
          action!,
        ],
      );
    },
  );
}

/// One scroll owner, with space for the keyboard and system navigation.
class ASheetScroll extends StatelessWidget {
  const ASheetScroll({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AContent(
        child: SingleChildScrollView(
          padding: SampleA.pagePadding,
          child: child,
        ),
      ),
    ),
  );
}

/// A readable label/value pair; important values never ellipsize.
class AInfoRow extends StatelessWidget {
  const AInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.onCopy,
    this.highlight = false,
  });
  final String label, value;
  final VoidCallback? onCopy;
  final bool highlight;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: SampleA.spaceXs),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SampleA.caption),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                value,
                style: SampleA.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: highlight ? SampleA.primary : SampleA.ink,
                ),
              ),
            ),
            if (onCopy != null)
              IconButton(
                tooltip: 'Sao chép $label',
                onPressed: onCopy,
                icon: const Icon(LucideIcons.copy, size: 20),
              ),
          ],
        ),
      ],
    ),
  );
}
