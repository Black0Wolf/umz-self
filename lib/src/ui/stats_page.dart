import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'strings.dart';
import 'widgets/widgets.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = s.stats;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    String money(int rial) => '${formatToman(rial)} ${s.t('toman')}';

    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('stats'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: st.count == 0
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: FadeSlideIn(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.insights_outlined,
                              size: 48, color: muted),
                          const SizedBox(height: 12),
                          Text(s.t('noStats'), textAlign: TextAlign.center),
                          const SizedBox(height: 6),
                          Text(
                            s.t('statsNote'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        s.t('statsNote'),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: muted),
                      ),
                    ),
                    FadeSlideIn(
                      child: _Hero(
                        label: s.t('totalSpent'),
                        value: st.totalRial.toDouble(),
                        format: (v) => money(v.round()),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 60),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _Tile(
                            label: s.t('mealsReserved'),
                            value: st.count.toDouble(),
                            format: (v) => '${v.round()}',
                          ),
                          _Tile(
                            label: s.t('average'),
                            value: st.averageRial.toDouble(),
                            format: (v) => money(v.round()),
                          ),
                          _Tile(
                            label: s.t('viaAuto'),
                            value: st.autoCount.toDouble(),
                            format: (v) => '${v.round()}',
                          ),
                          _Tile(
                            label: s.t('viaManual'),
                            value: st.manualCount.toDouble(),
                            format: (v) => '${v.round()}',
                          ),
                        ],
                      ),
                    ),
                    if (st.mostExpensive != null) ...[
                      const SizedBox(height: 10),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: Panel(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.t('mostExpensive'),
                                        style: TextStyle(color: muted)),
                                    const SizedBox(height: 4),
                                    Text(
                                        '${st.mostExpensive!.date} · '
                                        '${st.mostExpensive!.mealName} · '
                                        '${st.mostExpensive!.foodName}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              Text(money(st.mostExpensive!.priceRial),
                                  textDirection: TextDirection.ltr,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    _Section(
                      title: s.t('byMeal'),
                      values: st.mealCount,
                      trailing: (k, v) => '$v · ${money(st.mealSpent[k] ?? 0)}',
                      delay: 140,
                    ),
                    _Section(
                      title: s.t('byMonth'),
                      values: st.monthSpent,
                      trailing: (k, v) => money(v),
                      delay: 180,
                    ),
                    _Section(
                      title: s.t('topFoods'),
                      values: st.topFoods,
                      trailing: (k, v) => '$v',
                      delay: 220,
                    ),
                    _Section(
                      title: s.t('bySelf'),
                      values: st.selfCount,
                      trailing: (k, v) => '$v',
                      delay: 260,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero(
      {required this.label, required this.value, required this.format});
  final String label;
  final double value;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Panel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  letterSpacing: 0.6)),
          const SizedBox(height: 6),
          CountUp(
            value: value,
            builder: (context, v) => Text(
              format(v),
              textDirection: TextDirection.ltr,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(
      {required this.label, required this.value, required this.format});
  final String label;
  final double value;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 178,
      child: Panel(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 4),
            CountUp(
              value: value,
              builder: (context, v) => Text(
                format(v),
                textDirection: TextDirection.ltr,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A titled list of labelled bars scaled to the largest value.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.values,
    required this.trailing,
    required this.delay,
  });

  final String title;
  final Map<String, int> values;
  final String Function(String key, int value) trailing;
  final int delay;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    final max = values.values.reduce((a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(title),
        FadeSlideIn(
          delay: Duration(milliseconds: delay),
          child: Panel(
            child: Column(
              children: [
                for (final e in values.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: Text(e.key,
                                    overflow: TextOverflow.ellipsis)),
                            Text(trailing(e.key, e.value),
                                textDirection: TextDirection.ltr),
                          ],
                        ),
                        const SizedBox(height: 6),
                        AnimatedBar(fraction: max == 0 ? 0 : e.value / max),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
