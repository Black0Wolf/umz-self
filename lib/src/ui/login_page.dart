import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

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
    final busy = s.status == AuthStatus.loggingIn;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('appTitle')),
        actions: [
          TextButton(onPressed: s.toggleLanguage, child: Text(s.t('language'))),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            padding: const EdgeInsets.all(24),
            shrinkWrap: true,
            children: [
              TextField(
                controller: _user,
                enabled: !busy,
                autofillHints: const [AutofillHints.username],
                decoration: InputDecoration(
                  labelText: s.t('username'),
                  prefixIcon: const Icon(Icons.person),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pass,
                enabled: !busy,
                obscureText: !_showPass,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: s.t('password'),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _showPass ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                ),
                onSubmitted: (_) => _submit(s),
              ),
              if (s.captchaNeeded) ...[
                const SizedBox(height: 12),
                if (s.captchaImage != null && s.captchaImage!.isNotEmpty)
                  Row(
                    children: [
                      Expanded(child: Image.memory(s.captchaImage!)),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: s.reloadCaptcha,
                      ),
                    ],
                  ),
                TextField(
                  controller: _captcha,
                  decoration: InputDecoration(
                    labelText: s.t('captcha'),
                    helperText: s.t('captchaHint'),
                  ),
                  onSubmitted: (_) => _submit(s),
                ),
              ],
              CheckboxListTile(
                value: _remember,
                onChanged:
                    busy ? null : (v) => setState(() => _remember = v ?? true),
                title: Text(s.t('remember')),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              if (s.loginError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    s.loginError!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              FilledButton(
                onPressed: busy ? null : () => _submit(s),
                child: busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(s.t('login')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
