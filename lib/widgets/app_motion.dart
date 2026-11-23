import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Calibrated motion language & native-feel UI primitives
/// derived from `fe-motion-ui` (Emil Kowalski AI for UI, Apple Design, Design Bookmark Motion).
abstract final class AppMotion {
  /// Strong ease-out curve for crisp UI entrances, exits, and press states.
  static const Curve easeOut = Cubic(0.23, 1.0, 0.32, 1.0);

  /// Strong ease-in-out curve for on-screen morphing & sliding indicators.
  static const Curve easeInOut = Cubic(0.77, 0.0, 0.175, 1.0);

  /// Apple / iOS sheet & drawer curve.
  static const Curve easeDrawer = Cubic(0.32, 0.72, 0.0, 1.0);

  static const Duration pressDuration = Duration(milliseconds: 110);
  static const Duration fastDuration = Duration(milliseconds: 160);
  static const Duration uiDuration = Duration(milliseconds: 200);
  static const Duration viewDuration = Duration(milliseconds: 210);
  static const Duration routeDuration = Duration(milliseconds: 260);
  static const Duration sheetDuration = Duration(milliseconds: 340);

  /// True when continuous ambient motion (mascot float, live status pulse) is safe:
  /// honors `MediaQuery.disableAnimationsOf(context)` and pauses inside widget tests
  /// so `tester.pumpAndSettle()` never hangs.
  static bool allowAmbient(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return false;
    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    return !bindingName.contains('Test');
  }

  /// Soft elevated card shadow (replaces heavy flat borders).
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x060F172A),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  /// Subtle floating dock / bottom bar shadow.
  static const List<BoxShadow> dockShadow = [
    BoxShadow(
      color: Color(0x100F172A),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];
}

/// Global fluid page transition builder:
/// iOS-grade directional horizontal slide + depth parallax + subtle dim scrim,
/// automatically respecting `MediaQuery.disableAnimationsOf(context)`.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.isFirst) return child;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (reducedMotion) {
      return FadeTransition(opacity: animation, child: child);
    }

    final primaryCurved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.easeOut,
      reverseCurve: AppMotion.easeOut,
    );
    final secondaryCurved = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppMotion.easeOut,
      reverseCurve: AppMotion.easeOut,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.10, 0),
      ).animate(secondaryCurved),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.975).animate(secondaryCurved),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.62, curve: AppMotion.easeOut),
              reverseCurve: AppMotion.easeOut,
            ),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.22, 0),
              end: Offset.zero,
            ).animate(primaryCurved),
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.985,
                end: 1.0,
              ).animate(primaryCurved),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Choreographed GPU-composited entrance (opacity + subtle translateY + scale 0.985 -> 1)
/// calibrated for 40ms section stagger while strictly respecting reduced-motion.
class StaggeredReveal extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration stepDelay;
  final Duration duration;
  final double offsetY;

  const StaggeredReveal({
    super.key,
    required this.child,
    this.index = 0,
    this.stepDelay = const Duration(milliseconds: 45),
    this.duration = const Duration(milliseconds: 260),
    this.offsetY = 12,
  });

  @override
  State<StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<StaggeredReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _delayTimer;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) {
      _controller.value = 1.0;
      return;
    }
    final delayMs = (widget.index * widget.stepDelay.inMilliseconds).clamp(0, 260);
    if (delayMs == 0) {
      _controller.forward();
    } else {
      _delayTimer = Timer(Duration(milliseconds: delayMs), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = AppMotion.easeOut.transform(_controller.value);
        final scale = 0.985 + (0.015 * t);
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, widget.offsetY * (1.0 - t)),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// GPU-composited live status indicator with a gentle expanding signal halo.
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const PulsingDot({
    super.key,
    this.color = const Color(0xFF4ADE80),
    this.size = 7,
  });

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.allowAmbient(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final core = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.color,
        shape: BoxShape.circle,
      ),
    );
    if (!AppMotion.allowAmbient(context)) return core;

    return SizedBox(
      width: widget.size * 2.1,
      height: widget.size * 2.1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = AppMotion.easeOut.transform(_controller.value);
              return Transform.scale(
                scale: 1.0 + (t * 1.15),
                child: Opacity(
                  opacity: (1.0 - t) * 0.55,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
          core,
        ],
      ),
    );
  }
}

