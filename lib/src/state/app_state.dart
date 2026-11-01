import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/models.dart';
import '../api/umz_client.dart';
import '../logic/planner.dart';
import '../logic/stats.dart';
import '../storage/credential_store.dart';
import '../storage/ledger_store.dart';
import '../storage/settings_store.dart';
import '../ui/strings.dart';

enum AuthStatus { starting, loggedOut, loggingIn, loggedIn }

/// Outcome of a batch of reservations.
class ReserveSummary {
  int reserved = 0;
  int spentRial = 0;
  final List<String> failures = [];

  /// True if the batch stopped early because the balance was too low.
  bool stoppedForBalance = false;
}

class AppState extends ChangeNotifier {
  AppState({
    UmzClient? client,
    CredentialStore? store,
    LedgerStore? ledgerStore,
    SettingsStore? settings,
    this.autoInterval = const Duration(minutes: 5),
    this.pauseBetweenReserves = const Duration(milliseconds: 600),
  })  : client = client ?? UmzClient(),
        store = store ?? SecureCredentialStore(),
        ledgerStore = ledgerStore ?? PrefsLedgerStore(),
        settings = settings ?? PrefsSettingsStore();

  final UmzClient client;
  final CredentialStore store;
  final LedgerStore ledgerStore;
  final SettingsStore settings;

  /// How often auto-reserve looks for new meals while the app is open.
  Duration autoInterval;

  /// Gap between reserve calls so the server is not hammered.
  final Duration pauseBetweenReserves;

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

  /// Reservations made through this app (basis of the stats screen).
  List<LedgerEntry> ledger = [];

  bool reserving = false;
  bool autoReserve = false;
  DateTime? lastAutoRun;

  /// Newest first; shown in the activity dialog.
  final List<String> activity = [];

  Timer? _autoTimer;
  bool _autoBusy = false;
  int? _blockedAtCredit;
  final Set<String> _failedKeys = {};

  bool get rtl => lang == 'fa';
  String t(String key) => tr(lang, key);

