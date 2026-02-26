import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:permission_handler/permission_handler.dart';

import '../main.dart';
import 'payment_page_scaffold.dart';
import '../routes/no_swipe_back_material_page_route.dart';

const int _kOnboardingGaugeSteps = 9;
final RouteObserver<PageRoute<dynamic>> onboardingRouteObserver =
    RouteObserver<PageRoute<dynamic>>();

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFF10151D),
              Color(0xFF222C3B),
              Color(0xFF364B68),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFF10151D),
              Color(0xFF222C3B),
              Color(0xFF364B68),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
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
                    child: Text(
                      'あなたの評価',
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
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.topCenter,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.only(top: 150),
                                    child: Column(
                                      children: <Widget>[
                                        Stack(
                                          alignment: Alignment.center,
                                          children: <Widget>[
                                            Container(
                                              height: 6,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                                gradient: const LinearGradient(
                                                  colors: <Color>[
                                                    Color(0xFFCC2CFF),
                                                    Color(0xFF35D8FF),
                                                  ],
                                                ),
                                                boxShadow: const <BoxShadow>[
                                                  BoxShadow(
                                                    color: Color(0x6635D8FF),
                                                    blurRadius: 14,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              height: 14,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: List<Widget>.generate(
                                                  40,
                                                  (_) => Container(
                                                    width: 2,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.5,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            99,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SliderTheme(
                                              data: SliderTheme.of(context).copyWith(
                                                trackHeight: 20,
                                                trackShape:
                                                    const _FullWidthTrackShape(),
                                                activeTrackColor:
                                                    Colors.transparent,
                                                inactiveTrackColor:
                                                    Colors.transparent,
                                                overlayColor:
                                                    Colors.transparent,
                                                thumbColor: const Color(
                                                  0xFFDDF6FF,
                                                ),
                                                thumbShape:
                                                    const RoundSliderThumbShape(
                                                      enabledThumbRadius: 14,
                                                    ),
                                              ),
                                              child: Slider(
                                                value: _score,
                                                min: 0,
                                                max: 100,
                                                onChanged: (double value) {
                                                  setState(() {
                                                    _score = value;
                                                    _hasMovedSlider = true;
                                                    _OnboardingEvaluationMemory
                                                            .score =
                                                        value;
                                                    _OnboardingEvaluationMemory
                                                            .hasMovedSlider =
                                                        true;
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
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
                                  DecoratedBox(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: SweepGradient(
                                        colors: <Color>[
                                          Color(0xFF35D8FF),
                                          Color(0xFF6E45FF),
                                          Color(0xFFFF50CF),
                                          Color(0xFFFFD06E),
                                          Color(0xFF35D8FF),
                                        ],
                                      ),
                                      boxShadow: <BoxShadow>[
                                        BoxShadow(
                                          color: Color(0x6635D8FF),
                                          blurRadius: 24,
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(3),
                                      child: Container(
                                        width: 108,
                                        height: 108,
                                        alignment: Alignment.center,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF0A0D14),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          _score.round().toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 30,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFF10151D),
              Color(0xFF222C3B),
              Color(0xFF364B68),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFF10151D),
              Color(0xFF222C3B),
              Color(0xFF364B68),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
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
      '友達止まり',
      '興味持たれにくい',
      'わからない',
    ];
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFF10151D),
              Color(0xFF222C3B),
              Color(0xFF364B68),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFF10151D),
              Color(0xFF222C3B),
              Color(0xFF364B68),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFF10151D),
              Color(0xFF222C3B),
              Color(0xFF364B68),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
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
                                '実際の評価と自己認識は平均で+$gapPercent%ズレています',
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
                                      const OnboardingLastInfoScreen(),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFF10151D),
              Color(0xFF222C3B),
              Color(0xFF364B68),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 8),
                const _OnboardingTopBar(
                  currentStep: 7,
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
                            'assets/images/声.png',
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFF10151D),
              Color(0xFF222C3B),
              Color(0xFF364B68),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
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
  Timer? _progressTimer;
  bool _isFinalizingProgress = false;
  double _progressPhase = 0;
  String _statusDetail = 'プロファイルを初期化中';
  DateTime _lastStatusChangedAt = DateTime.now();

  static const List<String> _statusDetails = <String>[
    'プロファイルを初期化中',
    '最適な体験をチューニング',
    '推奨設定を調整中',
    '通知設定を最適化中',
    '体験を最適化',
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
        now.difference(_lastStatusChangedAt).inMilliseconds >= 1800;
    final bool shouldChangeStatus =
        canChangeStatus && _random.nextDouble() < 0.52;
    if (shouldChangeStatus) {
      setState(() {
        _statusDetail = _statusDetails[_random.nextInt(_statusDetails.length)];
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFF10151D),
              Color(0xFF222C3B),
              Color(0xFF364B68),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 8),
                const _OnboardingTopBar(
                  currentStep: 9,
                  totalSteps: _kOnboardingGaugeSteps,
                ),
                const Spacer(flex: 1),
                AnimatedBuilder(
                  animation: Listenable.merge(<Listenable>[
                    _progressController,
                    _blinkController,
                  ]),
                  builder: (BuildContext context, _) {
                    final bool done = _progressController.value >= 1;
                    final double opacity = done
                        ? 1
                        : (0.35 + (_blinkController.value * 0.65));
                    return Opacity(
                      opacity: opacity,
                      child: Text(
                        done ? '準備ok' : '準備中',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                const Text(
                  'あなたに合わせた環境を構築しています',
                  style: TextStyle(
                    color: Color(0xFFD2D9E8),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: Text(
                    _statusDetail,
                    key: ValueKey<String>(_statusDetail),
                    style: const TextStyle(
                      color: Color(0xFFAFB8CB),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                AnimatedBuilder(
                  animation: _progressController,
                  builder: (BuildContext context, _) {
                    final double progress = _progressController.value;
                    final int percent = (progress * 100).round().clamp(0, 100);
                    return ClipRRect(
                      child: SizedBox(
                        width: 246,
                        height: 246,
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            Container(
                              width: 216,
                              height: 216,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: <Color>[
                                    const Color(
                                      0xFF7E6DFF,
                                    ).withValues(alpha: 0.18),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 186,
                              height: 186,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 12,
                                strokeCap: StrokeCap.round,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.16,
                                ),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFBE79FF),
                                ),
                              ),
                            ),
                            Container(
                              width: 152,
                              height: 152,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  colors: <Color>[
                                    Color(0xFF2B2441),
                                    Color(0xFF171D2C),
                                  ],
                                ),
                              ),
                            ),
                            Text(
                              '$percent%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                                  final bool? closeToHome =
                                      await Navigator.of(context).push<bool>(
                                        _OnboardingFinishRoute<bool>(
                                          builder: (_) =>
                                              const OnboardingFinishImageScreen(),
                                        ),
                                      );
                                  if (!context.mounted || closeToHome != true) {
                                    return;
                                  }
                                  Navigator.of(context).pushAndRemoveUntil(
                                    _OnboardingNoTransitionRoute<void>(
                                      builder: (_) => const HomeScreen(),
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
