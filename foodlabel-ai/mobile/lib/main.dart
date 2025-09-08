import "package:flutter/material.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "src/pages/home_page.dart";
import "src/pages/login_page.dart";
import "src/pages/profile_edit_page.dart";
import "src/pages/profiles_page.dart";
import "src/pages/settings_page.dart";
import "src/pages/owner_settings_page.dart";
import "src/pages/owner_profile_page.dart";
import "src/app_shell.dart";
import "src/services/i18n.dart";
import "src/services/auth_service.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.init();
  runApp(const FoodLabelApp());
}

class FoodLabelApp extends StatefulWidget {
  const FoodLabelApp({super.key});
  @override
  State<FoodLabelApp> createState() => _S();
}

class _S extends State<FoodLabelApp> {
  Locale _loc = const Locale("en");
  Map<String, dynamic> _t = {};
  @override
  void initState() {
    super.initState();
    I18n.loadTranslations(["en", "nl_BE", "fr_BE"]).then((m) {
      setState(() => _t = m);
    });
  }

  void _setLocale(Locale l) => setState(() => _loc = l);
  @override
  Widget build(BuildContext c) => MaterialApp(
        title: "FoodLabel AI",
        debugShowCheckedModeBanner: false,
        locale: _loc,
        supportedLocales: const [
          Locale("en"),
          Locale("nl", "BE"),
          Locale("fr", "BE")
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        home: AppShell(onLocaleChange: _setLocale, translations: _t),
        initialRoute: AuthService.token == null ? '/login' : '/app',
        routes: {
          '/settings': (context) => const SettingsPage(),
          '/owner/profile': (context) => const OwnerProfilePage(),
          '/owner/settings': (context) => const OwnerSettingsPage(),
          '/app': (context) => AppShell(onLocaleChange: _setLocale, translations: _t),
          '/login': (context) => LoginPage(),
          '/profiles': (context) => ProfilesPage(),
          '/profile_edit': (context) => ProfileEditPage(),
        },
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
      );
}