/// Smooth count-up text using tabular figures so KPI digits never jitter horizontally.
class AnimatedCountText extends StatelessWidget {
  final int value;
  final String prefix;
  final String suffix;
  final TextStyle style;
  final int maxLines;

  const AnimatedCountText({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    required this.style,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final tabularStyle = style.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    if (reduced) {
      return Text(
        '$prefix$value$suffix',
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: tabularStyle,
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 220),
      curve: AppMotion.easeOut,
      builder: (_, val, _) => Text(
        '$prefix${val.round()}$suffix',
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: tabularStyle,
      ),
    );
  }
}

/// Instant pointer-down tactile compression (`scale(0.97)`) that responds the
/// millisecond a finger touches down without blocking scroll or tap gestures.
class TactilePress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final bool haptic;
  final BorderRadius? borderRadius;

  const TactilePress({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.97,
    this.haptic = false,
    this.borderRadius,
  });

  @override
  State<TactilePress> createState() => _TactilePressState();
}

class _TactilePressState extends State<TactilePress> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final targetScale = (_pressed && !reducedMotion) ? widget.scaleDown : 1.0;

    Widget content = AnimatedScale(
      scale: targetScale,
      duration: AppMotion.pressDuration,
      curve: AppMotion.easeOut,
      child: widget.child,
    );

    if (widget.onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (widget.haptic) {
              HapticFeedback.selectionClick();
            }
            widget.onTap?.call();
          },
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          splashColor: const Color(0xFF0E6BA8).withValues(alpha: 0.07),
          highlightColor: const Color(0xFF0E6BA8).withValues(alpha: 0.04),
          child: content,
        ),
      );
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: content,
    );
  }
}

/// Preserves scroll position & state like IndexedStack while giving tab swaps
/// a directional horizontal slide + crossfade + subtle depth scale transition.
class AppAnimatedTabBody extends StatefulWidget {
  final int currentIndex;
  final List<Widget> children;

