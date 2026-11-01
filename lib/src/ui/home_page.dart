import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/models.dart';
import '../state/app_state.dart';
import 'stats_page.dart';
import 'strings.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('appTitle')),
        actions: [
          TextButton(onPressed: s.toggleLanguage, child: Text(s.t('language'))),
          IconButton(
            tooltip: s.t('stats'),
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const StatsPage())),
          ),
          IconButton(
            tooltip: s.t('refresh'),
            icon: const Icon(Icons.refresh),
            onPressed: s.refresh,
          ),
          IconButton(
            tooltip: s.t('logout'),
            icon: const Icon(Icons.logout),
            onPressed: s.logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: s.refresh,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _CreditCard(state: s),
            const SizedBox(height: 8),
            _WeekNav(state: s),
            _BulkActions(state: s),
            if (s.weekError != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  s.weekError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (s.loadingWeek) const LinearProgressIndicator(),
            for (final day in s.week) _DayCard(state: s, day: day),
          ],
        ),
      ),
    );
  }
}

class _CreditCard extends StatelessWidget {
  const _CreditCard({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final c = state.credit;
    final negative = c != null && c < 0;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.account_balance_wallet),
        title: Text(state.t('credit')),
        subtitle: Text(state.username ?? ''),
        trailing: Text(
          c == null ? '—' : '${formatToman(c)} ${state.t('toman')}',
          textDirection: TextDirection.ltr,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: negative ? Theme.of(context).colorScheme.error : null,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}

class _WeekNav extends StatelessWidget {
  const _WeekNav({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: [
        OutlinedButton(
          onPressed: () => state.loadWeek(direction: -1),
          child: Text(state.t('prevWeek')),
        ),
        FilledButton.tonal(
          onPressed: () => state.loadWeek(),
          child: Text(state.t('thisWeek')),
        ),
        OutlinedButton(
          onPressed: () => state.loadWeek(direction: 1),
          child: Text(state.t('nextWeek')),
        ),
      ],
    );
  }
}

class _BulkActions extends StatelessWidget {
  const _BulkActions({required this.state});
  final AppState state;

  Future<void> _reserveAll(BuildContext context) async {
    final plans = state.planVisibleWeek();
    final messenger = ScaffoldMessenger.of(context);
    if (plans.isEmpty) {
      messenger.showSnackBar(
          SnackBar(content: Text(state.t('nothingToReserve'))));
      return;
    }
    final total = plans.fold<int>(0, (sum, p) => sum + p.price);
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${state.t('reserveAllTitle')} (${plans.length} '
            '${state.t('items')})'),
        content: SizedBox(
          width: 420,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final p in plans)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${p.day.title} · ${p.meal.name}'),
                  subtitle: Text('${p.food.name}\n${p.offer.selfName}'),
                  isThreeLine: true,
                  trailing: Text(formatToman(p.price),
                      textDirection: TextDirection.ltr),
                ),
              const Divider(),
              Text('${state.t('total')}: ${formatToman(total)} '
                  '${state.t('toman')}'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(state.t('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(state.t('confirm'))),
        ],
      ),
    );
    if (go != true) return;

    final summary = await state.reserveAll(plans);
    if (!context.mounted) return;
    final lines = <String>[
      '${state.t('reservedN')} ${summary.reserved} · '
          '${formatToman(summary.spentRial)} ${state.t('toman')}',
      if (summary.failures.isNotEmpty) ...[
        '',
        state.t('failedN'),
        ...summary.failures,
      ],
    ];
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(state.t('reserveAllTitle')),
        content: SingleChildScrollView(child: Text(lines.join('\n'))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(state.t('close'))),
        ],
      ),
    );
  }

  Future<void> _showActivity(BuildContext context) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(state.t('activity')),
          content: SizedBox(
            width: 420,
            child: state.activity.isEmpty
                ? Text(state.t('noActivity'))
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final line in state.activity)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(line),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(state.t('close'))),
          ],
        ),
      );

  String _lastRun() {
    final t = state.lastAutoRun;
    if (t == null) return '';
    String two(int v) => v.toString().padLeft(2, '0');
    return ' · ${state.t('lastRun')} ${two(t.hour)}:${two(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    state.reserving ? null : () => _reserveAll(context),
                icon: state.reserving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.done_all),
                label: Text(state.t('reserveAll')),
              ),
            ),
            SwitchListTile(
              value: state.autoReserve,
              onChanged: state.setAutoReserve,
              title: Text(state.t('autoReserve')),
              subtitle: Text('${state.t('autoReserveHint')}${_lastRun()}'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () => _showActivity(context),
                icon: const Icon(Icons.history),
                label: Text(state.t('activity')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.state, required this.day});
  final AppState state;
  final Day day;

  @override
  Widget build(BuildContext context) {
    final meals = day.mealsWithMenu.toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${day.title}  ${day.date}',
                style: Theme.of(context).textTheme.titleMedium),
            if (meals.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(day.stateTitle.isEmpty
                    ? state.t('noMenu')
                    : day.stateTitle),
              ),
            for (final meal in meals)
              _MealBlock(state: state, day: day, meal: meal),
          ],
        ),
      ),
    );
  }
}

class _MealBlock extends StatelessWidget {
  const _MealBlock(
      {required this.state, required this.day, required this.meal});
  final AppState state;
  final Day day;
  final Meal meal;

  Future<void> _reserve(
      BuildContext context, Food food, SelfOffer offer) async {
    final row = ReserveRow.forOffer(
        day: day, meal: meal, food: food, offer: offer);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(state.t('confirmTitle')),
        content: Text('${day.title} ${day.date} · ${meal.name}\n'
            '${food.name}\n${offer.selfName}\n\n'
            '${state.t('youPay')}: ${formatToman(row.unitPrice)} '
            '${state.t('toman')}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(state.t('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(state.t('confirm'))),
        ],
      ),
    );
    if (ok != true) return;
    String message;
    try {
      final r = await state.reserve(day, meal, food, offer);
      if (r == null) {
        message = state.t('sessionError');
      } else if (r.ok) {
        message = '${state.t('reserved')} · '
            '${state.t('reserveCode')}: ${r.reserveNumber}';
      } else {
        message = r.stateMessage ?? 'Error ${r.stateCode}';
      }
    } on Object catch (e) {
      message = '$e';
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(meal.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Chip(
                label: Text(meal.stateTitle),
                visualDensity: VisualDensity.compact,
                backgroundColor: meal.isOpen
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
              ),
            ],
          ),
          for (final food in meal.foods)
            for (final offer in food.offers)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(food.name),
                subtitle: Text(
                    '${offer.selfName} · ${formatToman(offer.studentPays)} '
                    '${state.t('toman')}'),
                trailing: meal.isOpen
                    ? FilledButton.tonal(
                        onPressed: () => _reserve(context, food, offer),
                        child: Text(state.t('reserve')),
                      )
                    : null,
              ),
        ],
      ),
    );
  }
}
