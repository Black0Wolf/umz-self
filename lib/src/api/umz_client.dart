/// HTTP client for self.umz.ac.ir. Plain Dart (no Flutter) so it can be
/// used from the CLI and from tests.
library;

import 'dart:convert';
import 'dart:io' show Cookie;
import 'dart:math';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:html/parser.dart' as html;

import 'models.dart';

class UmzException implements Exception {
  UmzException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Wrong username/password or other rejection; [message] is the server text.
class LoginFailedException extends UmzException {
  LoginFailedException(super.message);
}

/// The server wants a captcha before accepting a login.
class CaptchaRequiredException extends UmzException {
  CaptchaRequiredException() : super('Captcha required');
}

/// The server asked for a one-time code (2FA).
class OtpRequiredException extends UmzException {
  OtpRequiredException(super.message);
}

/// The session is gone and no stored credentials are available to renew it.
class SessionExpiredException extends UmzException {
  SessionExpiredException() : super('Session expired');
}

/// Data embedded in the identity server login page (`#modelJson`).
class LoginModel {
  LoginModel({
    required this.loginUrl,
    required this.xsrfName,
    required this.xsrfValue,
    this.errorMessage,
  });

  final String loginUrl;
  final String xsrfName;
  final String xsrfValue;
  final String? errorMessage;
}

/// Parses the login page. Returns null if [body] is not a login page.
LoginModel? parseLoginModel(String body) {
  final el = html.parse(body).getElementById('modelJson');
  if (el == null) return null;
  // Script contents are not entity-decoded by the HTML parser; the site's own
  // JS decodes them, so do the same here.
  final decoded = html.parseFragment(el.text).text ?? '';
  final Object? json;
  try {
    json = jsonDecode(decoded);
  } on FormatException {
    return null;
  }
  if (json is! Map) return null;
  final xsrf = json['antiForgery'];
  final loginUrl = json['loginUrl'];
  if (xsrf is! Map || loginUrl is! String) return null;
  final err = json['errorMessage'];
  return LoginModel(
    loginUrl: loginUrl,
    xsrfName: '${xsrf['name']}',
    xsrfValue: '${xsrf['value']}',
    errorMessage: err is String && err.isNotEmpty ? err : null,
  );
}

/// The auto-submitting `form_post` page that follows a successful login.
class FormPost {
  FormPost(this.action, this.fields);
  final String action;
  final Map<String, String> fields;
}

FormPost? parseFormPost(String body) {
  final doc = html.parse(body);
  final form = doc.querySelector('form');
  if (form == null) return null;
  final fields = <String, String>{};
  for (final input in form.querySelectorAll('input')) {
    final name = input.attributes['name'];
    if (name != null) fields[name] = input.attributes['value'] ?? '';
  }
  if (!fields.containsKey('id_token')) return null;
  return FormPost(form.attributes['action'] ?? '', fields);
}

bool _validCookie(String value) {
  try {
    return Cookie.fromSetCookieValue(value).name.isNotEmpty;
  } on Object {
    return false;
  }
}

/// Removes Set-Cookie values the cookie jar could not parse.
class _SanitizingAdapter implements HttpClientAdapter {
  _SanitizingAdapter(this._inner);

  final HttpClientAdapter _inner;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final res = await _inner.fetch(options, requestStream, cancelFuture);
    for (final key in res.headers.keys.toList()) {
      if (key.toLowerCase() != 'set-cookie') continue;
      res.headers[key] = [
        for (final v in res.headers[key]!)
          if (_validCookie(v)) v,
      ];
    }
    return res;
  }

  @override
  void close({bool force = false}) => _inner.close(force: force);
}

