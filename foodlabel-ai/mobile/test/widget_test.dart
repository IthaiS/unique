import 
"package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:foodlabel_ai/src/pages/home_page.dart";
void main(){
  testWidgets("Title", (WidgetTester tester) async {
    final t={"en":{"app":{"title":"FoodLabel 
AI"},"action":{"scan_label":"Scan 
label"},"hint":{"desktop_cloud_ocr":"Desktop uses cloud 
OCR."},"label":{"recognized_text":"Recognized 
text","ingredients":"Ingredients","assessment":"Assessment"},"assess":{"verdict":{"safe":"SAFE","caution":"CAUTION","avoid":"AVOID"},"score":"Score: 
{score}"},"reason":{"UNKNOWN":"No specific 
issues.","ALLERGEN_MATCH":"Contains allergen 
{param}.","VEGAN_CONFLICT":"Non-vegan.","ADDITIVE_FLAG":"Contains additive 
{param}."}}};
    await tester.pumpWidget(MaterialApp(locale: const Locale("en"),
      supportedLocales: const [Locale("en")],
      localizationsDelegates: const 
[GlobalMaterialLocalizations.delegate,GlobalWidgetsLocalizations.delegate,GlobalCupertinoLocalizations.delegate],
      home: HomePage(onLocaleChange: (_){}, translations: t),
    ));
    await tester.pumpAndSettle();
    expect(find.text("FoodLabel AI"), findsOneWidget);
  });
}
