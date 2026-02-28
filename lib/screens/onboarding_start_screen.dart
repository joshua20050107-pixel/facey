import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:permission_handler/permission_handler.dart';

import 'payment_page_scaffold.dart';
import 'upgrade_screen.dart';
import '../routes/no_swipe_back_material_page_route.dart';

const int _kOnboardingGaugeSteps = 10;
final RouteObserver<PageRoute<dynamic>> onboardingRouteObserver =
    RouteObserver<PageRoute<dynamic>>();

class _OnboardingGradientBackground extends StatelessWidget {
  const _OnboardingGradientBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFF042448),
                  Color(0xFF021A35),
                  Color(0xFF000D20),
                ],
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -1.05),
                radius: 1.12,
                colors: <Color>[
                  Color(0x802766AA),
                  Color(0x3323588A),
                  Color(0x00071B36),
                ],
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: <Color>[
                  Color(0xD9001024),
                  Color(0x00001024),
                  Color(0xD9001024),
                ],
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0x00000817),
                  Color(0x80000713),
                  Color(0xE6000610),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _OnboardingGaugeMemory {
  static int lastStep = 0;
}

class _OnboardingEvaluationMemory {
  static double score = 50;
  static bool hasMovedSlider = false;
}

class _OnboardingOptimizingMemory {
  static bool completed = false;
}

class _OnboardingNoTransitionRoute<T> extends NoSwipeBackMaterialPageRoute<T> {
  _OnboardingNoTransitionRoute({required super.builder});

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

class _OnboardingFinishRoute<T> extends PageRouteBuilder<T> {
  _OnboardingFinishRoute({required WidgetBuilder builder})
    : super(
        pageBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) => builder(context),
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        transitionsBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child,
            ) {
              final bool isReversing =
                  animation.status == AnimationStatus.reverse;
              final Tween<Offset> tween = isReversing
                  ? Tween<Offset>(begin: Offset.zero, end: const Offset(0, 1))
                  : Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero);
              final Animation<Offset> offsetAnimation = tween.animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeInCubic,
                ),
              );
              return SlideTransition(position: offsetAnimation, child: child);
            },
      );
}

class OnboardingStartScreen extends StatefulWidget {
  const OnboardingStartScreen({super.key});

  @override
  State<OnboardingStartScreen> createState() => _OnboardingStartScreenState();
}

