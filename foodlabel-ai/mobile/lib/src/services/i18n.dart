import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';

class I18n {
  static Future<Map<String, dynamic>> loadTranslations(List<String> locales) async {
    final map = <String, dynamic>{};
    for (final l in locales) {
      final path = l == 'en' ? 'assets/i18n/en.json' : 'assets/i18n/${l}.json';
      final s = await rootBundle.loadString(path);
      map[l] = jsonDecode(s);
    }
    return map;
  }

  static String t(Map<String, dynamic> translations, Locale locale, String key, {Map<String,String>? params}) {
    final tag = locale.languageCode == 'en' ? 'en'
      : (locale.languageCode == 'nl' ? 'nl_BE' : 'fr_BE');
    final parts = key.split('.');
    dynamic curr = translations[tag];
    for (final p in parts) {
      if (curr==null) break;
      curr = curr[p];
    }
    String result = curr?.toString() ?? key;
    params?.forEach((k, v) { result = result.replaceAll('{$k}', v); });
    return result;
  }
}
