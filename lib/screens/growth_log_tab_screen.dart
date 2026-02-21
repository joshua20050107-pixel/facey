import 'package:flutter/material.dart';

import 'face_analysis_result_screen.dart';

class GrowthLogTabScreen extends StatelessWidget {
  const GrowthLogTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FaceAnalysisResult result = FaceAnalysisResult.dummy();
    final int overallScore = result.overall.clamp(0, 100);
    final FaceMetricScore potentialMetric = result.metrics.firstWhere(
      (FaceMetricScore metric) => metric.label == 'ポテンシャル',
      orElse: () => result.metrics.first,
    );
    final int potentialScore = potentialMetric.value.clamp(0, 100);
    final int potentialDelta = potentialScore - overallScore;
    final String potentialDeltaText = potentialDelta > 0
        ? '↗ +$potentialDelta'
        : potentialDelta < 0
        ? '↘ $potentialDelta'
        : '→ ±0';

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: SizedBox(
                  height: 52,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '成長ログ',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(7, -4),
                child: const Text(
                  'あなたの変化を振り返りましょう',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFB9C0CF),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 160),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF1E2A3E,
                          ).withValues(alpha: 0.76),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 30,
                              backgroundColor: Color(0xFF2B3A51),
                              child: Icon(
                                Icons.person_rounded,
                                color: Color(0xFFB9C5D9),
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _MetricGroup(
                                          title: '総合スコア',
                                          value: '$overallScore',
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _MetricGroup(
                                          title: 'ポテンシャル',
                                          value: '$potentialScore',
                                          suffix: potentialDeltaText,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: 0.91,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        child: SizedBox(
                                          height: 10,
                                          child: LayoutBuilder(
                                            builder:
                                                (
                                                  BuildContext context,
                                                  BoxConstraints constraints,
                                                ) {
                                                  final double overallProgress =
                                                      (overallScore / 100)
                                                          .clamp(0.0, 1.0)
                                                          .toDouble();
                                                  final double
                                                  potentialProgress =
                                                      (potentialScore / 100)
                                                          .clamp(0.0, 1.0)
                                                          .toDouble();
                                                  final double overallWidth =
                                                      constraints.maxWidth *
                                                      overallProgress;
                                                  final double potentialWidth =
                                                      constraints.maxWidth *
                                                      (potentialProgress -
                                                              overallProgress)
                                                          .clamp(0.0, 1.0);
                                                  return Stack(
                                                    children: [
                                                      Container(
                                                        color: const Color(
                                                          0xFFD5DAE2,
                                                        ),
                                                      ),
                                                      Container(
                                                        width: overallWidth,
                                                        decoration:
                                                            const BoxDecoration(
                                                              gradient: LinearGradient(
                                                                colors: <Color>[
                                                                  Color(
                                                                    0xFF7CC5EA,
                                                                  ),
                                                                  Color(
                                                                    0xFF2C59E2,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                      ),
                                                      if (potentialWidth > 0)
                                                        Positioned(
                                                          left: overallWidth,
                                                          child: Container(
                                                            width:
                                                                potentialWidth,
                                                            height: 10,
                                                            decoration: const BoxDecoration(
                                                              gradient: LinearGradient(
                                                                colors: <Color>[
                                                                  Color(
                                                                    0xFF8A4DFF,
                                                                  ),
                                                                  Color(
                                                                    0xFF5A16F4,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      if (potentialWidth > 0)
                                                        Positioned(
                                                          left: (overallWidth - 1)
                                                              .clamp(
                                                                0.0,
                                                                constraints
                                                                    .maxWidth,
                                                              ),
                                                          child: Container(
                                                            width: 1,
                                                            height: 10,
                                                            color: Colors.white
                                                                .withValues(
                                                                  alpha: 0.75,
                                                                ),
                                                          ),
                                                        ),
                                                    ],
                                                  );
                                                },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text(
                          '習慣リスト',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFE9EEF7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 45,
          bottom: 50,
          child: SizedBox(
            width: 66,
            height: 66,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEDEDED),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.add_rounded,
                  size: 34,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricGroup extends StatelessWidget {
  const _MetricGroup({required this.title, required this.value, this.suffix});

  final String title;
  final String value;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 1),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE9EEF7),
          ),
        ),
        const SizedBox(height: 2),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 6,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1,
                color: Colors.white,
              ),
            ),
            if (suffix != null)
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 5),
                child: Text(
                  suffix!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9AA8BE),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
