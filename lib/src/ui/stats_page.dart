import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'strings.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = s.stats;
    String money(int rial) => '${formatToman(rial)} ${s.t('toman')}';

    return Scaffold(
      appBar: AppBar(title: Text(s.t('stats'))),
      body: st.count == 0
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(s.t('noStats'), textAlign: TextAlign.center),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(s.t('statsNote'),
                      style: Theme.of(context).textTheme.bodySmall),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Tile(s.t('totalSpent'), money(st.totalRial)),
                    _Tile(s.t('mealsReserved'), '${st.count}'),
                    _Tile(s.t('average'), money(st.averageRial)),
                    _Tile(s.t('viaAuto'), '${st.autoCount}'),
                    _Tile(s.t('viaManual'), '${st.manualCount}'),
                  ],
                ),
                if (st.mostExpensive != null)
                  Card(
                    child: ListTile(
                      title: Text(s.t('mostExpensive')),
                      subtitle: Text('${st.mostExpensive!.date} · '
                          '${st.mostExpensive!.mealName} · '
                          '${st.mostExpensive!.foodName}'),
                      trailing: Text(money(st.mostExpensive!.priceRial),
                          textDirection: TextDirection.ltr),
                    ),
                  ),
                _Section(
                  title: s.t('byMeal'),
                  values: st.mealCount,
                  trailing: (k, v) =>
                      '$v · ${money(st.mealSpent[k] ?? 0)}',
                ),
                _Section(
                  title: s.t('byMonth'),
                  values: st.monthSpent,
                  trailing: (k, v) => money(v),
                ),
                _Section(
                  title: s.t('topFoods'),
                  values: st.topFoods,
                  trailing: (k, v) => '$v',
                ),
                _Section(
                  title: s.t('bySelf'),
                  values: st.selfCount,
                  trailing: (k, v) => '$v',
                ),
              ],
            ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(value,
                  textDirection: TextDirection.ltr,
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}

/// A titled list of labelled bars scaled to the largest value.
class _Section extends StatelessWidget {
  const _Section(
      {required this.title, required this.values, required this.trailing});

  final String title;
  final Map<String, int> values;
  final String Function(String key, int value) trailing;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    final max = values.values.reduce((a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final e in values.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text(e.key, overflow: TextOverflow.ellipsis)),
                        Text(trailing(e.key, e.value),
                            textDirection: TextDirection.ltr),
                      ],
                    ),
                    const SizedBox(height: 2),
                    LinearProgressIndicator(
                      value: max == 0 ? 0 : e.value / max,
                      minHeight: 6,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