class _OnboardingStartScreenState extends State<OnboardingStartScreen> {
  bool _showFirstImage = false;
  bool _showSecondImage = false;
  bool _showNextButton = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _showFirstImage = true;
      });
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() {
          _showSecondImage = true;
        });
      });
      Future<void>.delayed(const Duration(milliseconds: 2200), () {
        if (!mounted) return;
        setState(() {
          _showNextButton = true;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 220),
              child: Align(
                alignment: Alignment.topCenter,
                child: AnimatedSlide(
                  offset: _showFirstImage ? Offset.zero : const Offset(0, 0.22),
                  duration: const Duration(milliseconds: 1300),
                  curve: Curves.easeOutQuart,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AnimatedOpacity(
                        opacity: _showFirstImage ? 1 : 0,
                        duration: const Duration(milliseconds: 1300),
                        curve: Curves.easeOutQuart,
                        child: Image.asset(
                          'assets/images/っぺろん.png',
                          width: 230,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedSlide(
                        offset: _showSecondImage
                            ? Offset.zero
                            : const Offset(0, 0.22),
                        duration: const Duration(milliseconds: 1300),
                        curve: Curves.easeOutQuart,
                        child: AnimatedOpacity(
                          opacity: _showSecondImage ? 1 : 0,
                          duration: const Duration(milliseconds: 1300),
                          curve: Curves.easeOutQuart,
                          child: Image.asset(
                            'assets/images/頑固者.png',
                            width: 125,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: AnimatedSlide(
                  offset: _showNextButton ? Offset.zero : const Offset(0, 0.2),
                  duration: const Duration(milliseconds: 1300),
                  curve: Curves.easeOutQuart,
                  child: AnimatedOpacity(
                    opacity: _showNextButton ? 1 : 0,
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutQuart,
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style:
                            ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: const StadiumBorder(),
                              textStyle: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                              shadowColor: Colors.transparent,
                            ).copyWith(
                              overlayColor: WidgetStatePropertyAll(
                                Colors.black.withValues(alpha: 0.06),
                              ),
                            ),
                        onPressed: () {
                          _OnboardingGaugeMemory.lastStep = 0;
                          _OnboardingEvaluationMemory.score = 50;
                          _OnboardingEvaluationMemory.hasMovedSlider = false;
                          Navigator.of(context).push(
                            _OnboardingNoTransitionRoute<void>(
                              builder: (_) => const OnboardingNextScreen(),
                            ),
                          );
                        },
                        child: const Text('次へ'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingNextScreen extends StatefulWidget {
  const OnboardingNextScreen({super.key});

  @override
  State<OnboardingNextScreen> createState() => _OnboardingNextScreenState();
}

class _OnboardingNextScreenState extends State<OnboardingNextScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedGender;
  late final AnimationController _introController;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  Widget _buildStaggeredReveal({required int order, required Widget child}) {
    final double start = order * 0.08;
    final double end = (start + 0.46) > 1 ? 1 : (start + 0.46);
    final Animation<double> animation = CurvedAnimation(
      parent: _introController,
      curve: Interval(start, end, curve: Curves.easeOutQuart),
    );

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (BuildContext context, Widget? builtChild) {
        final double t = animation.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * -12),
            child: builtChild,
          ),
        );
      },
    );
  }

  void _goToNextPage(BuildContext context) {
    Navigator.of(context).push(
      _OnboardingNoTransitionRoute<void>(
        builder: (_) => const OnboardingGenderDoneScreen(),
      ),
    );
  }

  void _handleGenderTap(String label) {
    setState(() {
      _selectedGender = label;
    });
  }

  Widget _buildGenderButton(String label, BuildContext context) {
    final IconData icon = label == '男性'
        ? Icons.male_rounded
        : Icons.female_rounded;
    final bool selected = _selectedGender == label;
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF000000) : const Color(0xFFE6E7EC),
            width: 1.2,
          ),
          color: selected
              ? const Color(0xFF000000)
              : const Color.fromARGB(255, 222, 221, 221),
        ),
        child: TextButton(
          onPressed: () => _handleGenderTap(label),
          style: TextButton.styleFrom(
            foregroundColor: selected
                ? const Color(0xFFF7F8FC)
                : const Color(0xFF17181D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 24),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? const Color(0xFFF7F8FC)
                      : const Color(0xFF17181D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _OnboardingGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 8),
                const _OnboardingTopBar(
                  currentStep: 0,
                  totalSteps: _kOnboardingGaugeSteps,
                  backEnabled: false,
                ),
                const SizedBox(height: 20),
                _buildStaggeredReveal(
                  order: 0,
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '性別を選択',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _buildStaggeredReveal(
                          order: 1,
                          child: _buildGenderButton('男性', context),
                        ),
                        const SizedBox(height: 38),
                        _buildStaggeredReveal(
                          order: 2,
                          child: _buildGenderButton('女性', context),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildStaggeredReveal(
                  order: 3,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedGender == null
                              ? const Color(0xFF707A8D)
                              : Colors.white,
                          foregroundColor: _selectedGender == null
                              ? const Color(0xFFD7DCE7)
                              : Colors.black,
                          elevation: 0,
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: _selectedGender == null
                            ? null
                            : () => _goToNextPage(context),
                        child: const Text('次へ'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingStepIndicator extends StatefulWidget {
  const _OnboardingStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.color = Colors.white,
  });

  final int currentStep;
  final int totalSteps;
  final Color color;

  @override
  State<_OnboardingStepIndicator> createState() =>
      _OnboardingStepIndicatorState();
}

class _OnboardingStepIndicatorState extends State<_OnboardingStepIndicator>
    with RouteAware {
  PageRoute<dynamic>? _route;
  int _animSeed = 0;
  double _fromProgress = 0;
  double _toProgress = 0;

  @override
  void initState() {
    super.initState();
    _setInitialProgress();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && route != _route) {
      if (_route != null) {
        onboardingRouteObserver.unsubscribe(this);
      }
      _route = route;
      onboardingRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didUpdateWidget(covariant _OnboardingStepIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep ||
        oldWidget.totalSteps != widget.totalSteps) {
      _syncFromMemory();
    }
  }

  @override
  void didPopNext() {
    _syncFromMemory();
  }

  @override
  void didPush() {
    _syncFromMemory();
  }

  void _setInitialProgress() {
    final int clampedStep = widget.currentStep
        .clamp(0, widget.totalSteps)
        .toInt();
    final int fromStep = _OnboardingGaugeMemory.lastStep.clamp(
      0,
      widget.totalSteps,
    );
    _fromProgress = fromStep / widget.totalSteps;
    _toProgress = clampedStep / widget.totalSteps;
  }

  void _syncFromMemory() {
    final int clampedStep = widget.currentStep
        .clamp(0, widget.totalSteps)
        .toInt();
    final int fromStep = _OnboardingGaugeMemory.lastStep.clamp(
      0,
      widget.totalSteps,
    );
    final double from = fromStep / widget.totalSteps;
    final double to = clampedStep / widget.totalSteps;
    _OnboardingGaugeMemory.lastStep = clampedStep;
    if (!mounted) return;
    setState(() {
      _fromProgress = from;
      _toProgress = to;
      _animSeed++;
    });
  }

  @override
  void dispose() {
    if (_route != null) {
      onboardingRouteObserver.unsubscribe(this);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: double.infinity,
        height: 4,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: ColoredBox(color: widget.color.withValues(alpha: 0.2)),
            ),
            TweenAnimationBuilder<double>(
              key: ValueKey<int>(_animSeed),
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: _fromProgress, end: _toProgress),
              builder: (BuildContext context, double value, Widget? child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: child,
                );
              },
              child: SizedBox(
                height: 4,
                child: ColoredBox(color: widget.color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingTopBar extends StatelessWidget {
  const _OnboardingTopBar({
    required this.currentStep,
    required this.totalSteps,
    this.showBackButton = true,
    this.backEnabled = true,
    this.color = Colors.white,
  });

  final int currentStep;
  final int totalSteps;
  final bool showBackButton;
  final bool backEnabled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 48,
            child: showBackButton
                ? IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: backEnabled
                        ? () {
                            _OnboardingGaugeMemory.lastStep = currentStep;
                            Navigator.of(context).maybePop();
                          }
                        : null,
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: backEnabled
                          ? color
                          : color.withValues(alpha: 0.35),
                      size: 22,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: Center(
              child: _OnboardingStepIndicator(
                key: ValueKey<String>(
                  'g-${_OnboardingGaugeMemory.lastStep}-$currentStep',
                ),
                currentStep: currentStep,
                totalSteps: totalSteps,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class OnboardingGenderDoneScreen extends StatefulWidget {
  const OnboardingGenderDoneScreen({super.key});

  @override
  State<OnboardingGenderDoneScreen> createState() =>
      _OnboardingGenderDoneScreenState();
}

class _OnboardingGenderDoneScreenState extends State<OnboardingGenderDoneScreen>
    with SingleTickerProviderStateMixin {
  double _score = _OnboardingEvaluationMemory.score;
  bool _hasMovedSlider = _OnboardingEvaluationMemory.hasMovedSlider;
  late final AnimationController _introController;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  Widget _buildStaggeredReveal({required int order, required Widget child}) {
    final double start = order * 0.08;
    final double end = (start + 0.46) > 1 ? 1 : (start + 0.46);
    final Animation<double> animation = CurvedAnimation(
      parent: _introController,
      curve: Interval(start, end, curve: Curves.easeOutQuart),
    );

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (BuildContext context, Widget? builtChild) {
        final double t = animation.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * -12),
            child: builtChild,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _OnboardingGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 8),
                const _OnboardingTopBar(
                  currentStep: 1,
                  totalSteps: _kOnboardingGaugeSteps,
                ),
                const SizedBox(height: 20),
                _buildStaggeredReveal(
                  order: 0,
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'あなたの評価',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '外見の変化は、現在地を知ることから始まります。',
                          style: TextStyle(
                            color: Color(0xFFD7E0F1),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _buildStaggeredReveal(
                      order: 1,
                      child: Transform.translate(
                        offset: const Offset(0, -70),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Text(
                              '今の自分は、何点ですか？',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 34),
                            SizedBox(
                              width: double.infinity,
                              child: Column(
                                children: <Widget>[
                                  _FuturisticScoreRing(score: _score),
                                  const SizedBox(height: 34),
                                  _FuturisticScoreSlider(
                                    value: _score,
                                    onChanged: (double value) {
                                      setState(() {
                                        _score = value;
                                        _hasMovedSlider = true;
                                        _OnboardingEvaluationMemory.score =
                                            value;
                                        _OnboardingEvaluationMemory
                                                .hasMovedSlider =
                                            true;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Text(
                                        '0',
                                        style: TextStyle(
                                          color: Color(0xFFC1C9D6),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '100',
                                        style: TextStyle(
                                          color: Color(0xFFC1C9D6),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _buildStaggeredReveal(
                  order: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasMovedSlider
                              ? Colors.white
                              : const Color(0xFF707A8D),
                          foregroundColor: _hasMovedSlider
                              ? Colors.black
                              : const Color(0xFFD7DCE7),
                          elevation: 0,
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: _hasMovedSlider
                            ? () {
                                Navigator.of(context).push(
                                  _OnboardingNoTransitionRoute<void>(
                                    builder: (_) =>
                                        const OnboardingPerceptionScreen(),
                                  ),
                                );
                              }
                            : null,
                        child: const Text('次へ'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FullWidthTrackShape extends RoundedRectSliderTrackShape {
  const _FullWidthTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 2;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(
      offset.dx,
      trackTop,
      parentBox.size.width,
      trackHeight,
    );
  }
}

class _FuturisticScoreRing extends StatelessWidget {
  const _FuturisticScoreRing({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  const Color(0xFF52E6FF).withValues(alpha: 0.16),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Container(
            width: 118,
            height: 118,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: <Color>[Color(0xFF111B2D), Color(0xFF080D19)],
                radius: 0.95,
              ),
              border: Border.all(
                color: const Color(0xFF9BC9FF).withValues(alpha: 0.22),
              ),
            ),
            child: Text(
              score.round().toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
          CustomPaint(
            size: const Size.square(140),
            painter: _ScoreRingPainter(progress: score / 100),
          ),
        ],
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  const _ScoreRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final double clamped = progress.clamp(0.0, 1.0);
    final Offset center = size.center(Offset.zero);
    final Rect rect = Rect.fromCircle(
      center: center,
      radius: (size.shortestSide / 2) - 10,
    );

    final Paint track = Paint()
      ..color = const Color(0xFFADC3E9).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawArc(rect, 0, pi * 2, false, track);

    final Paint arc = Paint()
      ..shader = const SweepGradient(
        colors: <Color>[
          Color(0xFF3DE2FF),
          Color(0xFF6A68FF),
          Color(0xFFFF58D0),
          Color(0xFFFFCC72),
          Color(0xFF3DE2FF),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -pi / 2, (pi * 2) * clamped, false, arc);

    final double angle = (-pi / 2) + (pi * 2 * clamped);
    final double radius = rect.width / 2;
    final Offset knob = Offset(
      center.dx + cos(angle) * radius,
      center.dy + sin(angle) * radius,
    );
    final Paint glow = Paint()
      ..color = const Color(0xFF9EEBFF).withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(knob, 10, glow);
    canvas.drawCircle(knob, 4, Paint()..color = const Color(0xFFE2FBFF));
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _FuturisticScoreSlider extends StatelessWidget {
  const _FuturisticScoreSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(
              painter: _ScoreSliderTrackPainter(progress: value / 100),
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 28,
              trackShape: const _FullWidthTrackShape(),
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              overlayColor: Colors.transparent,
              thumbShape: const _NeonThumbShape(radius: 15),
            ),
            child: Slider(value: value, min: 0, max: 100, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

class _ScoreSliderTrackPainter extends CustomPainter {
  const _ScoreSliderTrackPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final double clamped = progress.clamp(0.0, 1.0);
    final RRect fullTrack = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, (size.height - 8) / 2, size.width, 8),
      const Radius.circular(999),
    );
    final Paint trackBase = Paint()
      ..color = const Color(0xFF9BB2D8).withValues(alpha: 0.2);
    canvas.drawRRect(fullTrack, trackBase);

    final double activeWidth = size.width * clamped;
    if (activeWidth > 0) {
      final RRect activeTrack = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, (size.height - 8) / 2, activeWidth, 8),
        const Radius.circular(999),
      );
      final Paint activePaint = Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFFD641FF), Color(0xFF4ADFFF)],
        ).createShader(Rect.fromLTWH(0, 0, activeWidth, size.height));
      final Paint activeGlow = Paint()
        ..color = const Color(0xFF5BDFFF).withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawRRect(activeTrack, activeGlow);
      canvas.drawRRect(activeTrack, activePaint);
    }

    final int ticks = 38;
    final Paint tickPaint = Paint()
      ..color = const Color(0xFFE7EEFF).withValues(alpha: 0.5)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    for (int i = 0; i <= ticks; i++) {
      final double dx = size.width * (i / ticks);
      final bool major = i % 4 == 0;
      final double tickHeight = major ? 12 : 8;
      canvas.drawLine(
        Offset(dx, (size.height / 2) - (tickHeight / 2)),
        Offset(dx, (size.height / 2) + (tickHeight / 2)),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreSliderTrackPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _NeonThumbShape extends SliderComponentShape {
  const _NeonThumbShape({required this.radius});

  final double radius;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(radius + 2);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final Paint glow = Paint()
      ..color = const Color(0xFF84F1FF).withValues(alpha: 0.38)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius + 3, glow);

    final Paint shell = Paint()
      ..shader = const RadialGradient(
        colors: <Color>[Color(0xFFE8F7FF), Color(0xFFBFE9FF)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, shell);

    final Paint core = Paint()..color = const Color(0xFFDDF4FF);
    canvas.drawCircle(center, radius * 0.52, core);
  }
}

class OnboardingPerceptionScreen extends StatefulWidget {
  const OnboardingPerceptionScreen({super.key});

  @override
  State<OnboardingPerceptionScreen> createState() =>
      _OnboardingPerceptionScreenState();
}

class _OnboardingPerceptionScreenState extends State<OnboardingPerceptionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _introController;
  String? _selected;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  Widget _buildStaggeredReveal({required int order, required Widget child}) {
    final double start = order * 0.08;
    final double end = (start + 0.46) > 1 ? 1 : (start + 0.46);
    final Animation<double> animation = CurvedAnimation(
      parent: _introController,
      curve: Interval(start, end, curve: Curves.easeOutQuart),
    );

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (BuildContext context, Widget? builtChild) {
        final double t = animation.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * -12),
            child: builtChild,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const List<String> options = <String>[
      'かなり魅力的',
      'まあまあ魅力的',
      '普通',
      'あまり自信ない',
      '正直自信ない',
    ];
    return Scaffold(
      body: _OnboardingGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 8),
                const _OnboardingTopBar(
                  currentStep: 2,
                  totalSteps: _kOnboardingGaugeSteps,
                ),
                const SizedBox(height: 20),
                _buildStaggeredReveal(
                  order: 0,
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '他人からどう見られてると思う？',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: ListView.separated(
                    itemCount: options.length,
                    itemBuilder: (_, int index) => _buildStaggeredReveal(
                      order: index + 1,
                      child: _PerceptionOptionButton(
                        label: options[index],
                        selected: _selected == options[index],
                        onTap: () {
                          setState(() {
                            _selected = options[index];
                          });
                        },
                      ),
                    ),
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selected == null
                            ? const Color(0xFF707A8D)
                            : Colors.white,
                        foregroundColor: _selected == null
                            ? const Color(0xFFD7DCE7)
                            : Colors.black,
                        elevation: 0,
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: _selected == null
                          ? null
                          : () {
                              Navigator.of(context).push(
                                _OnboardingNoTransitionRoute<void>(
                                  builder: (_) =>
                                      const OnboardingConcernScreen(),
                                ),
                              );
                            },
                      child: const Text('次へ'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingConcernScreen extends StatefulWidget {
  const OnboardingConcernScreen({super.key});

  @override
  State<OnboardingConcernScreen> createState() =>
      _OnboardingConcernScreenState();
}

class _OnboardingConcernScreenState extends State<OnboardingConcernScreen>
    with SingleTickerProviderStateMixin {
  final Set<String> _selected = <String>{};
  late final AnimationController _introController;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  Widget _buildStaggeredReveal({required int order, required Widget child}) {
    final double start = order * 0.08;
    final double end = (start + 0.46) > 1 ? 1 : (start + 0.46);
    final Animation<double> animation = CurvedAnimation(
      parent: _introController,
      curve: Interval(start, end, curve: Curves.easeOutQuart),
    );

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (BuildContext context, Widget? builtChild) {
        final double t = animation.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * -12),
            child: builtChild,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const List<String> options = <String>[
      '清潔感',
      '目力',
      '輪郭',
      '肌',
      '髪',
      '雰囲気',
      'その他',
    ];
    return Scaffold(
      body: _OnboardingGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 8),
                const _OnboardingTopBar(
                  currentStep: 3,
                  totalSteps: _kOnboardingGaugeSteps,
                ),
                const SizedBox(height: 20),
                _buildStaggeredReveal(
                  order: 0,
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '一番気になるのは？',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildStaggeredReveal(
                  order: 1,
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '複数選択',
                      style: TextStyle(color: Color(0xFFBFC7D7), fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: options.length,
                    itemBuilder: (_, int index) {
                      final String label = options[index];
                      final bool selected = _selected.contains(label);
                      return _buildStaggeredReveal(
                        order: index + 2,
                        child: _QuestionOptionButton(
                          label: label,
                          selected: selected,
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _selected.remove(label);
                              } else {
                                _selected.add(label);
                              }
                            });
                          },
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selected.isEmpty
                            ? const Color(0xFF707A8D)
                            : Colors.white,
                        foregroundColor: _selected.isEmpty
                            ? const Color(0xFFD7DCE7)
                            : Colors.black,
                        elevation: 0,
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: _selected.isEmpty
                          ? null
                          : () {
                              Navigator.of(context).push(
                                _OnboardingNoTransitionRoute<void>(
                                  builder: (_) =>
                                      const OnboardingReactionScreen(),
                                ),
                              );
                            },
                      child: const Text('次へ'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingReactionScreen extends StatefulWidget {
  const OnboardingReactionScreen({super.key});

  @override
  State<OnboardingReactionScreen> createState() =>
      _OnboardingReactionScreenState();
}

class _OnboardingReactionScreenState extends State<OnboardingReactionScreen>
    with SingleTickerProviderStateMixin {
  String? _selected;
  late final AnimationController _introController;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  Widget _buildStaggeredReveal({required int order, required Widget child}) {
    final double start = order * 0.08;
    final double end = (start + 0.46) > 1 ? 1 : (start + 0.46);
    final Animation<double> animation = CurvedAnimation(
      parent: _introController,
      curve: Interval(start, end, curve: Curves.easeOutQuart),
    );

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (BuildContext context, Widget? builtChild) {
        final double t = animation.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * -12),
            child: builtChild,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const List<String> options = <String>[
      'よく褒められる',
      '清潔感はある',
      '可もなく不可もなく',
      '異性に刺さらない',
      '友達止まり',
      'わからない',
    ];
    return Scaffold(
      body: _OnboardingGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 8),
                const _OnboardingTopBar(
                  currentStep: 4,
                  totalSteps: _kOnboardingGaugeSteps,
                ),
                const SizedBox(height: 20),
                _buildStaggeredReveal(
                  order: 0,
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '異性の反応は？',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.separated(
                    itemCount: options.length,
                    itemBuilder: (_, int index) => _buildStaggeredReveal(
                      order: index + 1,
                      child: _QuestionOptionButton(
                        label: options[index],
                        selected: _selected == options[index],
                        onTap: () {
                          setState(() {
                            _selected = options[index];
                          });
                        },
                      ),
                    ),
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selected == null
                            ? const Color(0xFF707A8D)
                            : Colors.white,
                        foregroundColor: _selected == null
                            ? const Color(0xFFD7DCE7)
                            : Colors.black,
                        elevation: 0,
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: _selected == null
                          ? null
                          : () {
                              Navigator.of(context).push(
                                _OnboardingNoTransitionRoute<void>(
                                  builder: (_) =>
                                      const OnboardingReasonScreen(),
                                ),
                              );
                            },
                      child: const Text('次へ'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingReasonScreen extends StatefulWidget {
  const OnboardingReasonScreen({super.key});

  @override
  State<OnboardingReasonScreen> createState() => _OnboardingReasonScreenState();
}

class _OnboardingReasonScreenState extends State<OnboardingReasonScreen>
    with SingleTickerProviderStateMixin {
  String? _selected;
  late final AnimationController _introController;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  Widget _buildStaggeredReveal({required int order, required Widget child}) {
    final double start = order * 0.08;
    final double end = (start + 0.46) > 1 ? 1 : (start + 0.46);
    final Animation<double> animation = CurvedAnimation(
      parent: _introController,
      curve: Interval(start, end, curve: Curves.easeOutQuart),
    );

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (BuildContext context, Widget? builtChild) {
        final double t = animation.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * -12),
            child: builtChild,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const List<String> options = <String>[
      'モテたい',
      '自信が欲しい',
      '垢抜けたい',
      'レベル上げたい',
      'なんとなく',
    ];
    return Scaffold(
      body: _OnboardingGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 8),
                const _OnboardingTopBar(
                  currentStep: 5,
                  totalSteps: _kOnboardingGaugeSteps,
                ),
                const SizedBox(height: 20),
                _buildStaggeredReveal(
                  order: 0,
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '自分を変えたい理由は？',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.separated(
                    itemCount: options.length,
                    itemBuilder: (_, int index) => _buildStaggeredReveal(
                      order: index + 1,
                      child: _QuestionOptionButton(
                        label: options[index],
                        selected: _selected == options[index],
                        onTap: () {
                          setState(() {
                            _selected = options[index];
                          });
                        },
                      ),
                    ),
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                  ),
                ),
                _buildStaggeredReveal(
                  order: 6,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selected == null
                              ? const Color(0xFF707A8D)
                              : Colors.white,
                          foregroundColor: _selected == null
                              ? const Color(0xFFD7DCE7)
                              : Colors.black,
                          elevation: 0,
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: _selected == null
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  _OnboardingNoTransitionRoute<void>(
                                    builder: (_) =>
                                        const OnboardingFinalStepScreen(),
                                  ),
                                );
                              },
                        child: const Text('次へ'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingFinalStepScreen extends StatefulWidget {
  const OnboardingFinalStepScreen({super.key});

  @override
  State<OnboardingFinalStepScreen> createState() =>
      _OnboardingFinalStepScreenState();
}

class _OnboardingFinalStepScreenState extends State<OnboardingFinalStepScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _introController;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  Widget _buildStaggeredReveal({required int order, required Widget child}) {
    final double start = order * 0.08;
    final double end = (start + 0.52) > 1 ? 1 : (start + 0.52);
    final Animation<double> animation = CurvedAnimation(
      parent: _introController,
      curve: Interval(start, end, curve: Curves.easeOutQuart),
    );

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (BuildContext context, Widget? builtChild) {
        final double t = animation.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * -12),
            child: builtChild,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const int selfScore = 90;
    const int actualScore = 75;
    const int gapPercent = 20;

    return Scaffold(
      body: _OnboardingGradientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxHeight < 780;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const SizedBox(height: 8),
                            const _OnboardingTopBar(
                              currentStep: 6,
                              totalSteps: _kOnboardingGaugeSteps,
                            ),
                            SizedBox(height: compact ? 16 : 20),
                            _buildStaggeredReveal(
                              order: 0,
                              child: Text(
                                '多くの人は、自分の魅力を\n正確に認識していません',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: compact ? 26 : 31,
                                  height: 1.22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            SizedBox(height: compact ? 16 : 24),
                            _buildStaggeredReveal(
                              order: 1,
                              child: AnimatedBuilder(
                                animation: _introController,
                                builder: (BuildContext context, _) {
                                  return _FinalComparisonGraph(
                                    progress: Curves.easeOutCubic.transform(
                                      _introController.value,
                                    ),
                                    actualScore: actualScore,
                                    selfScore: selfScore,
                                    gapPercent: gapPercent,
                                    isPositiveGap: true,
                                    chartHeight: compact ? 320 : 370,
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: compact ? 14 : 20),
                            _buildStaggeredReveal(
                              order: 2,
                              child: Text(
                                '実際の評価と自己認識は平均で+$gapPercent%\nズレています',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: compact ? 18 : 23,
                                  fontWeight: FontWeight.w600,
                                  height: 1.36,
                                ),
                              ),
                            ),
                            SizedBox(height: compact ? 16 : 20),
                            _buildStaggeredReveal(
                              order: 3,
                              child: Text(
                                'Faceyはあなたの“魅力”を数値化し、\n具体的な改善ステップを提示します',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: compact ? 16 : 18,
                                  fontWeight: FontWeight.w500,
                                  height: 1.42,
                                ),
                              ),
                            ),
                            SizedBox(height: compact ? 16 : 22),
                          ],
                        ),
                      ),
                    ),
                    _buildStaggeredReveal(
                      order: 4,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: const StadiumBorder(),
                              textStyle: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                _OnboardingNoTransitionRoute<void>(
                                  builder: (_) =>
                                      const OnboardingExtraStepScreen(),
                                ),
                              );
                            },
                            child: const Text('次へ'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class OnboardingExtraStepScreen extends StatefulWidget {
  const OnboardingExtraStepScreen({super.key});

  @override
  State<OnboardingExtraStepScreen> createState() =>
      _OnboardingExtraStepScreenState();
}

class _OnboardingExtraStepScreenState extends State<OnboardingExtraStepScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _introController;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  Widget _buildStaggeredReveal({required int order, required Widget child}) {
    final double start = order * 0.08;
    final double end = (start + 0.46) > 1 ? 1 : (start + 0.46);
    final Animation<double> animation = CurvedAnimation(
      parent: _introController,
      curve: Interval(start, end, curve: Curves.easeOutQuart),
    );

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (BuildContext context, Widget? builtChild) {
        final double t = animation.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * -12),
            child: builtChild,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _OnboardingGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 8),
                const _OnboardingTopBar(
                  currentStep: 7,
                  totalSteps: _kOnboardingGaugeSteps,
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _buildStaggeredReveal(
                          order: 0,
                          child: const Text(
                            '外見は、設計できます。',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 31,
                              fontWeight: FontWeight.w700,
                              height: 1.22,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildStaggeredReveal(
                          order: 1,
                          child: const Text(
                            '外見は固定ではありません。\n'
                            '姿勢・表情・肌・意識や生活習慣などを改めることで印象は変化していきます。\n'
                            'Faceyは、その変化を記録します。',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: Color(0xFFD7E0F1),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildStaggeredReveal(
                          order: 2,
                          child: SizedBox(
                            height: 150,
                            width: double.infinity,
                            child: CustomPaint(
                              painter: _OnboardingGrowthArcPainter(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStaggeredReveal(
                          order: 3,
                          child: Row(
                            children: const <Widget>[
                              Expanded(
                                child: _OnboardingFeatureCard(
                                  icon: Icons.search_rounded,
                                  title: '観察する',
                                  subtitle: '印象・肌・コンディション\nを見える化',
                                  accent: Color(0xFF6BCAFF),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: _OnboardingFeatureCard(
                                  icon: Icons.tune_rounded,
                                  title: '調整する',
                                  subtitle: 'あなた用の\n改善ポイントを提案',
                                  accent: Color(0xFFB37BFF),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: _OnboardingFeatureCard(
                                  icon: Icons.trending_up_rounded,
                                  title: '伸ばす',
                                  subtitle: '変化をグラフ /\n履歴で確認',
                                  accent: Color(0xFF8BD7FF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
                _buildStaggeredReveal(
                  order: 4,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            _OnboardingNoTransitionRoute<void>(
                              builder: (_) => const OnboardingLastInfoScreen(),
                            ),
                          );
                        },
                        child: const Text('次へ'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingFeatureCard extends StatelessWidget {
  const _OnboardingFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF1B2540).withValues(alpha: 0.55),
        border: Border.all(
          color: const Color(0xFF6D86C5).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: <Color>[
                  accent.withValues(alpha: 0.75),
                  const Color(0xFF8D6EFF).withValues(alpha: 0.45),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB8C5E0),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.38,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingGrowthArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint track = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[
          Color(0xFF5B79C8),
          Color(0xFFC387FF),
          Color(0xFF78E1FF),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final Paint glow = Paint()
      ..color = const Color(0xFF9ED9FF).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final Path path = Path()
      ..moveTo(0, size.height * 0.84)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.82,
        size.width * 0.46,
        size.height * 0.62,
        size.width * 0.66,
        size.height * 0.44,
      )
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.34,
        size.width * 0.9,
        size.height * 0.24,
        size.width,
        size.height * 0.16,
      );

    canvas.drawPath(path, glow);
    canvas.drawPath(path, track);

    final List<Offset> dots = <Offset>[
      Offset(size.width * 0.14, size.height * 0.78),
      Offset(size.width * 0.39, size.height * 0.67),
      Offset(size.width * 0.62, size.height * 0.48),
      Offset(size.width * 0.84, size.height * 0.25),
    ];
    for (final Offset dot in dots) {
      final Paint dotPaint = Paint()..color = const Color(0xFFBDE8FF);
      final Paint dotGlow = Paint()
        ..color = const Color(0xFF9FE6FF).withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
      canvas.drawCircle(dot, 9, dotGlow);
      canvas.drawCircle(dot, 4, dotPaint);

      final Paint dash = Paint()
        ..color = const Color(0xFFAFBEDA).withValues(alpha: 0.45)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(dot.dx, dot.dy + 8),
        Offset(dot.dx, size.height - 6),
        dash,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class OnboardingLastInfoScreen extends StatefulWidget {
  const OnboardingLastInfoScreen({super.key});

  @override
  State<OnboardingLastInfoScreen> createState() =>
      _OnboardingLastInfoScreenState();
}

class _OnboardingLastInfoScreenState extends State<OnboardingLastInfoScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _introController;
  bool _didRequestReview = false;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestAppReviewIfPossible();
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  Widget _buildStaggeredReveal({required int order, required Widget child}) {
    final double start = order * 0.08;
    final double end = (start + 0.46) > 1 ? 1 : (start + 0.46);
    final Animation<double> animation = CurvedAnimation(
      parent: _introController,
      curve: Interval(start, end, curve: Curves.easeOutQuart),
    );

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (BuildContext context, Widget? builtChild) {
        final double t = animation.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * -12),
            child: builtChild,
          ),
        );
      },
    );
  }

  Future<void> _requestAppReviewIfPossible() async {
    if (_didRequestReview || !mounted) return;
    _didRequestReview = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      final InAppReview inAppReview = InAppReview.instance;
      final bool available = await inAppReview.isAvailable();
      if (!available || !mounted) return;
      await inAppReview.requestReview();
    } catch (_) {
      // Ignore: review prompt availability depends on store-side conditions.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _OnboardingGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 8),
                const _OnboardingTopBar(
                  currentStep: 8,
                  totalSteps: _kOnboardingGaugeSteps,
                ),
                const SizedBox(height: 20),
                _buildStaggeredReveal(
                  order: 0,
                  child: const Text(
                    'ユーザー体験をもとに改善されています',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _buildStaggeredReveal(
                  order: 1,
                  child: const Text(
                    'Faceyは数多くのテストを通して設計されています。',
                    style: TextStyle(
                      color: Color(0xFFE2E8F3),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),

                Expanded(
                  child: _buildStaggeredReveal(
                    order: 2,
                    child: Align(
                      alignment: const Alignment(0, -0.7),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Image.asset(
                            'assets/images/めっも.png',
                            width: 250,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 15),
                          Image.asset(
                            'assets/images/おかmw.png',
                            width: 250,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildStaggeredReveal(
                  order: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            _OnboardingNoTransitionRoute<void>(
                              builder: (_) => const OnboardingLastDoneScreen(),
                            ),
                          );
                        },
                        child: const Text('次へ'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingLastDoneScreen extends StatefulWidget {
  const OnboardingLastDoneScreen({super.key});

  @override
  State<OnboardingLastDoneScreen> createState() =>
      _OnboardingLastDoneScreenState();
}

class _OnboardingLastDoneScreenState extends State<OnboardingLastDoneScreen> {
  bool _didRequestNotificationPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestNotificationPermissionIfNeeded();
    });
  }

  Future<void> _requestNotificationPermissionIfNeeded() async {
    if (_didRequestNotificationPermission || !mounted) return;
    _didRequestNotificationPermission = true;
    try {
      await Permission.notification.request();
    } catch (_) {
      // Ignore and keep onboarding flow stable.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _OnboardingGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 8),
                const _OnboardingTopBar(
                  currentStep: 9,
                  totalSteps: _kOnboardingGaugeSteps,
                ),
                const SizedBox(height: 20),
                const Text(
                  '通知を許可してください',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Faceyからのお知らせを受け取れます。',
                  style: TextStyle(
                    color: Color(0xFFE2E8F3),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: const Alignment(0, -0.34),
                    child: Image.asset(
                      'assets/images/ルチお.png',
                      width: 270,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          _OnboardingNoTransitionRoute<void>(
                            builder: (_) => const OnboardingOptimizingScreen(),
                          ),
                        );
                      },
                      child: const Text('次へ'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingOptimizingScreen extends StatefulWidget {
  const OnboardingOptimizingScreen({super.key});

  @override
  State<OnboardingOptimizingScreen> createState() =>
      _OnboardingOptimizingScreenState();
}

class _OnboardingOptimizingScreenState extends State<OnboardingOptimizingScreen>
    with TickerProviderStateMixin {
  final Random _random = Random();
  late final AnimationController _progressController;
  late final AnimationController _blinkController;
  late final AnimationController _ringSpinController;
  Timer? _progressTimer;
  bool _isFinalizingProgress = false;
  double _progressPhase = 0;
  String _statusDetail = 'プロファイルを初期化中';
  int _statusIndex = 0;
  DateTime _lastStatusChangedAt = DateTime.now();

  static const List<String> _statusDetails = <String>[
    'プロファイルを初期化中',
    'フェイスエンジンを起動中',
    '魅力モデルを読み込み中',
    'パーソナルデータを同期中',
    '印象データを最適化中',
    '成長トラッキングを準備中',
  ];

  @override
  void initState() {
    super.initState();
    final bool alreadyCompleted = _OnboardingOptimizingMemory.completed;
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1),
      value: alreadyCompleted ? 1 : 0.04,
    );
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _ringSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
    if (alreadyCompleted) {
      _statusDetail = '環境構築が完了しました';
      _isFinalizingProgress = true;
      return;
    }
    _scheduleNextProgressStep();
  }

  void _scheduleNextProgressStep() {
    _progressTimer?.cancel();
    final double current = _progressController.value;
    if (!mounted || current >= 1) return;
    if (_isFinalizingProgress) return;

    if (current >= 0.96) {
      _isFinalizingProgress = true;
      _statusDetail = '最終チェック中';
      _progressTimer = Timer(
        Duration(milliseconds: 350 + _random.nextInt(350)),
        () {
          if (!mounted) return;
          _progressController
              .animateTo(
                1,
                duration: const Duration(milliseconds: 620),
                curve: Curves.easeOutCubic,
              )
              .whenComplete(() {
                if (!mounted) return;
                setState(() {
                  _statusDetail = '環境構築が完了しました';
                });
                _OnboardingOptimizingMemory.completed = true;
              });
        },
      );
      setState(() {});
      return;
    }

    final double baseStep = current < 0.32
        ? 0.04
        : current < 0.72
        ? 0.025
        : 0.013;
    _progressPhase += 0.72 + (_random.nextDouble() * 0.18);
    final double wave = sin(_progressPhase) * baseStep * 0.26;
    final double jitter = (_random.nextDouble() - 0.5) * baseStep * 0.24;
    final double delta = (baseStep + wave + jitter).clamp(0.004, 0.04);
    final double target = (current + delta).clamp(0.0, 0.965);
    final int moveMs = current < 0.72
        ? 220 + _random.nextInt(100)
        : 260 + _random.nextInt(120);
    final int gapMs = 45 + _random.nextInt(45);

    final DateTime now = DateTime.now();
    final bool canChangeStatus =
        now.difference(_lastStatusChangedAt).inMilliseconds >= 1400;
    if (canChangeStatus) {
      setState(() {
        _statusIndex = (_statusIndex + 1) % _statusDetails.length;
        _statusDetail = _statusDetails[_statusIndex];
        _lastStatusChangedAt = now;
      });
    }
    _progressController
        .animateTo(
          target,
          duration: Duration(milliseconds: moveMs),
          curve: Curves.easeInOutCubic,
        )
        .whenComplete(() {
          if (!mounted) return;
          _progressTimer = Timer(Duration(milliseconds: gapMs), () {
            if (!mounted) return;
            _scheduleNextProgressStep();
          });
        });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _progressController.dispose();
    _blinkController.dispose();
    _ringSpinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _OnboardingGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 8),
                const _OnboardingTopBar(
                  currentStep: 10,
                  totalSteps: _kOnboardingGaugeSteps,
                ),
                const Spacer(flex: 1),
                const SizedBox(height: 4),
                const Text(
                  'あなたの印象は、\nここから変わります。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: Listenable.merge(<Listenable>[
                    _blinkController,
                    _progressController,
                  ]),
                  builder: (BuildContext context, _) {
                    final bool done = _progressController.value >= 1;
                    return Opacity(
                      opacity: done
                          ? 1
                          : (0.35 + (_blinkController.value * 0.65)),
                      child: Text(
                        done ? '準備完了' : _statusDetail,
                        style: const TextStyle(
                          color: Color(0xFFAFB8CB),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                AnimatedBuilder(
                  animation: Listenable.merge(<Listenable>[
                    _progressController,
                    _ringSpinController,
                  ]),
                  builder: (BuildContext context, _) {
                    final double progress = _progressController.value;
                    return _FuturisticLoadingRing(
                      progress: progress,
                      spinValue: _ringSpinController.value,
                    );
                  },
                ),
                const SizedBox(height: 30),
                const Spacer(flex: 2),
                AnimatedBuilder(
                  animation: _progressController,
                  builder: (BuildContext context, _) {
                    final bool done = _progressController.value >= 1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: done
                                ? Colors.white
                                : const Color(0xFF8E95A6),
                            foregroundColor: done
                                ? Colors.black
                                : const Color(0xFFE2E6EF),
                            elevation: 0,
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: done
                              ? () async {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    _OnboardingFinishRoute<void>(
                                      builder: (_) => const UpgradeScreen(),
                                    ),
                                    (Route<dynamic> route) => false,
                                  );
                                }
                              : null,
                          child: const Text('完了'),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingFinishImageScreen extends StatelessWidget {
  const OnboardingFinishImageScreen({super.key});

  void _close(BuildContext context) {
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return PaymentPageScaffold(onClose: () => _close(context));
  }
}

class _FuturisticLoadingRing extends StatelessWidget {
  const _FuturisticLoadingRing({
    required this.progress,
    required this.spinValue,
  });

  final double progress;
  final double spinValue;

  @override
  Widget build(BuildContext context) {
    final int percent = (progress * 100).round().clamp(0, 100);
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: 154,
            height: 154,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  const Color(0xFF5E7BFF).withValues(alpha: 0.16),
                  const Color(0xFF8561FF).withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          SizedBox(
            width: 228,
            height: 228,
            child: CustomPaint(
              painter: _FuturisticSpinnerPainter(
                progress: progress,
                spinValue: spinValue,
              ),
            ),
          ),
          Text(
            '$percent%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _FuturisticSpinnerPainter extends CustomPainter {
  _FuturisticSpinnerPainter({required this.progress, required this.spinValue});

  final double progress;
  final double spinValue;

  @override
  void paint(Canvas canvas, Size size) {
    const int spokeCount = 22;
    const double stroke = 12;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double clampedProgress = progress.clamp(0.0, 1.0);
    final double colorBoost = Curves.easeOutCubic.transform(clampedProgress);
    final double filledRaw = spokeCount * clampedProgress;
    final int fullCount = filledRaw.floor().clamp(0, spokeCount);
    final double partial = (filledRaw - fullCount).clamp(0.0, 1.0);
    final int shimmerOffset = ((spinValue * spokeCount).floor()) % spokeCount;
    final double startRadius = size.width * 0.34;
    final double baseLength = size.width * 0.115;

    for (int i = 0; i < spokeCount; i++) {
      final bool full = i < fullCount;
      final bool partialFill = i == fullCount && fullCount < spokeCount;
      final double fillLevel = full
          ? 1.0
          : partialFill
          ? partial
          : 0.0;
      final int distanceFromShimmer =
          (i - (fullCount + shimmerOffset) + spokeCount) % spokeCount;
      final double shimmer = fillLevel > 0 && distanceFromShimmer <= 1
          ? (0.12 + (0.12 * colorBoost))
          : 0.0;
      final double intensity = (fillLevel * 0.9) + shimmer;
      final double angle = (-pi / 2) + ((2 * pi * i) / spokeCount);
      final double length =
          baseLength + ((fillLevel > 0 ? 1.0 : 0.0) * size.width * 0.022);
      final double hue = (215 + ((i / spokeCount) * 65)) % 360;
      final Color litColor = HSLColor.fromAHSL(
        1,
        hue,
        0.46 + (0.5 * colorBoost),
        0.58 + (0.2 * colorBoost),
      ).toColor();
      final Color baseColor = Color.lerp(
        const Color(0xFF2E3442),
        const Color(0xFF3D4A68),
        colorBoost * 0.62,
      )!;
      final Offset from = Offset(
        center.dx + cos(angle) * startRadius,
        center.dy + sin(angle) * startRadius,
      );
      final Offset to = Offset(
        center.dx + cos(angle) * (startRadius + length),
        center.dy + sin(angle) * (startRadius + length),
      );

      if (fillLevel > 0.02 && intensity > 0.62) {
        final Paint glow = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke + 3.8
          ..strokeCap = StrokeCap.round
          ..color = litColor.withValues(
            alpha: (0.22 + (0.26 * colorBoost)) * intensity,
          )
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5.5);
        canvas.drawLine(from, to, glow);
      }

      final double blend = (0.08 + (0.92 * intensity)).clamp(0.0, 1.0);
      final Paint spoke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = Color.lerp(
          baseColor,
          litColor,
          blend,
        )!.withValues(alpha: 0.2 + (0.26 * colorBoost) + (0.54 * intensity));
      canvas.drawLine(from, to, spoke);
    }
  }

  @override
  bool shouldRepaint(covariant _FuturisticSpinnerPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.spinValue != spinValue;
}

class _FinalComparisonGraph extends StatelessWidget {
  const _FinalComparisonGraph({
    required this.progress,
    required this.actualScore,
    required this.selfScore,
    required this.gapPercent,
    required this.isPositiveGap,
    required this.chartHeight,
  });

  final double progress;
  final int actualScore;
  final int selfScore;
  final int gapPercent;
  final bool isPositiveGap;
  final double chartHeight;

  @override
  Widget build(BuildContext context) {
    const double maxValue = 140;
    final double actualFactor = (actualScore / maxValue).clamp(0.12, 1.0);
    final double selfFactor = ((selfScore / maxValue) * 1.14).clamp(0.12, 1.0);

    return SizedBox(
      height: chartHeight,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double w = constraints.maxWidth;
          final double h = constraints.maxHeight;
          const double labelBottomPadding = 12;
          final double axisY = h - 70;
          final double maxBarH = h - 118;
          final double barW = 86;
          final double leftX = 36;
          final double rightX = w - barW - 36;
          final double actualH = maxBarH * actualFactor * progress;
          final double selfH = maxBarH * selfFactor * progress;
          final double actualTopY = axisY - actualH;
          final double selfTopY = axisY - selfH;

          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Colors.white.withValues(alpha: 0.06),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                top: axisY,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6CC3FF).withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Positioned(
                left: leftX,
                top: actualTopY,
                child: _GlowBar(
                  width: barW,
                  height: actualH,
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: <Color>[Color(0xFF2D9CFF), Color(0xFFA34EFF)],
                  ),
                  value: actualScore,
                ),
              ),
              Positioned(
                left: rightX,
                top: selfTopY,
                child: _GlowBar(
                  width: barW,
                  height: selfH,
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: <Color>[Color(0xFF7B7DFF), Color(0xFFFF4FB0)],
                  ),
                  value: selfScore,
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _ChartLinePainter(
                    progress: progress,
                    from: Offset(leftX + barW * 0.5, actualTopY),
                    to: Offset(rightX + barW * 0.5, selfTopY),
                    lineColor: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ),
              Positioned(
                left: leftX + barW * 0.48,
                top: selfTopY - 54,
                child: Transform.translate(
                  offset: Offset((rightX - leftX) * 0.44, 0),
                  child: Opacity(
                    opacity: progress.clamp(0.0, 1.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2246).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFBF8BFF)),
                      ),
                      child: Text(
                        '${isPositiveGap ? '+' : '-'}$gapPercent%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                bottom: labelBottomPadding,
                width: (w - 16) / 2,
                child: const Text(
                  '実際の見た目',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Positioned(
                right: 8,
                bottom: labelBottomPadding,
                width: (w - 16) / 2,
                child: const Text(
                  '自己認識',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GlowBar extends StatelessWidget {
  const _GlowBar({
    required this.width,
    required this.height,
    required this.gradient,
    required this.value,
  });

  final double width;
  final double height;
  final Gradient gradient;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: gradient,
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.22),
            blurRadius: 18,
            spreadRadius: 0.4,
          ),
        ],
      ),
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        '$value',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ChartLinePainter extends CustomPainter {
  const _ChartLinePainter({
    required this.progress,
    required this.from,
    required this.to,
    required this.lineColor,
  });

  final double progress;
  final Offset from;
  final Offset to;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint curvedPaint = Paint()
      ..color = const Color(0xFFC76BFF).withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final Path curvePath = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(
        from.dx + (to.dx - from.dx) * 0.52,
        from.dy - 88,
        to.dx,
        to.dy - 2,
      );

    final metric = curvePath.computeMetrics().first;
    final Path partialCurve = metric.extractPath(
      0,
      metric.length * progress.clamp(0.0, 1.0),
    );
    canvas.drawPath(partialCurve, curvedPaint);

    final Paint dashedPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final int dashCount = 18;
    for (int i = 0; i < dashCount; i++) {
      final double t0 = i / dashCount;
      final double t1 = (i + 0.5) / dashCount;
      final Offset p0 = Offset.lerp(from, to, t0)!;
      final Offset p1 = Offset.lerp(from, to, t1)!;
      if (t0 > progress) break;
      canvas.drawLine(p0, p1, dashedPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartLinePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.from != from ||
        oldDelegate.to != to ||
        oldDelegate.lineColor != lineColor;
  }
}

class _PerceptionOptionButton extends StatelessWidget {
  const _PerceptionOptionButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: selected
              ? const Color(0xFF000000)
              : const Color.fromARGB(255, 222, 221, 221),
          foregroundColor: selected
              ? const Color(0xFFF7F8FC)
              : const Color(0xFF101216),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: selected
                    ? const Color(0xFFF7F8FC)
                    : const Color(0xFF15171C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionOptionButton extends StatelessWidget {
  const _QuestionOptionButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.lightTheme = false,
    this.purpleStyle = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool lightTheme;
  final bool purpleStyle;

  @override
  Widget build(BuildContext context) {
    if (purpleStyle) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFFD5B9FF)
                  : const Color(0xFFA983FF),
              width: selected ? 1.8 : 1.2,
            ),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: <Color>[Color(0xFF5B22FF), Color(0xFFB61DFF)],
            ),
          ),
          child: TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(label),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected
              ? const Color(0xFF000000)
              : const Color.fromARGB(255, 222, 221, 221),
          side: const BorderSide(color: Colors.transparent, width: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          foregroundColor: selected
              ? const Color(0xFFF7F8FC)
              : const Color(0xFF15171C),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}
