import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/models.dart';
import '../state/app_state.dart';
import 'settings_page.dart';
import 'stats_page.dart';
import 'strings.dart';
import 'widgets/glint_button.dart';
import 'widgets/widgets.dart';

Color _muted(BuildContext context, [double alpha = 0.6]) =>
    Theme.of(context).colorScheme.onSurface.withValues(alpha: alpha);

void _push(BuildContext context, Widget page) => Navigator.of(context)
    .push(MaterialPageRoute<void>(builder: (_) => page));

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final weekKey = s.week.isEmpty ? 'none' : s.week.first.date;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: s.refresh,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                children: [
                  FadeSlideIn(child: _Header(state: s)),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 50),
                    child: _BalancePanel(state: s),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 100),
                    child: _WeekNav(state: s),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 150),
                    child: _ActionsPanel(state: s),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: s.loadingWeek
                        ? const LinearProgressIndicator(
                            key: ValueKey('loading'), minHeight: 2)
                        : const SizedBox(key: ValueKey('idle'), height: 2),
                  ),
                  if (s.weekError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        s.weekError!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOutCubic,
                    child: Column(
                      key: ValueKey(weekKey),
                      children: [
                        for (var i = 0; i < s.week.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: FadeSlideIn(
                              delay: Duration(milliseconds: 40 * i),
                              child: _DayCard(state: s, day: s.week[i]),
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
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppMark(size: 34),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            state.t('appTitle'),
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          tooltip: state.t('stats'),
          icon: const Icon(Icons.insights_outlined),
          onPressed: () => _push(context, const StatsPage()),
        ),
        IconButton(
          tooltip: state.t('refresh'),
          icon: const Icon(Icons.refresh),
          onPressed: state.refresh,
        ),
        IconButton(
          tooltip: state.t('settings'),
          icon: const Icon(Icons.tune),
          onPressed: () => _push(context, const SettingsPage()),
        ),
      ],
    );
  }
}

class _BalancePanel extends StatelessWidget {
  const _BalancePanel({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final credit = state.credit;
    final negative = credit != null && credit < 0;
    final color = negative ? cs.error : cs.onSurface;
    return Panel(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(state.t('credit'),
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: _muted(context), letterSpacing: 0.6)),
                const SizedBox(height: 6),
                CountUp(
                  value: (credit ?? 0).toDouble(),
                  builder: (context, v) => Text(
                    credit == null ? '—' : formatToman(v.round()),
                    textDirection: TextDirection.ltr,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w300,
                          letterSpacing: -1,
                          height: 1.05,
                        ),
                  ),
                ),
                Text(state.t('toman'),
                    style: TextStyle(color: _muted(context, 0.5))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  color: _muted(context, 0.5)),
              const SizedBox(height: 6),
              Text(state.username ?? '',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(color: _muted(context))),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekNav extends StatelessWidget {
  const _WeekNav({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlintButton(
            label: state.t('prevWeek'),
            icon: Icons.chevron_left,
            style: GlintStyle.outline,
            compact: true,
            expand: true,
            onPressed: () => state.loadWeek(direction: -1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GlintButton(
            label: state.t('thisWeek'),
            style: GlintStyle.tonal,
            compact: true,
            expand: true,
            onPressed: () => state.loadWeek(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GlintButton(
            label: state.t('nextWeek'),
            icon: Icons.chevron_right,
            style: GlintStyle.outline,
            compact: true,
            expand: true,
            onPressed: () => state.loadWeek(direction: 1),
          ),
        ),
      ],
    );
  }
}

class _ActionsPanel extends StatelessWidget {
  const _ActionsPanel({required this.state});
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
        title: Text('${state.t('reserveAllTitle')} · ${plans.length} '
            '${state.t('items')}'),
        content: SizedBox(
          width: 440,
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
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${state.t('total')}: ${formatToman(total)} '
                  '${state.t('toman')}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        actions: [
          GlintButton(
            label: state.t('cancel'),
            style: GlintStyle.outline,
            compact: true,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          GlintButton(
            label: state.t('confirm'),
            compact: true,
            onPressed: () => Navigator.pop(ctx, true),
          ),
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
          GlintButton(
            label: state.t('close'),
            compact: true,
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  Future<void> _showActivity(BuildContext context) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(state.t('activity')),
          content: SizedBox(
            width: 440,
            child: state.activity.isEmpty
                ? Text(state.t('noActivity'))
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final line in state.activity)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(line),
                        ),
                    ],
                  ),
          ),
          actions: [
            GlintButton(
              label: state.t('close'),
              compact: true,
              onPressed: () => Navigator.pop(ctx),
            ),
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
    return Panel(
      child: Column(
        children: [
          GlintButton(
            label: state.t('reserveAll'),
            icon: Icons.done_all,
            expand: true,
            busy: state.reserving,
            onPressed: () => _reserveAll(context),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              PulseDot(active: state.autoReserve),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.t('autoReserve'),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      '${state.t('autoReserveHint')}${_lastRun()}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: _muted(context)),
                    ),
                  ],
                ),
              ),
              Switch(
                value: state.autoReserve,
                onChanged: state.setAutoReserve,
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: () => _showActivity(context),
              icon: const Icon(Icons.history, size: 18),
              label: Text(state.t('activity')),
            ),
          ),
        ],
      ),
    );
  }
}

