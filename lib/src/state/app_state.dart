import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../api/models.dart';
import '../api/umz_client.dart';
import '../storage/credential_store.dart';
import '../ui/strings.dart';

enum AuthStatus { starting, loggedOut, loggingIn, loggedIn }

class AppState extends ChangeNotifier {
  AppState({UmzClient? client, CredentialStore? store})
      : client = client ?? UmzClient(),
        store = store ?? SecureCredentialStore();

  final UmzClient client;
  final CredentialStore store;

  AuthStatus status = AuthStatus.starting;
  String lang = 'fa';

  /// Error text for the login form.
  String? loginError;

  /// Set when the server asks for a captcha; [captchaImage] holds the picture.
  bool captchaNeeded = false;
  Uint8List? captchaImage;

  String? username;
  int? credit;
  List<Day> week = [];
  bool loadingWeek = false;
  String? weekError;

  bool get rtl => lang == 'fa';
  String t(String key) => tr(lang, key);

  /// Loads settings and tries to sign in with the last saved account.
  Future<void> start() async {
    lang = await store.language() ?? 'fa';
    final last = await store.lastUsername();
    Account? saved;
    for (final a in await store.accounts()) {
      if (a.username == last) saved = a;
    }
    if (saved == null) {
      status = AuthStatus.loggedOut;
      notifyListeners();
      return;
    }
    await login(saved.username, saved.password, remember: true);
  }

  Future<void> toggleLanguage() async {
    lang = lang == 'fa' ? 'en' : 'fa';
    notifyListeners();
    await store.setLanguage(lang);
  }

  Future<void> login(String user, String pass,
      {bool remember = false, String? captcha}) async {
    status = AuthStatus.loggingIn;
    loginError = null;
    notifyListeners();
    try {
      await client.login(user, pass, captcha: captcha);
      username = user;
      captchaNeeded = false;
      captchaImage = null;
      if (remember) {
        await store.save(Account(user, pass));
      } else {
        await store.setLastUsername(null);
      }
      status = AuthStatus.loggedIn;
      notifyListeners();
      await refresh();
    } on CaptchaRequiredException {
      captchaNeeded = true;
      captchaImage = await client.captchaImage();
      status = AuthStatus.loggedOut;
      notifyListeners();
    } on OtpRequiredException {
      loginError = t('otpUnsupported');
      status = AuthStatus.loggedOut;
      notifyListeners();
    } on UmzException catch (e) {
      loginError = e.message;
      status = AuthStatus.loggedOut;
      notifyListeners();
    } on Object {
      loginError = t('sessionError');
      status = AuthStatus.loggedOut;
      notifyListeners();
    }
  }

  Future<void> reloadCaptcha() async {
    captchaImage = await client.captchaImage();
    notifyListeners();
  }

  Future<void> logout({bool forget = true}) async {
    final u = username;
    await client.logout();
    if (forget && u != null) await store.remove(u);
    username = null;
    credit = null;
    week = [];
    status = AuthStatus.loggedOut;
    notifyListeners();
  }

  Future<void> refresh() async {
    await Future.wait([_loadCredit(), loadWeek()]);
  }

  Future<void> _loadCredit() async {
    try {
      credit = await client.credit();
    } on Object {
      // Keep the old value; the week error banner covers connectivity.
    }
    notifyListeners();
  }

  /// [direction] 0 = this week, 1 = next, -1 = previous.
  Future<void> loadWeek({int direction = 0}) async {
    loadingWeek = true;
    weekError = null;
    notifyListeners();
    try {
      final anchor = week.isEmpty ? '' : week.first.date;
      week = direction == 0
          ? await client.week()
          : await client.week(lastDate: anchor, navigation: direction * 7);
    } on UmzException catch (e) {
      weekError = e.message;
    } on Object {
      weekError = t('sessionError');
    }
    loadingWeek = false;
    notifyListeners();
  }

  /// Reserves one food. Returns the server's verdict for display.
  Future<ReserveResult?> reserve(
      Day day, Meal meal, Food food, SelfOffer offer) async {
    final row = ReserveRow.forOffer(
        day: day, meal: meal, food: food, offer: offer);
    final results = await client.reserve([row]);
    await refresh();
    return results.isEmpty ? null : results.first;
  }
}
