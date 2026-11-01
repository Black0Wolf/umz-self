import 'fake_server.dart';

class Session {
  bool authed = false;
}

/// Server that accepts password "good" and then authenticates by cookie.
FakeAdapter happyServer([Session? session]) {
  final s = session ?? Session();
  return FakeAdapter({
    'GET /': (o) => s.authed
        ? page('<html>app</html>')
        : redirect('/identity/login?signin=abc', headers: {
            // The real server also sends nameless cookies; they must not break
            // the client.
            'set-cookie': [
              '; SameSite=Strict',
              'nonce=n1; path=/; secure; HttpOnly',
              '; HttpOnly',
            ],
          }),
    'GET /identity/login': (_) => page(loginPage(), headers: {
          'set-cookie': ['idsrv.xsrf=tok123; path=/; secure'],
        }),
    'GET /api/v0/Captcha': (_) => page('0'),
    'POST /identity/login': (o) {
      final data = Map<String, dynamic>.from(o.data as Map);
      if (data['password'] == 'good' && data['idsrv.xsrf'] == 'tok123') {
        return redirect('/identity/connect/authorize/callback');
      }
      return page(loginPage(error: 'نام کاربری یا رمز عبور اشتباه است'));
    },
    'GET /identity/connect/authorize/callback': (_) => page(formPostPage),
    'POST /': (o) {
      s.authed = true;
      return redirect('/', headers: {
        'set-cookie': ['session=ok; path=/; secure; HttpOnly'],
      });
    },
    'GET /api/v0/Credit': (o) {
      final cookie = o.headers['cookie']?.toString() ?? '';
      if (!s.authed || !cookie.contains('session=ok')) {
        return page('Access is denied', status: 401);
      }
      return page('-850000');
    },
  });
}
