import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'src/pages/home_page.dart';
import 'src/services/i18n.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FoodLabelApp());
}

class FoodLabelApp extends StatefulWidget {
  const FoodLabelApp({super.key});
  @override
  State<FoodLabelApp> createState() => _FoodLabelAppState();
}

class _FoodLabelAppState extends State<FoodLabelApp> {
  Locale _locale = const Locale('en');
  Map<String, dynamic> _translations = {};

  @override
  void initState() {
    super.initState();
    I18n.loadTranslations(['en','nl_BE','fr_BE']).then((map) {
      setState(() { _translations = map; });
    });
  }

  void _setLocale(Locale locale) {
    setState(() { _locale = locale; });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodLabel AI',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: const [
        Locale('en'),
        Locale('nl', 'BE'),
        Locale('fr', 'BE'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: HomePage(onLocaleChange: _setLocale, translations: _translations),
    );
  }
}
