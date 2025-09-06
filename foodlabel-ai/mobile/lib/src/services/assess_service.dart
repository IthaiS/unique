import "dart:convert";
import "package:foodlabel_ai/src/models/reason.dart";
import "package:http/http.dart" as http;


class AssessResult {
  final int score;
  final String verdict;
  final List<Reason> reasons; // typed now

  const AssessResult(this.score, this.verdict, this.reasons);
}

class AssessService {
  static String baseUrl =
      const String.fromEnvironment("BACKEND_BASE_URL", defaultValue: "");

  static List<String> extractIngredients(String raw) {
    final canon = raw.toLowerCase().replaceAll(RegExp("[\\n\\r]"), " ");
    final parts = canon
        .split(RegExp(r"[;,]"))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return parts
        .map((s) => s.replaceAll(RegExp("[^a-z0-9 \\-\\(\\)]"), ""))
        .toList();
  }

  static Future<AssessResult> assess(List<String> ingredients) async {
    if (baseUrl.isEmpty) {
      // ---- Offline fallback mode (no backend): preserve same UX with messages
      int score = 0;
      final toks = ingredients.map((e) => e.trim().toLowerCase()).toList();
      final reasons = <Reason>[];

      // Simple messages similar to policy_v2.json
      String msg(String code, String param) {
        switch (code) {
          case "ALLERGEN_MATCH":
            return "Contains a major allergen.";
          case "VEGAN_CONFLICT":
            return "Contains animal-derived ingredient.";
          case "ADDITIVE_FLAG":
            return "Contains flagged additive: $param.";
          case "DEFAULT_UNSAFE":
            return "Contains an inedible/product-safety substance: $param.";
          case "HAZARDOUS_CHEM":
            return "Contains a hazardous chemical: $param.";
          default:
            return "No specific concerns matched; limited information.";
        }
      }

      if (toks.any((t) =>
          t.contains("milk") || t.contains("peanut") || t.contains("egg"))) {
        reasons.add(Reason(
          code: "ALLERGEN_MATCH",
          param: "major_allergen",
          message: msg("ALLERGEN_MATCH", "major_allergen"),
        ));
        score += 40;
      }
      if (toks.any((t) => t.contains("gelatin") || t.contains("cochineal"))) {
        reasons.add(Reason(
          code: "VEGAN_CONFLICT",
          param: "animal",
          message: msg("VEGAN_CONFLICT", "animal"),
        ));
        score += 30;
      }
      if (toks.any((t) => t.contains("e951") || t.contains("aspartame"))) {
        reasons.add(Reason(
          code: "ADDITIVE_FLAG",
          param: "E951",
          message: msg("ADDITIVE_FLAG", "E951"),
        ));
        score += 20;
      }
      if (reasons.isEmpty) {
        reasons.add(Reason(
          code: "UNKNOWN",
          param: "",
          message: msg("UNKNOWN", ""),
        ));
        score += 10;
      }
      final verdict =
          score >= 60 ? "avoid" : (score >= 30 ? "caution" : "safe");
      return AssessResult(score, verdict, reasons);
    }

    // ---- Online mode (backend)
    final resp = await http.post(
      Uri.parse("$baseUrl/v1/assess"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"ingredients": ingredients}),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final m = jsonDecode(resp.body) as Map<String, dynamic>;

      // Parse reasons as typed objects, including backend 'message'
      final List<dynamic> rawReasons = (m["reasons"] as List<dynamic>? ?? []);
      final reasons = rawReasons
          .map((e) => Reason.fromJson(e as Map<String, dynamic>))
          .toList();

      return AssessResult(
        (m["score"] as num).toInt(),
        (m["verdict"] as String?) ?? "safe",
        reasons,
      );
    } else {
      throw Exception("Backend error: ${resp.statusCode} ${resp.body}");
    }
  }
}
