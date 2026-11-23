import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_motion.dart';

enum GuideMood { welcome, guiding, waiting, happy }

/// A local, vector-drawn Smart Order Button companion with calm 60fps ambient
/// breathing/waving motion, natural blink, and smooth mood transitions.
class AuthGuide extends StatefulWidget {
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
  State<AuthGuide> createState() => _AuthGuideState();
}

class _AuthGuideState extends State<AuthGuide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.allowAmbient(context)) {
      if (!_ambientController.isAnimating) {
        _ambientController.repeat();
      }
    } else {
      _ambientController.stop();
      _ambientController.value = 0;
    }
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final ambient = AppMotion.allowAmbient(context);
    final duration = reducedMotion
        ? Duration.zero
        : const Duration(milliseconds: 260);
    final size = widget.large ? 184.0 : 66.0;

    final mascot = ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(widget.mood),
        tween: Tween(begin: 0.94, end: 1.0),
        duration: duration,
        curve: AppMotion.easeOut,
        builder: (_, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: AnimatedBuilder(
          animation: _ambientController,
          builder: (context, _) {
            final phase = ambient ? _ambientController.value : 0.0;
            final rad = phase * math.pi * 2;
            final bobY = ambient ? math.sin(rad) * (widget.large ? 4.5 : 2.0) : 0.0;
            final wave = ambient ? math.sin(rad * 2) : 0.0;
            // Subtle natural blink near end of cycle
            final blink = ambient && phase > 0.88 && phase < 0.94;
            final auraScale = 0.95 + (math.sin(rad) * 0.05);

            return SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.large)
                    Transform.scale(
                      scale: auraScale,
                      child: Container(
                        width: size * 0.86,
                        height: size * 0.86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF0E6BA8).withValues(alpha: 0.14),
                              const Color(0xFF38BDF8).withValues(alpha: 0.04),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  Transform.translate(
                    offset: Offset(0, bobY),
                    child: CustomPaint(
                      size: Size.square(size),
                      painter: _ButtonCompanionPainter(
                        widget.mood,
                        wave: wave,
                        blink: blink,
                        floatFactor: ambient ? (math.sin(rad) + 1) * 0.5 : 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    final bubble = AnimatedContainer(
      duration: duration,
      curve: AppMotion.easeOut,
      padding: EdgeInsets.symmetric(
        horizontal: widget.large ? 20 : 14,
        vertical: widget.large ? 15 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: widget.mood == GuideMood.happy
              ? const Color(0xFF86EFAC)
              : const Color(0xFFD7E5F2),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppMotion.cardShadow,
      ),
      child: AnimatedSwitcher(
        duration: reducedMotion ? Duration.zero : AppMotion.uiDuration,
        switchInCurve: AppMotion.easeOut,
        switchOutCurve: AppMotion.easeOut,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: Text(
          widget.message,
          key: ValueKey<String>(widget.message),
          textAlign: widget.large ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: widget.large ? 18 : 13.5,
            height: 1.4,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: const Color(0xFF102A43),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: widget.large
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
  final double wave;
  final bool blink;
  final double floatFactor;

  _ButtonCompanionPainter(
    this.mood, {
    this.wave = 0.0,
    this.blink = false,
    this.floatFactor = 0.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 160, size.height / 160);
    final blue = Paint()..color = const Color(0xFF1D5B9F);
    final orange = Paint()..color = const Color(0xFFF5862B);
    final white = Paint()..color = Colors.white;
    final ink = Paint()..color = const Color(0xFF102A43);

    // Ground shadow gently contracts as mascot floats up
    final shadowScale = 1.0 - (floatFactor * 0.08);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(80, 146),
        width: 104 * shadowScale,
        height: 12 * shadowScale,
      ),
      Paint()..color = const Color(0xFFE3EDF7),
    );

    // Feet
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

    // Arms (right arm smoothly waves on welcome & happy)
    final arms = Paint()
      ..color = blue.color
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(28, 92), const Offset(12, 110), arms);
    final raised = mood == GuideMood.welcome || mood == GuideMood.happy;
    final waveOffsetX = raised ? wave * 6.0 : 0.0;
    final waveOffsetY = raised ? (wave * -5.0) : 0.0;
    canvas.drawLine(
      const Offset(132, 90),
      Offset(149 + waveOffsetX, (raised ? 60 : 110) + waveOffsetY),
      arms,
    );

    // Outer body + glossy inner face
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
    // Subtle top highlight sheen
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(42, 33, 76, 16),
        const Radius.circular(10),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.14),
    );

    // Smart LED indicator dot
    canvas.drawCircle(
      const Offset(80, 42),
      7,
      mood == GuideMood.happy ? (Paint()..color = const Color(0xFF34D399)) : orange,
    );

    // Eyes (with natural blink)
    for (final x in [59.0, 101.0]) {
      if (blink) {
        final lid = Paint()
          ..color = ink.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(x - 8, 76), Offset(x + 8, 76), lid);
      } else {
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
    }

    // Mouth expression
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
      oldDelegate.mood != mood ||
      oldDelegate.wave != wave ||
      oldDelegate.blink != blink ||
      oldDelegate.floatFactor != floatFactor;
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
    this.curve = AppMotion.easeOut,
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