class UmzClient {
  UmzClient({String baseUrl = 'https://self.umz.ac.ir', Dio? dio})
      : baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
        _dio = dio ?? Dio() {
    final o = _dio.options;
    o.followRedirects = false;
    o.validateStatus = (_) => true;
    o.connectTimeout = const Duration(seconds: 20);
    o.receiveTimeout = const Duration(seconds: 40);
    o.headers['User-Agent'] =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) UMZSelf/0.1';
    // The server sends nameless cookies ("; SameSite=Strict") that make
    // Dart's cookie parser throw, so drop unparsable Set-Cookie values first.
    _dio.httpClientAdapter = _SanitizingAdapter(_dio.httpClientAdapter);
    _dio.interceptors.add(CookieManager(_jar));
  }

  final String baseUrl;
  final Dio _dio;
  final CookieJar _jar = CookieJar();

  String? _user;
  String? _pass;

  static const _json = 'application/json, text/plain, */*';

  bool _isRedirect(int? s) => s == 301 || s == 302 || s == 303 || s == 307;

  Future<Response<String>> _once(
    String method,
    String url, {
    Object? data,
    Map<String, dynamic>? query,
    String? contentType,
    Map<String, String>? headers,
  }) =>
      _dio.request<String>(
        url,
        data: data,
        queryParameters: query,
        options: Options(
          method: method,
          contentType: contentType,
          responseType: ResponseType.plain,
          headers: headers,
        ),
      );

  /// Follows redirects by hand (always as GET) so cookies are kept per hop.
  Future<Response<String>> _chase(Response<String> first) async {
    var cur = first;
    for (var hop = 0; hop < 10 && _isRedirect(cur.statusCode); hop++) {
      final loc = cur.headers.value('location');
      if (loc == null) break;
      cur = await _once('GET', cur.requestOptions.uri.resolve(loc).toString());
    }
    return cur;
  }

  /// True if the current cookie session is accepted by the API.
  Future<bool> isAuthenticated() async {
    final r = await _once('GET', '$baseUrl/api/v0/Credit',
        headers: {'Accept': _json});
    return r.statusCode == 200 && num.tryParse((r.data ?? '').trim()) != null;
  }

  /// Whether the login form currently demands a captcha.
  Future<bool> captchaActive() async {
    final r = await _once('GET', '$baseUrl/api/v0/Captcha',
        query: {'isactive': 'wehavecaptcha'});
    final t = (r.data ?? '').trim();
    return r.statusCode == 200 && t.isNotEmpty && t != '0';
  }

  /// Captcha image for the current session (PNG/JPEG bytes).
  Future<Uint8List> captchaImage() async {
    final r = await _dio.get<List<int>>(
      '$baseUrl/api/v0/Captcha',
      queryParameters: {'id': Random().nextInt(99999999)},
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(r.data ?? const []);
  }

  /// Full login: login form, then the OpenID `form_post` back to the site.
  /// Remembers the credentials in memory so expired sessions renew silently.
  Future<void> login(String username, String password,
      {String? captcha}) async {
    var page = await _chase(await _once('GET', '$baseUrl/'));
    var model = parseLoginModel(page.data ?? '');
    if (model == null) {
      if (await isAuthenticated()) {
        _user = username;
        _pass = password;
        return;
      }
      throw UmzException('Unrecognised login page (HTTP ${page.statusCode})');
    }

    if (captcha == null && await captchaActive()) {
      throw CaptchaRequiredException();
    }

    final fields = <String, String>{
      model.xsrfName: model.xsrfValue,
      'username': username,
      'password': password,
      if (captcha != null) 'Captcha': captcha,
    };
    final loginUri =
        Uri.parse('$baseUrl/').resolve(model.loginUrl).toString();
    var res = await _chase(await _once(
      'POST',
      loginUri,
      data: fields,
      contentType: Headers.formUrlEncodedContentType,
    ));

    // The success page auto-submits id_token/access_token back to the site.
    for (var i = 0; i < 3; i++) {
      final form = parseFormPost(res.data ?? '');
      if (form == null) break;
      final action = Uri.parse('$baseUrl/').resolve(form.action).toString();
      res = await _chase(await _once(
        'POST',
        action,
        data: form.fields,
        contentType: Headers.formUrlEncodedContentType,
      ));
    }

    final failed = parseLoginModel(res.data ?? '');
    if (failed != null) {
      final msg = failed.errorMessage;
      if (msg != null && (msg.startsWith('2FA') || msg.startsWith('W2FA'))) {
        throw OtpRequiredException(msg);
      }
      throw LoginFailedException(msg ?? 'Login failed');
    }
    if (!await isAuthenticated()) {
      throw LoginFailedException('Login did not produce a session');
    }
    _user = username;
    _pass = password;
  }

  /// Forgets the session and stored in-memory credentials.
  Future<void> logout() async {
    _user = null;
    _pass = null;
    await _jar.deleteAll();
  }

  bool _looksUnauthenticated(Response<String> r) {
    if (r.statusCode == 401 || _isRedirect(r.statusCode)) return true;
    return (r.data ?? '').trimLeft().startsWith('<');
  }

  Future<dynamic> _api(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
  }) async {
    Future<Response<String>> go() => _once(
          method,
          '$baseUrl$path',
          query: query,
          data: body,
          contentType: body == null ? null : 'application/json; charset=utf-8',
          headers: {'Accept': _json},
        );

    var r = await go();
    if (_looksUnauthenticated(r)) {
      final u = _user, p = _pass;
      if (u == null || p == null) throw SessionExpiredException();
      await login(u, p);
      r = await go();
      if (_looksUnauthenticated(r)) throw SessionExpiredException();
    }
    if (r.statusCode != 200) {
      throw UmzException('HTTP ${r.statusCode} for $path');
    }
    final text = (r.data ?? '').trim();
    return text.isEmpty ? null : jsonDecode(text);
  }

  /// Current balance in rial (negative = in debt).
  Future<int> credit() async {
    final v = await _api('GET', '/api/v0/Credit');
    return v is num ? v.toInt() : int.parse('$v');
  }

  /// One week of days. Pass the first `DayDate` of the shown week as
  /// [lastDate] with [navigation] = 7 / -7 to move; empty + 0 = this week.
  Future<List<Day>> week({String lastDate = '', int navigation = 0}) async {
    final v = await _api('GET', '/api/v0/Reservation',
        query: {'lastdate': lastDate, 'navigation': navigation});
    if (v is! List) return [];
    return v
        .whereType<Map>()
        .map((m) => Day.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// Sends reservations for ONE meal. HTTP is 200 even when refused, so check
  /// each [ReserveResult.ok].
  Future<List<ReserveResult>> reserve(List<ReserveRow> rows) async {
    final v = await _api('POST', '/api/v0/Reservation',
        body: rows.map((r) => r.toJson()).toList());
    if (v is! List) return [];
    return v
        .whereType<Map>()
        .map((m) => ReserveResult.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// Reservations between two Jalali dates (inclusive). Raw maps: the shape
  /// has not been mapped yet.
  Future<List<Map<String, dynamic>>> reservedList(
      String fromDate, String toDate) async {
    final v = await _api('GET', '/api/v0/Reservation',
        query: {'fromdate': fromDate, 'todate': toDate});
    if (v is! List) return [];
    return v
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }
}