  /// Loads settings and tries to sign in with the last saved account.
  Future<void> start() async {
    lang = await store.language() ?? 'fa';
    final minutes = await settings.autoIntervalMinutes();
    if (minutes != null && minutes > 0) {
      autoInterval = Duration(minutes: minutes);
    }
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
      ledger = await ledgerStore.load(user);
      autoReserve = await store.autoReserve();
      status = AuthStatus.loggedIn;
      notifyListeners();
      await refresh();
      if (autoReserve) _startAuto();
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
    } on Object catch (e) {
      loginError = '${t('sessionError')}\n$e';
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
    _stopAuto();
    await client.logout();
    if (forget && u != null) await store.remove(u);
    username = null;
    credit = null;
    week = [];
    ledger = [];
    activity.clear();
    _failedKeys.clear();
    _blockedAtCredit = null;
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
    } on Object catch (e) {
      weekError = '${t('sessionError')}\n$e';
    }
    loadingWeek = false;
    notifyListeners();
  }

  /// Reserves one food. Returns the server's verdict for display.
  Future<ReserveResult?> reserve(
      Day day, Meal meal, Food food, SelfOffer offer) async {
    final plan = PlannedReservation(day, meal, food, offer);
    final results = await client.reserve([plan.row]);
    final r = results.isEmpty ? null : results.first;
    if (r != null && r.ok) await _record(plan, r, auto: false);
    await refresh();
    return r;
  }

  /// What "reserve all" would book for the week currently on screen.
  List<PlannedReservation> planVisibleWeek() => planReservations(week);

  /// Reserves each plan one at a time, stopping early if the balance runs out.
  Future<ReserveSummary> reserveAll(List<PlannedReservation> plans,
      {bool auto = false}) async {
    final summary = ReserveSummary();
    reserving = true;
    notifyListeners();
    try {
      for (var i = 0; i < plans.length; i++) {
        final p = plans[i];
        final label = '${p.day.title} ${p.day.date} ${p.meal.name}';
        try {
          final results = await client.reserve([p.row]);
          final r = results.isEmpty ? null : results.first;
          if (r != null && r.ok) {
            await _record(p, r, auto: auto);
            summary.reserved++;
            summary.spentRial += p.price;
          } else if (r != null &&
              r.stateCode == stateCodeInsufficientBalance) {
            summary.failures.add('$label: ${r.stateMessage ?? r.stateCode}');
            summary.stoppedForBalance = true;
            break;
          } else {
            _failedKeys.add(p.key);
            summary.failures.add(
                '$label: ${r?.stateMessage ?? t('sessionError')}');
          }
        } on UmzException catch (e) {
          _failedKeys.add(p.key);
          summary.failures.add('$label: ${e.message}');
        }
        if (i < plans.length - 1) await Future<void>.delayed(pauseBetweenReserves);
      }
    } finally {
      reserving = false;
    }
    await _loadCredit();
    if (summary.stoppedForBalance) _blockedAtCredit = credit;
    if (summary.reserved > 0 || summary.failures.isNotEmpty) {
      await loadWeek();
    }
    notifyListeners();
    return summary;
  }

  Future<void> _record(PlannedReservation p, ReserveResult r,
      {required bool auto}) async {
    final u = username;
    ledger = [
      ...ledger,
      LedgerEntry(
        date: p.day.date,
        mealId: p.meal.mealId,
        mealName: p.meal.name,
        foodName: p.food.name,
        selfName: p.offer.selfName,
        priceRial: p.price,
        reserveNumber: r.reserveNumber ?? '',
        at: DateTime.now(),
        auto: auto,
      ),
    ];
    if (u != null) await ledgerStore.save(u, ledger);
  }

  Stats get stats => Stats.from(ledger);

  // ---- auto-reserve -------------------------------------------------------

  Future<void> setAutoReserve(bool on) async {
    autoReserve = on;
    await store.setAutoReserve(on);
    if (on) {
      _failedKeys.clear();
      _blockedAtCredit = null;
      _startAuto();
    } else {
      _stopAuto();
    }
    notifyListeners();
  }

  /// Changes how often auto-reserve checks; restarts the timer if running.
  Future<void> setAutoInterval(int minutes) async {
    autoInterval = Duration(minutes: minutes);
    notifyListeners();
    await settings.setAutoIntervalMinutes(minutes);
    if (_autoTimer != null) {
      _autoTimer?.cancel();
      _autoTimer = Timer.periodic(autoInterval, (_) => autoTick());
    }
  }

  void _startAuto() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(autoInterval, (_) => autoTick());
    unawaited(autoTick());
  }

  void _stopAuto() {
    _autoTimer?.cancel();
    _autoTimer = null;
  }

  void _log(String message) {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    activity.insert(0, '${two(now.hour)}:${two(now.minute)}  $message');
    if (activity.length > 50) activity.removeRange(50, activity.length);
  }

  /// One auto-reserve pass over this week and next. Public for tests.
  Future<void> autoTick() async {
    if (_autoBusy || reserving || status != AuthStatus.loggedIn) return;
    _autoBusy = true;
    try {
      final c = await client.credit();
      credit = c;
      if (_blockedAtCredit != null && _blockedAtCredit == c) {
        return; // still short of money; nothing changed since the last try
      }
      _blockedAtCredit = null;

      final days = [...await client.week()];
      if (days.isNotEmpty) {
        days.addAll(
            await client.week(lastDate: days.first.date, navigation: 7));
      }
      final plans = planReservations(days, skip: _failedKeys);
      if (plans.isEmpty) return;

      final s = await reserveAll(plans, auto: true);
      if (s.reserved > 0) {
        _log('${t('autoReserve')}: ${t('reservedN')} ${s.reserved} · '
            '${formatToman(s.spentRial)} ${t('toman')}');
      }
      for (final f in s.failures) {
        _log(f);
      }
      if (s.stoppedForBalance) _log(t('waitingBalance'));
    } on Object catch (e) {
      _log('${t('sessionError')}: $e');
    } finally {
      _autoBusy = false;
      lastAutoRun = DateTime.now();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }
}
