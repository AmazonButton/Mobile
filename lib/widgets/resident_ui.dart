import 'package:flutter/material.dart';

const residentBlue = Color(0xFF2563EB);
const residentBackground = Color(0xFFF8FAFC);
const residentInk = Color(0xFF1E293B);
const residentMuted = Color(0xFF475569);

ThemeData residentTheme(BuildContext context) {
  final theme = Theme.of(context);
  return theme.copyWith(
    colorScheme: theme.colorScheme.copyWith(primary: residentBlue),
    appBarTheme: theme.appBarTheme.copyWith(
      backgroundColor: Colors.white,
      foregroundColor: residentInk,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      errorMaxLines: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: residentBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    ),
  );
}

class ResidentScaffold extends StatelessWidget {
  const ResidentScaffold({
    super.key,
    required this.appBar,
    required this.body,
    this.actions = const [],
  });

  final PreferredSizeWidget appBar;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Theme(
    data: residentTheme(context),
    child: Scaffold(
      backgroundColor: residentBackground,
      appBar: appBar,
      body: body,
      bottomNavigationBar: actions.isEmpty
          ? null
          : Material(
              color: Colors.white,
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: actions,
                ),
              ),
            ),
    ),
  );
}

class ResidentPanel extends StatelessWidget {
  const ResidentPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(17),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
}

class ResidentHero extends StatelessWidget {
  const ResidentHero({
    super.key,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
    this.strong = false,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final foreground = strong ? Colors.white : residentInk;
    final caption = strong ? const Color(0xFFDBEAFE) : residentMuted;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: strong ? const Color(0xFF1D4ED8) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(21),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResidentIcon(icon),
          const SizedBox(height: 12),
          Text(
            eyebrow,
            style: TextStyle(color: caption, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: foreground,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(description, style: TextStyle(color: caption)),
        ],
      ),
    );
  }
}

class ResidentIcon extends StatelessWidget {
  const ResidentIcon(this.icon, {super.key});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFDBEAFE),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: const Color(0xFF1D4ED8), size: 20),
  );
}

class ResidentBadge extends StatelessWidget {
  const ResidentBadge(
    this.label, {
    super.key,
    this.success = false,
    this.waiting = false,
  });
  final String label;
  final bool success;
  final bool waiting;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: success
          ? const Color(0xFFDCFCE7)
          : waiting
          ? const Color(0xFFFFF1D5)
          : const Color(0xFFDBEAFE),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: success
            ? const Color(0xFF166534)
            : waiting
            ? const Color(0xFF854D0E)
            : const Color(0xFF1E40AF),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class ResidentNotice extends StatelessWidget {
  const ResidentNotice(this.message, {super.key, this.error = false});
  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: error ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Text(
      message,
      style: TextStyle(
        color: error ? const Color(0xFF991B1B) : const Color(0xFF1E40AF),
      ),
    ),
  );
}

Future<bool?> showResidentConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = false,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: Colors.white,
  builder: (context) => Theme(
    data: residentTheme(context),
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: residentMuted)),
            const SizedBox(height: 16),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF991B1B),
                    )
                  : null,
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmLabel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(cancelLabel),
            ),
          ],
        ),
      ),
    ),
  ),
);
