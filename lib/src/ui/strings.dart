/// Minimal two-language string table (fa default, en).
const Map<String, Map<String, String>> _strings = {
  'fa': {
    'appTitle': 'سلف دانشگاه مازندران',
    'username': 'نام کاربری',
    'password': 'رمز عبور',
    'remember': 'مرا به خاطر بسپار',
    'login': 'ورود',
    'captcha': 'کد امنیتی',
    'captchaHint': 'کد امنیتی را وارد کنید',
    'refresh': 'بروزرسانی',
    'logout': 'خروج',
    'credit': 'اعتبار',
    'toman': 'تومان',
    'thisWeek': 'هفته جاری',
    'prevWeek': 'هفته قبل',
    'nextWeek': 'هفته بعد',
    'reserve': 'رزرو',
    'confirmTitle': 'تأیید رزرو',
    'youPay': 'مبلغ پرداختی شما',
    'cancel': 'انصراف',
    'confirm': 'تأیید',
    'reserved': 'رزرو شد',
    'reserveCode': 'کد رزرو',
    'noMenu': 'منو ندارد',
    'language': 'English',
    'loading': 'در حال بارگذاری...',
    'sessionError': 'خطا در ارتباط با سرور',
    'otpUnsupported': 'این حساب کد یک‌بار مصرف می‌خواهد که هنوز پشتیبانی نمی‌شود',
  },
  'en': {
    'appTitle': 'UMZ Self',
    'username': 'Username',
    'password': 'Password',
    'remember': 'Remember me',
    'login': 'Sign in',
    'captcha': 'Security code',
    'captchaHint': 'Enter the security code',
    'refresh': 'Refresh',
    'logout': 'Sign out',
    'credit': 'Balance',
    'toman': 'Toman',
    'thisWeek': 'This week',
    'prevWeek': 'Previous week',
    'nextWeek': 'Next week',
    'reserve': 'Reserve',
    'confirmTitle': 'Confirm reservation',
    'youPay': 'You pay',
    'cancel': 'Cancel',
    'confirm': 'Confirm',
    'reserved': 'Reserved',
    'reserveCode': 'Reserve code',
    'noMenu': 'No menu',
    'language': 'فارسی',
    'loading': 'Loading...',
    'sessionError': 'Could not reach the server',
    'otpUnsupported': 'This account needs a one-time code, which is not supported yet',
  },
};

String tr(String lang, String key) =>
    _strings[lang]?[key] ?? _strings['en']![key] ?? key;

/// Rial -> toman with thousands separators, e.g. -850000 -> "-85,000".
String formatToman(int rial) {
  final toman = rial ~/ 10;
  final neg = toman < 0;
  final digits = toman.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return neg ? '-$buf' : '$buf';
}
