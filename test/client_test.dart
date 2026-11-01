import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:umz_self/src/api/models.dart';
import 'package:umz_self/src/api/umz_client.dart';

import 'fake_server.dart';
import 'happy_server.dart';

void main() {
  group('parseLoginModel', () {
    test('decodes entity-encoded model', () {
      final m = parseLoginModel(loginPage())!;
      expect(m.loginUrl, '/identity/login?signin=abc');
      expect(m.xsrfName, 'idsrv.xsrf');
      expect(m.xsrfValue, 'tok123');
      expect(m.errorMessage, isNull);
    });

    test('returns null for non-login pages', () {
      expect(parseLoginModel('<html>hi</html>'), isNull);
    });

    test('reads error message', () {
      expect(parseLoginModel(loginPage(error: 'bad'))!.errorMessage, 'bad');
    });
  });

  group('parseFormPost', () {
    test('extracts action and hidden fields', () {
      final f = parseFormPost(formPostPage)!;
      expect(f.action, 'https://self.umz.ac.ir');
      expect(f.fields['id_token'], 'idt');
      expect(f.fields['state'], 'st');
    });

    test('ignores ordinary forms', () {
      expect(parseFormPost('<form><input name="x" value="1"></form>'), isNull);
    });
  });

  group('UmzClient.login', () {
    test('completes the full redirect + form_post flow', () async {
      final server = happyServer();
      final client = UmzClient(dio: Dio()..httpClientAdapter = server);
      await client.login('user', 'good');
      expect(await client.credit(), -850000);
      expect(server.log, contains('POST /identity/login'));
      expect(server.log, contains('POST /'));
    });

    test('wrong password throws LoginFailedException with server text',
        () async {
      final client =
          UmzClient(dio: Dio()..httpClientAdapter = happyServer());
      expect(
        () => client.login('user', 'bad'),
        throwsA(isA<LoginFailedException>()
            .having((e) => e.message, 'message', contains('اشتباه'))),
      );
    });

    test('captcha demanded without a code throws CaptchaRequiredException',
        () async {
      final server = happyServer();
      server.routes['GET /api/v0/Captcha'] = (_) => page('1');
      final client = UmzClient(dio: Dio()..httpClientAdapter = server);
      expect(() => client.login('user', 'good'),
          throwsA(isA<CaptchaRequiredException>()));
    });

    test('2FA error message maps to OtpRequiredException', () async {
      final server = happyServer();
      server.routes['POST /identity/login'] =
          (_) => page(loginPage(error: '2FA 120 enter code'));
      final client = UmzClient(dio: Dio()..httpClientAdapter = server);
      expect(() => client.login('user', 'good'),
          throwsA(isA<OtpRequiredException>()));
    });
  });

  test('expired session is renewed transparently', () async {
    final session = Session();
    final server = happyServer(session);
    final client = UmzClient(dio: Dio()..httpClientAdapter = server);
    await client.login('user', 'good');

    session.authed = false; // server forgets the session
    expect(await client.credit(), -850000);
    expect(server.log.where((l) => l == 'POST /identity/login').length, 2);
  });

  test('reserve parses the real insufficient-balance reply', () async {
    final server = happyServer();
    server.routes['POST /api/v0/Reservation'] = (_) => jsonBody([
          {
            'Row': 1,
            'ID': -1,
            'Date': '1405/08/13',
            'MealID': 1,
            'FoodID': 1298,
            'SelfID': 10,
            'Count': 1,
            'Price': 100000,
            'PriceType': 2,
            'SobsidPrice': 900000,
            'State': 2,
            'StateCode': 3,
            'StateMessage': 'موجودی کافی نمی باشد',
            'ReserveNumber': null,
          }
        ]);
    final client = UmzClient(dio: Dio()..httpClientAdapter = server);
    await client.login('user', 'good');

    final day = Day.fromJson({'DayDate': '1405/08/13', 'DayTitle': 'چهارشنبه'});
    final meal = Meal.fromJson({
      'Id': 21,
      'MealId': 1,
      'MealName': 'صبحانه',
      'MealState': 0,
      'FoodCountLimit': [
        {'FoodType': 1, 'PriceType': 2, 'MaxCount': 1, 'TotalCount': 1}
      ],
    });
    final food = Food.fromJson({'FoodId': 1298, 'FoodName': 'x', 'FoodType': 1});
    final offer = SelfOffer.fromJson(
        {'SelfId': 10, 'SelfName': 's', 'Price': 1000000, 'Yarane': 900000});

    final res = await client.reserve(
        [ReserveRow.forOffer(day: day, meal: meal, food: food, offer: offer)]);
    expect(res, hasLength(1));
    expect(res.first.ok, isFalse);
    expect(res.first.stateCode, 3);
    expect(res.first.stateMessage, contains('موجودی'));
  });
}
