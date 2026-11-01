import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/palettes.dart';
import '../theme/theme_controller.dart';
import 'widgets/glint_button.dart';
import 'widgets/widgets.dart';

const String appVersion = '0.3.0';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final theme = context.watch<ThemeController>();
    final brightness = Theme.of(context).brightness;
    final loggedIn = s.status == AuthStatus.loggedIn;

    final segStyle = SegmentedButton.styleFrom(
      selectedBackgroundColor: Theme.of(context).colorScheme.primaryContainer,
      selectedForegroundColor: Theme.of(context).colorScheme.onSurface,
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('settings'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              SectionLabel(s.t('appearance')),
              FadeSlideIn(
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.t('themeMode')),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          showSelectedIcon: false,
                          style: segStyle,
                          segments: [
                            ButtonSegment(
                              value: ThemeMode.system,
                              icon: const Icon(Icons.brightness_auto, size: 18),
                              label: Text(s.t('modeSystem')),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              icon: const Icon(Icons.light_mode_outlined,
                                  size: 18),
                              label: Text(s.t('modeLight')),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              icon: const Icon(Icons.dark_mode_outlined,
                                  size: 18),
                              label: Text(s.t('modeDark')),
                            ),
                          ],
                          selected: {theme.mode},
                          onSelectionChanged: (v) => theme.setMode(v.first),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(s.t('palette')),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final p in palettes)
                            _PaletteTile(
                              palette: p,
                              name: p.name(s.lang),
                              brightness: brightness,
                              selected: p.id == theme.paletteId,
                              onTap: () => theme.setPalette(p.id),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SectionLabel(s.t('languageLabel')),
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: Panel(
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      style: segStyle,
                      segments: const [
                        ButtonSegment(value: 'fa', label: Text('فارسی')),
                        ButtonSegment(value: 'en', label: Text('English')),
                      ],
                      selected: {s.lang},
                      onSelectionChanged: (v) {
                        if (v.first != s.lang) s.toggleLanguage();
                      },
                    ),
                  ),
                ),
              ),
              if (loggedIn) ...[
                SectionLabel(s.t('autoReserve')),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            PulseDot(active: s.autoReserve),
                            const SizedBox(width: 12),
                            Expanded(child: Text(s.t('autoReserve'))),
                            Switch(
                              value: s.autoReserve,
                              onChanged: s.setAutoReserve,
                            ),
                          ],
                        ),
                        Text(
                          s.t('autoReserveHint'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(s.t('checkEvery')),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final m in const [2, 5, 10, 15])
                              ChoiceChip(
                                label: Text('$m ${s.t('minutes')}'),
                                selected: s.autoInterval.inMinutes == m,
                                showCheckmark: false,
                                selectedColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                backgroundColor: Colors.transparent,
                                side: BorderSide(
                                    color: s.autoInterval.inMinutes == m
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .outlineVariant),
                                onSelected: (_) => s.setAutoInterval(m),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SectionLabel(s.t('account')),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 180),
                  child: Panel(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.t('signedInAs'),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                              ),
                              Text(s.username ?? '',
                                  textDirection: TextDirection.ltr),
                            ],
                          ),
                        ),
                        GlintButton(
                          label: s.t('logout'),
                          icon: Icons.logout,
                          style: GlintStyle.outline,
                          compact: true,
                          onPressed: () async {
                            final nav = Navigator.of(context);
                            await s.logout();
                            nav.popUntil((r) => r.isFirst);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              SectionLabel(s.t('about')),
              FadeSlideIn(
                delay: const Duration(milliseconds: 240),
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const AppMark(size: 36),
                          const SizedBox(width: 12),
                          Expanded(child: Text(s.t('appTitle'))),
                          Text('v$appVersion',
                              textDirection: TextDirection.ltr),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        s.t('aboutText'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A swatch showing a palette in the current brightness.
class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    required this.palette,
    required this.name,
    required this.brightness,
    required this.selected,
    required this.onTap,
  });

  final AppPalette palette;
  final String name;
  final Brightness brightness;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final v = palette.variant(brightness);
    final cs = Theme.of(context).colorScheme;
    final ink = onColor(v.bg);
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 148,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: v.bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? v.accent : cs.outlineVariant,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: v.accent.withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: -4,
                      ),
                    ]
                  : const [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: AlignmentDirectional.centerStart,
                  decoration: BoxDecoration(
                    color: v.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ink.withValues(alpha: 0.12)),
                  ),
                  child: Container(
                    width: 46,
                    height: 8,
                    decoration: BoxDecoration(
                      color: v.accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: selected ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.check_circle, size: 16, color: v.accent),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
