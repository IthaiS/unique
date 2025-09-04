import 
"package:flutter/material.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "src/pages/home_page.dart";
import "src/services/i18n.dart";

void main(){ WidgetsFlutterBinding.ensureInitialized(); runApp(const 
FoodLabelApp()); }
class FoodLabelApp extends StatefulWidget{ const 
FoodLabelApp({super.key}); @override State<FoodLabelApp> 
createState()=>_S(); }
class _S extends State<FoodLabelApp>{
  Locale _loc=const Locale("en"); Map<String,dynamic> _t={};
  @override void initState(){ super.initState(); 
I18n.loadTranslations(["en","nl_BE","fr_BE"]).then((m){ 
setState(()=>_t=m);}); }
  void _setLocale(Locale l)=>setState(()=>_loc=l);
  @override Widget build(BuildContext c)=>MaterialApp(
    title:"FoodLabel AI", debugShowCheckedModeBanner:false, locale:_loc,
    supportedLocales: const [Locale("en"), Locale("nl","BE"), 
Locale("fr","BE")],
    localizationsDelegates: const 
[GlobalMaterialLocalizations.delegate,GlobalWidgetsLocalizations.delegate,GlobalCupertinoLocalizations.delegate],
    home: HomePage(onLocaleChange:_setLocale, translations:_t),
  );
}
