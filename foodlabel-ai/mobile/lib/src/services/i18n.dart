import "dart:convert";
import "package:flutter/services.dart" show rootBundle;
import "package:flutter/material.dart";
class I18n {
  static Future<Map<String, dynamic>> loadTranslations(List<String> 
locales) async {
    final map=<String, dynamic>{};
    for (final l in locales) {
      final path = l=="en" ? "assets/i18n/en.json" : 
"assets/i18n/${l}.json";
      final s = await rootBundle.loadString(path);
      map[l] = jsonDecode(s);
    }
    return map;
  }
  static String t(Map<String,dynamic> t, Locale loc, String 
key,{Map<String,String>? params}){
    final tag = loc.languageCode=="en" ? "en" : (loc.languageCode=="nl" ? 
"nl_BE" : "fr_BE");
    dynamic cur=t[tag];
    for(final p in key.split(".")){ if(cur==null) break; cur=cur[p]; }
    String res = cur?.toString() ?? key;
    params?.forEach((k,v){ res=res.replaceAll("{$k}", v); });
    return res;
  }
}
