import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef Handler = ResponseBody Function(RequestOptions o);

/// Scripted stand-in for the server: routes are keyed "METHOD /path".
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.routes);

  final Map<String, Handler> routes;
  final List<String> log = [];

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? body,
      Future<void>? cancel) async {
    final path = o.uri.path.isEmpty ? '/' : o.uri.path;
    final key = '${o.method} $path';
    log.add(key);
    final h = routes[key];
    if (h == null) return ResponseBody.fromString('not found: $key', 404);
    return h(o);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody page(String body,
        {int status = 200, Map<String, List<String>> headers = const {}}) =>
    ResponseBody.fromString(body, status, headers: {
      Headers.contentTypeHeader: ['text/html; charset=utf-8'],
      ...headers,
    });

ResponseBody redirect(String to,
        {Map<String, List<String>> headers = const {}}) =>
    ResponseBody.fromString('', 302, headers: {
      'location': [to],
      ...headers,
    });

ResponseBody jsonBody(Object v) => ResponseBody.fromString(jsonEncode(v), 200,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    });

/// A login page whose `#modelJson` is HTML-entity encoded like the real one.
String loginPage({String? error}) {
  final model = jsonEncode({
    'loginUrl': '/identity/login?signin=abc',
    'antiForgery': {'name': 'idsrv.xsrf', 'value': 'tok123'},
    'errorMessage': error,
  });
  final encoded = model
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll('<', '&lt;');
  return "<html><body><script id='modelJson' type='application/json'>"
      '$encoded</script></body></html>';
}

const formPostPage = '<html><body><form method="post" '
    'action="https://self.umz.ac.ir"><input type="hidden" name="id_token" '
    'value="idt"/><input type="hidden" name="access_token" value="act"/>'
    '<input type="hidden" name="state" value="st"/></form></body></html>';
