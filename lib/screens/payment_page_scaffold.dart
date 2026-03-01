import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentPageScaffold extends StatefulWidget {
  const PaymentPageScaffold({
    super.key,
    required this.onClose,
    this.content,
    this.backgroundImagePath = 'assets/images/引きそ.png',
    this.useAppGradientBackground = false,
    this.closeAlignment = Alignment.topRight,
    this.closePadding = const EdgeInsets.only(top: 8, right: 8),
    this.closeIcon = const Icon(Icons.close, color: Colors.white, size: 23),
    this.backgroundFit = BoxFit.cover,
    this.title = 'Facey AI',
    this.subtitle = '『今の自分をレベルアップしよう😎』',
  });

  final VoidCallback onClose;
  final Widget? content;
  final String backgroundImagePath;
  final bool useAppGradientBackground;
  final Alignment closeAlignment;
  final EdgeInsets closePadding;
  final Widget closeIcon;
  final BoxFit backgroundFit;
  final String title;
  final String subtitle;

  @override
  State<PaymentPageScaffold> createState() => _PaymentPageScaffoldState();
}

class _PaymentPageScaffoldState extends State<PaymentPageScaffold>
    with SingleTickerProviderStateMixin {
  static const int _cardCount = 4;
  static final Uri _privacyPolicyUrl = Uri.parse(
    'https://mercury-ixora-4df.notion.site/30ab9bad745580b89262d3bead931a6b',
  );
  static final Uri _termsUrl = Uri.parse(
    'https://mercury-ixora-4df.notion.site/Facey-30ab9bad745580b78192d675b7fa6b1b',
  );
  late final PageController _cardsController;
  late final AnimationController _enterController;
  int _activeCardIndex = 0;

  @override
  void initState() {
    super.initState();
    _cardsController = PageController(viewportFraction: 0.92);
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _enterController.forward();
  }

  @override
  void dispose() {
    _cardsController.dispose();
    _enterController.dispose();
    super.dispose();
  }

  Widget _buildStaggeredReveal({required int order, required Widget child}) {
    final double start = (order * 0.07).clamp(0.0, 0.86);
    final double end = (start + 0.62).clamp(start + 0.01, 1.0);
    final Animation<double> animation = CurvedAnimation(
      parent: _enterController,
      curve: Interval(start, end, curve: Curves.easeOutSine),
    );

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (BuildContext context, Widget? child) {
        final double t = animation.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 8),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: widget.useAppGradientBackground
                ? const _AppGradientBackground()
                : Image.asset(
                    widget.backgroundImagePath,
                    fit: widget.backgroundFit,
                  ),
          ),
          if (widget.content != null)
            SafeArea(
              child: Align(
                alignment: widget.closeAlignment,
                child: Padding(
                  padding: widget.closePadding,
                  child: IconButton(
                    onPressed: widget.onClose,
                    icon: widget.closeIcon,
                  ),
                ),
              ),
            ),
          if (widget.content == null)
            SafeArea(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double cardHeight = (constraints.maxHeight * 0.48)
                      .clamp(320.0, 500.0);
                  final double cardWidth = constraints.maxWidth - 32;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Positioned.fill(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 100),
                          child: Column(
                            children: <Widget>[
                              _buildStaggeredReveal(
                                order: 0,
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: Padding(
                                    padding: widget.closePadding,
                                    child: IconButton(
                                      onPressed: widget.onClose,
                                      icon: widget.closeIcon,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                ),
                                child: Transform.translate(
                                  offset: const Offset(0, -38),
                                  child: Column(
                                    children: <Widget>[
                                      const SizedBox(height: 28),
                                      _buildStaggeredReveal(
                                        order: 1,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            widget.title,
                                            maxLines: 1,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 33,
                                              fontFamily:
                                                  'Hiragino Kaku Gothic ProN',
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.2,
                                              height: 1.02,
                                              shadows: <Shadow>[
                                                Shadow(
                                                  color: Color(0x50000000),
                                                  blurRadius: 2,
                                                  offset: Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      _buildStaggeredReveal(
                                        order: 2,
                                        child: Text(
                                          widget.subtitle,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xFF9FB3D9),
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 30),
                                      _buildStaggeredReveal(
                                        order: 3,
                                        child: SizedBox(
                                          width: cardWidth,
                                          height: cardHeight + 96,
                                          child: Column(
                                            children: <Widget>[
                                              SizedBox(
                                                height: cardHeight,
                                                child: PageView.builder(
                                                  controller: _cardsController,
                                                  itemCount: _cardCount,
                                                  onPageChanged: (int index) {
                                                    setState(() {
                                                      _activeCardIndex = index;
                                                    });
                                                  },
                                                  itemBuilder: (BuildContext context, int index) {
                                                    final BorderRadius radius =
                                                        BorderRadius.circular(
                                                          34,
                                                        );
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                          ),
                                                      child: Container(
                                                        width: double.infinity,
                                                        decoration: BoxDecoration(
                                                          borderRadius: radius,
                                                          gradient:
                                                              const LinearGradient(
                                                                begin: Alignment
                                                                    .topLeft,
                                                                end: Alignment
                                                                    .bottomRight,
                                                                colors: <Color>[
                                                                  Color(
                                                                    0xAA111826,
                                                                  ),
                                                                  Color(
                                                                    0xCC0A1222,
                                                                  ),
                                                                ],
                                                              ),
                                                          border: Border.all(
                                                            color: Colors.white
                                                                .withValues(
                                                                  alpha: 0.06,
                                                                ),
                                                          ),
                                                          boxShadow:
                                                              const <BoxShadow>[
                                                                BoxShadow(
                                                                  color: Color(
                                                                    0x66000000,
                                                                  ),
                                                                  blurRadius:
                                                                      24,
                                                                  offset:
                                                                      Offset(
                                                                        0,
                                                                        10,
                                                                      ),
                                                                ),
                                                              ],
                                                        ),
                                                        child: ClipRRect(
                                                          borderRadius: radius,
                                                          child: index == 0
                                                              ? LayoutBuilder(
                                                                  builder:
                                                                      (
                                                                        BuildContext
                                                                        context,
                                                                        BoxConstraints
                                                                        constraints,
                                                                      ) {
                                                                        return Stack(
                                                                          children:
                                                                              <
                                                                                Widget
                                                                              >[
                                                                                const Positioned(
                                                                                  left: 0,
                                                                                  right: 25,
                                                                                  top: 55,
                                                                                  child: Text(
                                                                                    'AIによるフィードバック',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                      color: Colors.white,
                                                                                      fontSize: 20,
                                                                                      fontFamily: 'Hiragino Kaku Gothic ProN',
                                                                                      fontWeight: FontWeight.w900,
                                                                                      letterSpacing: 0.1,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                Align(
                                                                                  alignment: const Alignment(
                                                                                    0,
                                                                                    1.6,
                                                                                  ),
                                                                                  child: SizedBox(
                                                                                    width:
                                                                                        constraints.maxWidth *
                                                                                        0.87,
                                                                                    height:
                                                                                        constraints.maxHeight *
                                                                                        0.87,
                                                                                    child: Image.asset(
                                                                                      'assets/images/oka.png',
                                                                                      fit: BoxFit.contain,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                        );
                                                                      },
                                                                )
                                                              : const SizedBox.shrink(),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: List<Widget>.generate(
                                                  _cardCount,
                                                  (int dotIndex) => Container(
                                                    width: 8,
                                                    height: 8,
                                                    margin:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color:
                                                          _activeCardIndex ==
                                                              dotIndex
                                                          ? Colors.white
                                                          : Colors.white
                                                                .withValues(
                                                                  alpha: 0.32,
                                                                ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                              Text(
                                                '多くの実データから導かれた評価ロジックです。',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.36),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 30),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 170,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[
                                  Color(0x00000610),
                                  Color(0x26000610),
                                  Color(0x5A000610),
                                  Color(0x8C000610),
                                ],
                                stops: <double>[0.0, 0.36, 0.72, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                      _buildStaggeredReveal(
                        order: 4,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(22, 0, 22, 50),
                            child: SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2F4CF6),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(44),
                                  ),
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 50 / 3,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.1,
                                    ),
                                    children: <InlineSpan>[
                                      const TextSpan(text: 'アップグレード'),
                                      WidgetSpan(
                                        alignment:
                                            PlaceholderAlignment.baseline,
                                        baseline: TextBaseline.alphabetic,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 2.4,
                                          ),
                                          child: Transform.translate(
                                            offset: const Offset(0, -1.5),
                                            child: const Text(
                                              '🙌',
                                              style: TextStyle(fontSize: 21),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 18,
                        child: _buildStaggeredReveal(
                          order: 5,
                          child: Center(
                            child: Text(
                              '¥1500/月',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: -7,
                        child: _buildStaggeredReveal(
                          order: 6,
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Center(
                                  child: TextButton(
                                    onPressed: () async {
                                      await launchUrl(
                                        _termsUrl,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      minimumSize: Size.zero,
                                      padding: EdgeInsets.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Terms of Use',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.fade,
                                      softWrap: false,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      minimumSize: Size.zero,
                                      padding: EdgeInsets.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Restore Purchase',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.fade,
                                      softWrap: false,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: TextButton(
                                    onPressed: () async {
                                      await launchUrl(
                                        _privacyPolicyUrl,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      minimumSize: Size.zero,
                                      padding: EdgeInsets.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Privacy Policy',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.fade,
                                      softWrap: false,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          if (widget.content != null) SafeArea(child: widget.content!),
        ],
      ),
    );
  }
}

class _AppGradientBackground extends StatelessWidget {
  const _AppGradientBackground();

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
      ],
    );
  }
}
