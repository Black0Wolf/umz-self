import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'settings_page.dart';
import 'widgets/glint_button.dart';
import 'widgets/widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _captcha = TextEditingController();
  bool _remember = true;
  bool _showPass = false;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    _captcha.dispose();
    super.dispose();
  }

  void _submit(AppState s) {
    if (_user.text.trim().isEmpty || _pass.text.isEmpty) return;
    s.login(
      _user.text.trim(),
      _pass.text,
      remember: _remember,
      captcha: s.captchaNeeded && _captcha.text.isNotEmpty
          ? _captcha.text.trim()
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final busy = s.status == AuthStatus.loggingIn;
    final muted = cs.onSurface.withValues(alpha: 0.6);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            PositionedDirectional(
              top: 8,
              end: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                      onPressed: s.toggleLanguage,
                      child: Text(s.t('language'))),
                  IconButton(
                    tooltip: s.t('settings'),
                    icon: const Icon(Icons.palette_outlined),
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => const SettingsPage())),
                  ),
                ],
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shrinkWrap: true,
                  children: [
                    const FadeSlideIn(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: AppMark(size: 60),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 60),
                      child: Text(
                        s.t('appTitle'),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 120),
                      child: TextField(
                        controller: _user,
                        enabled: !busy,
                        autofillHints: const [AutofillHints.username],
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: s.t('username'),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 180),
                      child: TextField(
                        controller: _pass,
                        enabled: !busy,
                        obscureText: !_showPass,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          hintText: s.t('password'),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_showPass
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () =>
                                setState(() => _showPass = !_showPass),
                          ),
                        ),
                        onSubmitted: (_) => _submit(s),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: s.captchaNeeded
                          ? Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Column(
                                children: [
                                  if (s.captchaImage != null &&
                                      s.captchaImage!.isNotEmpty)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.memory(
                                                s.captchaImage!),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.refresh),
                                          onPressed: s.reloadCaptcha,
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _captcha,
                                    decoration: InputDecoration(
                                        hintText: s.t('captchaHint')),
                                    onSubmitted: (_) => _submit(s),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                    const SizedBox(height: 8),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 220),
                      child: Row(
                        children: [
                          Switch(
                            value: _remember,
                            onChanged: busy
                                ? null
                                : (v) => setState(() => _remember = v),
                          ),
                          const SizedBox(width: 8),
                          Text(s.t('remember'),
                              style: TextStyle(color: muted)),
                        ],
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: s.loginError == null
                          ? const SizedBox(width: double.infinity)
                          : Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                s.loginError!,
                                style: TextStyle(color: cs.error),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 260),
                      child: GlintButton(
                        label: s.t('login'),
                        expand: true,
                        busy: busy,
                        onPressed: () => _submit(s),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
