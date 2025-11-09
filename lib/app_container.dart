import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:password_vault/service/cache/cache_service.dart';
import 'package:password_vault/service/route/route_service.dart';
import 'package:password_vault/service/singletons/theme_change_manager.dart';
import 'package:password_vault/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class ThemeChangeNotifier extends Notifier<bool?> {
  @override
  bool? build() => null;
  
  void update(bool? value) => state = value;
}

final themeChangeProvider = NotifierProvider<ThemeChangeNotifier, bool?>(
  ThemeChangeNotifier.new,
);

final themeCacheProvider = FutureProvider<bool>((ref) async {
  return await CacheService().getThemeMode();
});


class PasswordVault extends ConsumerWidget {
  const PasswordVault({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var themeChange = ref.watch(themeChangeProvider);
    ThemeChangeService().initializeThemeChange(ref, themeChange);

    return MaterialApp.router(
      title: 'Vault',
      debugShowCheckedModeBanner: false,
      locale: const Locale('en', ''),
      supportedLocales: const [
        Locale('en', ''),
        Locale('fr', ''),
        Locale('zh', ''),
      ],
      localizationsDelegates: _getLocalizationsDelegates(),
      localeResolutionCallback: (locale, supportedLocales) => _getLocale(locale, supportedLocales),
      theme: ThemeChangeService().getThemeChangeValue() ? AppTheme.darkTheme : AppTheme.lightTheme,
      builder: EasyLoading.init(),
      routerConfig: createRouter(context, ref),
    );
  }

  List<LocalizationsDelegate> _getLocalizationsDelegates() {
    return [
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ];
  }

  Locale _getLocale(Locale? locale, Iterable<Locale> supportedLocales) {
    if (locale == null) {
      return supportedLocales.first;
    }
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return supportedLocale;
      }
    }
    return supportedLocales.first;
  }
}
