import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum YomuGender { male, female }

class YomuGenderTwoChoice extends StatefulWidget {
  const YomuGenderTwoChoice({
    super.key,
    this.title = '性別を選択',
    this.onChanged,
    this.initialValue = YomuGender.male,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 0),
    this.topGap = 26,
    this.titleBottomGap = 10,
    this.cardsTopGap = 14,
    this.gap = 18,
    this.wholeOffset = const Offset(0, -29),
    this.titleOffset = const Offset(0, -10),
    this.titlePadding = EdgeInsets.zero,
    this.cardsOffset = const Offset(0, 3),
    this.labelsOffset = const Offset(0, 2),
    this.cardSize = 150,
    this.radius = 18,
    this.cardInnerPad = 10,
    this.iconSize = 42,
    this.femaleIcon = Icons.female_rounded,
    this.maleIcon = Icons.male_rounded,
    this.femaleSelectedBg = const Color(0xFFE86B8C),
    this.maleSelectedBg = const Color(0xFF6FA6DD),
    this.femaleAccent = const Color(0xFFE86B8C),
    this.maleAccent = const Color(0xFF6FA6DD),
    this.unselectedBg = Colors.white,
    this.unselectedBorderColor = const Color(0xFFE9E9EF),
    this.unselectedBorderWidth = 1.2,
    this.shadowBlur = 18,
    this.shadowY = 10,
    this.shadowOpacityUnselected = 0.08,
    this.shadowOpacitySelected = 0.10,
    this.labelTopGap = 12,
    this.femaleLabel = '女性',
    this.maleLabel = '男性',
    this.labelStyle,
    this.showTitle = true,
    this.titleStyle,
  });

  final String title;
  final ValueChanged<YomuGender>? onChanged;
  final YomuGender initialValue;

  final EdgeInsets padding;
  final double topGap;
  final double titleBottomGap;
  final double cardsTopGap;
  final double gap;

  final Offset wholeOffset;
  final Offset titleOffset;
  final EdgeInsets titlePadding;
  final Offset cardsOffset;
  final Offset labelsOffset;

  final double cardSize;
  final double radius;
  final double cardInnerPad;

  final double iconSize;
  final IconData femaleIcon;
  final IconData maleIcon;

  final Color femaleSelectedBg;
  final Color maleSelectedBg;
  final Color femaleAccent;
  final Color maleAccent;
  final Color unselectedBg;
  final Color unselectedBorderColor;
  final double unselectedBorderWidth;

  final double shadowBlur;
  final double shadowY;
  final double shadowOpacityUnselected;
  final double shadowOpacitySelected;

  final double labelTopGap;
  final String femaleLabel;
  final String maleLabel;
  final TextStyle? labelStyle;

  final bool showTitle;
  final TextStyle? titleStyle;

  @override
  State<YomuGenderTwoChoice> createState() => _YomuGenderTwoChoiceState();
}

