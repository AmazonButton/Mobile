import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class DashboardFooter extends StatelessWidget {
  final Function(String link)? onLinkTap;

  const DashboardFooter({super.key, this.onLinkTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgPage,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 750;
          final paddingH = constraints.maxWidth < 600 ? 16.0 : 28.0;

          final links = Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _FooterLink(label: 'Trợ giúp', onTap: () => onLinkTap?.call('Trợ giúp')),
              _FooterLink(label: 'Chính sách', onTap: () => onLinkTap?.call('Chính sách')),
              _FooterLink(label: 'Liên hệ', onTap: () => onLinkTap?.call('Liên hệ')),
            ],
          );

          if (isNarrow) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/fpt_toggle_button.png',
                        height: 22,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.school_rounded,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          '© 2026 SmartOrderButton — FPT University',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  links,
                ],
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/fpt_toggle_button.png',
                        height: 22,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.school_rounded,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '© 2026 SmartOrderButton — FPT University. All rights reserved.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                links,
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FooterLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _FooterLink({required this.label, required this.onTap});

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _hovered ? AppColors.accent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