  const AppAnimatedTabBody({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  @override
  State<AppAnimatedTabBody> createState() => _AppAnimatedTabBodyState();
}

class _AppAnimatedTabBodyState extends State<AppAnimatedTabBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _activeIndex = 0;
  int? _outgoingIndex;
  int _direction = 1; // +1: moving right (new enters from right), -1: moving left

  @override
  void initState() {
    super.initState();
    _activeIndex = widget.children.isEmpty
        ? 0
        : widget.currentIndex.clamp(0, widget.children.length - 1);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      value: 1.0,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed &&
            _outgoingIndex != null &&
            mounted) {
          setState(() => _outgoingIndex = null);
        }
      });
  }

  @override
  void didUpdateWidget(covariant AppAnimatedTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children.isEmpty) return;
    final nextIndex = widget.currentIndex.clamp(0, widget.children.length - 1);
    if (nextIndex != _activeIndex) {
      final reduced = MediaQuery.disableAnimationsOf(context);
      _direction = nextIndex > _activeIndex ? 1 : -1;
      if (reduced) {
        _outgoingIndex = null;
        _activeIndex = nextIndex;
        _controller.value = 1.0;
      } else {
        _outgoingIndex = _activeIndex;
        _activeIndex = nextIndex;
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) return const SizedBox.shrink();
    final safeActive = _activeIndex.clamp(0, widget.children.length - 1);
    final safeOutgoing = _outgoingIndex != null &&
            _outgoingIndex! >= 0 &&
            _outgoingIndex! < widget.children.length &&
            _outgoingIndex != safeActive
        ? _outgoingIndex
        : null;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = AppMotion.easeOut.transform(_controller.value);
        return Stack(
          fit: StackFit.expand,
          children: List<Widget>.generate(widget.children.length, (i) {
            final isActive = i == safeActive;
            final isOutgoing = i == safeOutgoing && _controller.isAnimating;
            final visible = isActive || isOutgoing;

            double opacity = isActive ? 1.0 : 0.0;
            double dx = 0.0;
            double scale = 1.0;

            if (safeOutgoing != null && _controller.isAnimating) {
              if (isActive) {
                opacity = (t * 1.15).clamp(0.0, 1.0);
                dx = (1.0 - t) * 0.14 * _direction;
                scale = 0.988 + (0.012 * t);
              } else if (isOutgoing) {
                opacity = (1.0 - t * 1.25).clamp(0.0, 1.0);
                dx = -t * 0.08 * _direction;
                scale = 1.0 - (0.012 * t);
              }
            }

            return Offstage(
              offstage: !visible,
              child: IgnorePointer(
                ignoring: !isActive,
                child: TickerMode(
                  enabled: isActive,
                  child: FractionalTranslation(
                    translation: Offset(dx, 0),
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: opacity,
                        child: widget.children[i],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Reusable directional horizontal slide + fade switcher for filter chips,
/// segmented lists, and inline state views.
class AppSlideSwitcher extends StatelessWidget {
  final Widget child;
  final int direction; // +1 slides from right, -1 slides from left
  final Duration duration;

  const AppSlideSwitcher({
    super.key,
    required this.child,
    this.direction = 1,
    this.duration = const Duration(milliseconds: 220),
  });

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: reduced ? Duration.zero : duration,
      switchInCurve: AppMotion.easeOut,
      switchOutCurve: AppMotion.easeOut,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.topCenter,
        children: [
          ...previousChildren,
          ?currentChild,
        ],
      ),
      transitionBuilder: (widget, animation) {
        if (reduced) {
          return FadeTransition(opacity: animation, child: widget);
        }
        final isIncoming = widget.key == child.key;
        final beginOffset = Offset(
          (isIncoming ? 0.08 : -0.06) * direction,
          0,
        );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: beginOffset,
              end: Offset.zero,
            ).animate(animation),
            child: widget,
          ),
        );
      },
      child: child,
    );
  }
}

/// Interactive swipeable slide deck with parallax scale/lift interpolation,
/// clickable morphing pill indicators, and gentle auto-play (pauses on touch
/// and automatically disables under reduced-motion / widget tests).
class HeroSlideDeck extends StatefulWidget {
  final List<Widget> slides;
  final double height;
  final Color activeDotColor;
  final Color inactiveDotColor;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final double viewportFraction;
  final ValueChanged<int>? onPageChanged;

  const HeroSlideDeck({
    super.key,
    required this.slides,
    required this.height,
    this.activeDotColor = const Color(0xFF0E6BA8),
    this.inactiveDotColor = const Color(0xFFCBD5E1),
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(milliseconds: 5200),
    this.viewportFraction = 0.93,
    this.onPageChanged,
  });

  @override
  State<HeroSlideDeck> createState() => _HeroSlideDeckState();
}

class _HeroSlideDeckState extends State<HeroSlideDeck> {
  late final PageController _pageController;
  double _page = 0.0;
  int _currentIndex = 0;
  Timer? _autoTimer;
  bool _userDragging = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: widget.viewportFraction)
      ..addListener(_handleScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAutoPlay();
  }

  @override
  void didUpdateWidget(covariant HeroSlideDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autoPlay != widget.autoPlay ||
        oldWidget.slides.length != widget.slides.length) {
      _syncAutoPlay();
    }
  }

  void _handleScroll() {
    if (!_pageController.hasClients) return;
    final nextPage = _pageController.page ?? _currentIndex.toDouble();
    if ((nextPage - _page).abs() > 0.002 && mounted) {
      setState(() => _page = nextPage);
    }
  }

  void _syncAutoPlay() {
    _autoTimer?.cancel();
    if (!widget.autoPlay ||
        widget.slides.length <= 1 ||
        !AppMotion.allowAmbient(context)) {
      return;
    }
    _autoTimer = Timer.periodic(widget.autoPlayInterval, (_) {
      if (!mounted || _userDragging || !_pageController.hasClients) return;
      final next = (_currentIndex + 1) % widget.slides.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: AppMotion.easeOut,
      );
    });
  }

  void _jumpTo(int index) {
    if (!_pageController.hasClients || index == _currentIndex) return;
    HapticFeedback.selectionClick();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) {
      _pageController.jumpToPage(index);
    } else {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 340),
        curve: AppMotion.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.removeListener(_handleScroll);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slides.isEmpty) return const SizedBox.shrink();
    final reduced = MediaQuery.disableAnimationsOf(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification &&
                  notification.dragDetails != null) {
                _userDragging = true;
              } else if (notification is ScrollEndNotification) {
                _userDragging = false;
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              padEnds: false,
              itemCount: widget.slides.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                widget.onPageChanged?.call(index);
              },
              itemBuilder: (context, index) {
                final dist = (_page - index).abs().clamp(0.0, 1.0);
                final scale = reduced ? 1.0 : (1.0 - dist * 0.05);
                final opacity = reduced ? 1.0 : (1.0 - dist * 0.22);
                final liftY = reduced ? 0.0 : (dist * 5.0);

                return Padding(
                  padding: EdgeInsets.only(
                    right: index == widget.slides.length - 1 ? 0 : 10,
                  ),
                  child: Transform.translate(
                    offset: Offset(0, liftY),
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: opacity,
                        child: widget.slides[index],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (widget.slides.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(widget.slides.length, (i) {
              final active = i == _currentIndex;
              return GestureDetector(
                key: ValueKey('slideDot_$i'),
                behavior: HitTestBehavior.opaque,
                onTap: () => _jumpTo(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: AnimatedContainer(
                    duration: reduced
                        ? Duration.zero
                        : const Duration(milliseconds: 240),
                    curve: AppMotion.easeOut,
                    width: active ? 24 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active
                          ? widget.activeDotColor
                          : widget.inactiveDotColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class AppNavItem {
  final IconData icon;
  final String label;

  const AppNavItem({required this.icon, required this.label});
}

/// Translucent frosted-glass bottom navigation bar with a gliding active pill
/// indicator, optional count badges, and instant tactile press response.
class AppFloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<AppNavItem> items;
  final bool compactLabels;
  final Color accentColor;
  final Color accentSoftColor;
  final Map<int, int> badges;

  const AppFloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
    this.compactLabels = false,
    this.accentColor = const Color(0xFF0E6BA8),
    this.accentSoftColor = const Color(0xFFE0F2FE),
    this.badges = const {},
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final count = items.isEmpty ? 1 : items.length;
    final safeSelected = selectedIndex.clamp(0, count - 1);
    final pillAlignmentX = count <= 1
        ? 0.0
        : -1.0 + (2.0 * safeSelected / (count - 1));

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            8,
            8,
            8,
            bottomPadding > 0 ? bottomPadding : 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            border: const Border(
              top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C0F172A),
                blurRadius: 18,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slotWidth = constraints.maxWidth / count;
              final pillWidth = (slotWidth * 0.68).clamp(44.0, 64.0);
              return Stack(
                children: [
                  // Gliding pill highlight sliding smoothly behind the active tab icon
                  Positioned(
                    top: 2,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: AnimatedAlign(
                        alignment: Alignment(pillAlignmentX, 0),
                        duration: reducedMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 240),
                        curve: AppMotion.easeInOut,
                        child: SizedBox(
                          width: slotWidth,
                          child: Center(
                            child: AnimatedContainer(
                              duration: reducedMotion
                                  ? Duration.zero
                                  : AppMotion.uiDuration,
                              curve: AppMotion.easeOut,
                              width: pillWidth,
                              height: 30,
                              decoration: BoxDecoration(
                                color: accentSoftColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: List<Widget>.generate(items.length, (index) {
                      final item = items[index];
                      final selected = index == safeSelected;
                      final badgeCount = badges[index] ?? 0;
                      return Expanded(
                        child: TactilePress(
                          scaleDown: 0.93,
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => onSelected(index),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    SizedBox(
                                      height: 30,
                                      width: 54,
                                      child: Center(
                                        child: AnimatedScale(
                                          scale: selected && !reducedMotion
                                              ? 1.12
                                              : 1.0,
                                          duration: AppMotion.fastDuration,
                                          curve: AppMotion.easeOut,
                                          child: Icon(
                                            item.icon,
                                            size: 20,
                                            color: selected
                                                ? accentColor
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (badgeCount > 0)
                                      Positioned(
                                        top: -2,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEF4444),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Text(
                                            badgeCount > 99
                                                ? '99+'
                                                : '$badgeCount',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              fontFeatures: [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                AnimatedDefaultTextStyle(
                                  duration: reducedMotion
                                      ? Duration.zero
                                      : AppMotion.fastDuration,
                                  curve: AppMotion.easeOut,
                                  style: TextStyle(
                                    fontSize: compactLabels ? 10.5 : 11.5,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    letterSpacing: -0.1,
                                    color: selected
                                        ? accentColor
                                        : const Color(0xFF64748B),
                                  ),
                                  child: Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