class _YomuGenderTwoChoiceState extends State<YomuGenderTwoChoice> {
  late YomuGender _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialValue;
  }

  void _setGender(YomuGender next) {
    if (_current == next) return;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.lightImpact();
    }
    setState(() {
      _current = next;
    });
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final tStyle =
        widget.titleStyle ??
        TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: Colors.black.withValues(alpha: 0.78),
          letterSpacing: 0.2,
        );

    final lStyle =
        widget.labelStyle ??
        TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: Colors.white.withValues(alpha: 0.92),
          letterSpacing: 0.1,
        );

    return Transform.translate(
      offset: widget.wholeOffset,
      child: Padding(
        padding: widget.padding,
        child: LayoutBuilder(
          builder: (context, c) {
            final maxW = c.maxWidth;
            final maxSizeFromWidth = ((maxW - widget.gap) / 2).floorToDouble();
            final size = widget.cardSize.clamp(86.0, maxSizeFromWidth);

            Widget card({
              required bool selected,
              required Color selectedBg,
              required Color accent,
              required IconData icon,
              required VoidCallback onTap,
            }) {
              return _SquareChoiceCard(
                size: size,
                radius: widget.radius,
                innerPad: widget.cardInnerPad,
                isSelected: selected,
                selectedBg: selectedBg,
                unselectedBg: widget.unselectedBg,
                unselectedBorderColor: widget.unselectedBorderColor,
                unselectedBorderWidth: widget.unselectedBorderWidth,
                icon: icon,
                iconSize: widget.iconSize,
                iconColorSelected: Colors.white,
                iconColorUnselected: accent,
                shadowBlur: widget.shadowBlur,
                shadowY: widget.shadowY,
                shadowOpacitySelected: widget.shadowOpacitySelected,
                shadowOpacityUnselected: widget.shadowOpacityUnselected,
                onTap: onTap,
              );
            }

            Widget labelsRow() {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: size,
                    child: Text(
                      widget.femaleLabel,
                      textAlign: TextAlign.center,
                      style: lStyle,
                    ),
                  ),
                  SizedBox(width: widget.gap),
                  SizedBox(
                    width: size,
                    child: Text(
                      widget.maleLabel,
                      textAlign: TextAlign.center,
                      style: lStyle,
                    ),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: widget.topGap),
                if (widget.showTitle) ...[
                  Padding(
                    padding: widget.titlePadding,
                    child: Transform.translate(
                      offset: widget.titleOffset,
                      child: Text(
                        widget.title,
                        style: tStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(height: widget.titleBottomGap),
                ],
                SizedBox(height: widget.cardsTopGap),
                Transform.translate(
                  offset: widget.cardsOffset,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      card(
                        selected: _current == YomuGender.female,
                        selectedBg: widget.femaleSelectedBg,
                        accent: widget.femaleAccent,
                        icon: widget.femaleIcon,
                        onTap: () => _setGender(YomuGender.female),
                      ),
                      SizedBox(width: widget.gap),
                      card(
                        selected: _current == YomuGender.male,
                        selectedBg: widget.maleSelectedBg,
                        accent: widget.maleAccent,
                        icon: widget.maleIcon,
                        onTap: () => _setGender(YomuGender.male),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: widget.labelTopGap),
                Transform.translate(
                  offset: widget.labelsOffset,
                  child: labelsRow(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SquareChoiceCard extends StatefulWidget {
  const _SquareChoiceCard({
    required this.size,
    required this.radius,
    required this.innerPad,
    required this.isSelected,
    required this.selectedBg,
    required this.unselectedBg,
    required this.unselectedBorderColor,
    required this.unselectedBorderWidth,
    required this.icon,
    required this.iconSize,
    required this.iconColorSelected,
    required this.iconColorUnselected,
    required this.shadowBlur,
    required this.shadowY,
    required this.shadowOpacitySelected,
    required this.shadowOpacityUnselected,
    required this.onTap,
  });

  final double size;
  final double radius;
  final double innerPad;

  final bool isSelected;

  final Color selectedBg;
  final Color unselectedBg;

  final Color unselectedBorderColor;
  final double unselectedBorderWidth;

  final IconData icon;
  final double iconSize;
  final Color iconColorSelected;
  final Color iconColorUnselected;

  final double shadowBlur;
  final double shadowY;
  final double shadowOpacitySelected;
  final double shadowOpacityUnselected;

  final VoidCallback onTap;

  @override
  State<_SquareChoiceCard> createState() => _SquareChoiceCardState();
}

class _SquareChoiceCardState extends State<_SquareChoiceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.08,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.08,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
    ]).animate(_bounceCtrl);
  }

  @override
  void didUpdateWidget(covariant _SquareChoiceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isSelected && widget.isSelected) {
      _bounceCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isSelected ? widget.selectedBg : widget.unselectedBg;

    final border = widget.isSelected
        ? Border.all(color: Colors.transparent, width: 0)
        : Border.all(
            color: widget.unselectedBorderColor,
            width: widget.unselectedBorderWidth,
          );

    final shadowOpacity = widget.isSelected
        ? widget.shadowOpacitySelected
        : widget.shadowOpacityUnselected;

    return Material(
      color: Colors.transparent,
      child: ScaleTransition(
        scale: _scale,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(widget.radius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            width: widget.size,
            height: widget.size,
            padding: EdgeInsets.all(widget.innerPad),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(widget.radius),
              border: border,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: shadowOpacity),
                  blurRadius: widget.shadowBlur,
                  offset: Offset(0, widget.shadowY),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                widget.icon,
                size: widget.iconSize,
                color: widget.isSelected
                    ? widget.iconColorSelected
                    : widget.iconColorUnselected,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
