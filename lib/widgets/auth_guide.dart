import 'package:flutter/material.dart';

enum GuideMood { welcome, guiding, waiting, happy }

/// A local, vector-drawn Smart Order Button companion; no remote assets needed.
class AuthGuide extends StatelessWidget {
  final String message;
  final GuideMood mood;
  final bool large;

  const AuthGuide({
    super.key,
    required this.message,
    this.mood = GuideMood.guiding,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 280);
    final mascot = ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(mood),
        tween: Tween(begin: 0.92, end: 1),
        duration: duration,
        builder: (_, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: CustomPaint(
          size: Size.square(large ? 184 : 64),
          painter: _ButtonCompanionPainter(mood),
        ),
      ),
    );
    final bubble = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD7E5F2), width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        message,
        textAlign: large ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          fontSize: large ? 19 : 14,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF102A43),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: large
          ? Column(children: [bubble, const SizedBox(height: 16), mascot])
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                mascot,
                const SizedBox(width: 12),
                Expanded(child: bubble),
              ],
            ),
    );
  }
}

class _ButtonCompanionPainter extends CustomPainter {
  final GuideMood mood;
  _ButtonCompanionPainter(this.mood);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 160, size.height / 160);
    final blue = Paint()..color = const Color(0xFF1D5B9F);
    final orange = Paint()..color = const Color(0xFFF5862B);
    final white = Paint()..color = Colors.white;
    final ink = Paint()..color = const Color(0xFF102A43);
    canvas.drawOval(
      const Rect.fromLTWH(28, 140, 104, 12),
      Paint()..color = const Color(0xFFE3EDF7),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(42, 125, 28, 20),
        const Radius.circular(10),
      ),
      orange,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(90, 125, 28, 20),
        const Radius.circular(10),
      ),
      orange,
    );
    final arms = Paint()
      ..color = blue.color
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(28, 92), const Offset(12, 110), arms);
    final raised = mood == GuideMood.welcome || mood == GuideMood.happy;
    canvas.drawLine(
      const Offset(132, 90),
      Offset(149, raised ? 62 : 110),
      arms,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(25, 25, 110, 110),
        const Radius.circular(32),
      ),
      blue,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(33, 29, 94, 96),
        const Radius.circular(28),
      ),
      Paint()..color = const Color(0xFF4185C5),
    );
    canvas.drawCircle(const Offset(80, 42), 7, orange);
    for (final x in [59.0, 101.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 75), width: 25, height: 30),
        white,
      );
      canvas.drawCircle(
        Offset(x + (mood == GuideMood.guiding ? 3 : 0), 77),
        6,
        ink,
      );
      canvas.drawCircle(Offset(x + 2, 74), 2, white);
    }
    final smile = Paint()
      ..color = ink.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    if (mood == GuideMood.waiting) {
      canvas.drawCircle(const Offset(80, 104), 5, smile);
    } else {
      canvas.drawArc(
        const Rect.fromLTWH(67, 91, 26, 22),
        0.15,
        2.84,
        false,
        smile,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ButtonCompanionPainter oldDelegate) =>
      oldDelegate.mood != mood;
}

/// Avoid AnimatedSize's zero-duration layout mutation on reduced-motion devices.
class AuthStepSize extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final AlignmentGeometry alignment;
  final Curve curve;
  const AuthStepSize({
    super.key,
    required this.child,
    required this.duration,
    this.alignment = Alignment.center,
    this.curve = Curves.linear,
  });
  @override
  Widget build(BuildContext context) => MediaQuery.disableAnimationsOf(context)
      ? child
      : AnimatedSize(
          duration: duration,
          alignment: alignment,
          curve: curve,
          child: child,
        );
}