bool _isToday(Day day) {
  final d = day.miladi;
  if (d == null) return false;
  final now = DateTime.now();
  return d.year == now.year && d.month == now.month && d.day == now.day;
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.state, required this.day});
  final AppState state;
  final Day day;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final meals = day.mealsWithMenu.toList();
    final today = _isToday(day);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(day.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: 10),
              Text(day.date,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(color: _muted(context, 0.5))),
              const Spacer(),
              if (today)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cs.primary),
                  ),
                  child: Text(state.t('today'),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          if (meals.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                dayStateLabel(state.lang, day.state, day.stateTitle),
                style: TextStyle(color: _muted(context)),
              ),
            ),
          for (final meal in meals) ...[
            const SizedBox(height: 14),
            Divider(color: cs.outlineVariant),
            const SizedBox(height: 10),
            _MealBlock(state: state, day: day, meal: meal),
          ],
        ],
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
    final row =
        ReserveRow.forOffer(day: day, meal: meal, food: food, offer: offer);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(state.t('confirmTitle')),
        content: Text('${day.title} ${day.date} · ${meal.name}\n'
            '${food.name}\n${offer.selfName}\n\n'
            '${state.t('youPay')}: ${formatToman(row.unitPrice)} '
            '${state.t('toman')}'),
        actions: [
          GlintButton(
            label: state.t('cancel'),
            style: GlintStyle.outline,
            compact: true,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          GlintButton(
            label: state.t('confirm'),
            compact: true,
            onPressed: () => Navigator.pop(ctx, true),
          ),
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
    final cs = Theme.of(context).colorScheme;
    final label = mealStateLabel(state.lang, meal.state, meal.stateTitle);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(meal.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: meal.isOpen
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: _muted(context, 0.55))),
            ),
            if (meal.hasReservation) ...[
              const Spacer(),
              Icon(Icons.check_circle, size: 16, color: cs.primary),
              const SizedBox(width: 4),
              Text(state.t('reservedTag'),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
        for (final food in meal.foods)
          for (final offer in food.offers)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(food.name),
                        const SizedBox(height: 2),
                        Text(
                          '${offer.selfName} · ${formatToman(offer.studentPays)}'
                          ' ${state.t('toman')}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: _muted(context, 0.55)),
                        ),
                      ],
                    ),
                  ),
                  if (meal.isOpen && !meal.hasReservation) ...[
                    const SizedBox(width: 12),
                    GlintButton(
                      label: state.t('reserve'),
                      style: GlintStyle.tonal,
                      compact: true,
                      onPressed: () => _reserve(context, food, offer),
                    ),
                  ],
                ],
              ),
            ),
      ],
    );
  }
}
