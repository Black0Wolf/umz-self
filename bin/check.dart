// Read-only live check: logs in and prints balance + this week's menu.
//
//   dart run bin/check.dart            (reads UMZ_USER / UMZ_PASS from env)
//
// Never reserves or changes anything.
import 'dart:io';

import 'package:umz_self/src/api/umz_client.dart';
import 'package:umz_self/src/ui/strings.dart';

Future<void> main() async {
  final user = Platform.environment['UMZ_USER'];
  final pass = Platform.environment['UMZ_PASS'];
  if (user == null || pass == null) {
    stderr.writeln('Set UMZ_USER and UMZ_PASS environment variables first.');
    exitCode = 64;
    return;
  }

  final client = UmzClient();
  try {
    await client.login(user, pass);
  } on CaptchaRequiredException {
    stderr.writeln('The server wants a captcha; sign in once in a browser, '
        'then retry later.');
    exitCode = 2;
    return;
  } on UmzException catch (e) {
    stderr.writeln('Login failed: ${e.message}');
    exitCode = 1;
    return;
  }

  stdout.writeln('Balance: ${formatToman(await client.credit())} toman');
  for (final day in await client.week()) {
    stdout.writeln('\n${day.title} ${day.date}  [${day.stateTitle}]');
    for (final meal in day.mealsWithMenu) {
      stdout.writeln('  ${meal.name} (${meal.stateTitle})');
      for (final food in meal.foods) {
        for (final o in food.offers) {
          stdout.writeln('    - ${food.name} @ ${o.selfName}: '
              '${formatToman(o.studentPays)} toman');
        }
      }
    }
  }
}
