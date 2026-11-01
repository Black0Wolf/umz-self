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
    'reserveAll': 'رزرو همه موارد قابل رزرو',
    'reserveAllTitle': 'رزرو همه',
    'nothingToReserve': 'موردی برای رزرو در این هفته وجود ندارد',
    'items': 'مورد',
    'total': 'جمع',
    'autoReserve': 'رزرو خودکار',
    'autoReserveHint':
        'تا وقتی برنامه باز است، وعده‌های جدید این هفته و هفته بعد را رزرو می‌کند',
    'lastRun': 'آخرین بررسی',
    'activity': 'گزارش فعالیت',
    'noActivity': 'هنوز فعالیتی ثبت نشده',
    'close': 'بستن',
    'reservedN': 'رزرو شد:',
    'failedN': 'ناموفق:',
    'waitingBalance': 'اعتبار کافی نیست؛ با تغییر اعتبار دوباره تلاش می‌شود',
    'stats': 'آمار',
    'statsNote':
        'فقط رزروهایی که با این برنامه انجام شده‌اند؛ تغییرات سایت دیده نمی‌شود',
    'noStats': 'هنوز رزروی با این برنامه ثبت نشده',
    'totalSpent': 'مجموع هزینه',
    'mealsReserved': 'وعده‌های رزرو شده',
    'average': 'میانگین هر وعده',
    'byMeal': 'بر اساس وعده',
    'byMonth': 'هزینه هر ماه',
    'topFoods': 'پرتکرارترین غذاها',
    'bySelf': 'بر اساس سلف',
    'viaAuto': 'رزرو خودکار',
    'viaManual': 'رزرو دستی',
    'mostExpensive': 'گران‌ترین وعده',
    'settings': 'تنظیمات',
    'appearance': 'ظاهر',
    'themeMode': 'حالت نمایش',
    'modeSystem': 'سیستم',
    'modeLight': 'روشن',
    'modeDark': 'تیره',
    'palette': 'رنگ تم',
    'languageLabel': 'زبان',
    'checkEvery': 'بررسی هر',
    'minutes': 'دقیقه',
    'account': 'حساب کاربری',
    'signedInAs': 'وارد شده با',
    'about': 'درباره',
    'aboutText': 'برنامه غیررسمی برای سامانه رزرو غذای دانشگاه مازندران',
    'today': 'امروز',
    'reservedTag': 'رزرو شده',
    'back': 'بازگشت',
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
    'reserveAll': 'Reserve everything available',
    'reserveAllTitle': 'Reserve all',
    'nothingToReserve': 'Nothing to reserve in this week',
    'items': 'items',
    'total': 'Total',
    'autoReserve': 'Auto-reserve',
    'autoReserveHint':
        'While the app is open, reserves new meals this week and next',
    'lastRun': 'Last check',
    'activity': 'Activity log',
    'noActivity': 'No activity yet',
    'close': 'Close',
    'reservedN': 'Reserved:',
    'failedN': 'Failed:',
    'waitingBalance': 'Balance too low; will retry when it changes',
    'stats': 'Stats',
    'statsNote':
        'Only reservations made with this app; changes made on the website are not seen',
    'noStats': 'No reservations made with this app yet',
    'totalSpent': 'Total spent',
    'mealsReserved': 'Meals reserved',
    'average': 'Average per meal',
    'byMeal': 'By meal',
    'byMonth': 'Spent per month',
    'topFoods': 'Most reserved foods',
    'bySelf': 'By dining hall',
    'viaAuto': 'Auto-reserved',
    'viaManual': 'Reserved manually',
    'mostExpensive': 'Most expensive meal',
    'settings': 'Settings',
    'appearance': 'Appearance',
    'themeMode': 'Mode',
    'modeSystem': 'System',
    'modeLight': 'Light',
    'modeDark': 'Dark',
    'palette': 'Accent palette',
    'languageLabel': 'Language',
    'checkEvery': 'Check every',
    'minutes': 'min',
    'account': 'Account',
    'signedInAs': 'Signed in as',
    'about': 'About',
    'aboutText': 'Unofficial client for the University of Mazandaran food reservation system',
    'today': 'Today',
    'reservedTag': 'Reserved',
    'back': 'Back',
  },
};

/// Server meal states, translated for English; Persian keeps the server text.
String mealStateLabel(String lang, int state, String serverTitle) {
  if (lang == 'fa') {
    if (serverTitle.isNotEmpty) return serverTitle;
    return const {
          0: 'باز برای رزرو',
          1: 'بسته',
          4: 'خارج از زمان‌بندی',
          5: 'برنامه تعریف نشده',
          6: 'امکان رزرو نیست',
        }[state] ??
        '';
  }
  return const {
        0: 'Open',
        1: 'Closed',
        4: 'Outside schedule',
        5: 'No program',
        6: 'Unavailable today',
      }[state] ??
      serverTitle;
}

String dayStateLabel(String lang, int state, String serverTitle) {
  if (lang == 'fa') return serverTitle;
  return const {
        0: 'Active',
        2: 'Inactive',
        4: 'Holiday',
        5: 'No schedule',
      }[state] ??
      serverTitle;
}

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
