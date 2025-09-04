import 
"dart:convert";
import "package:http/http.dart" as http;
class AssessResult{ final int score; final String verdict; final 
List<dynamic> reasons; AssessResult(this.score,this.verdict,this.reasons); 
}
class AssessService{
  static String baseUrl=const String.fromEnvironment("BACKEND_BASE_URL", 
defaultValue:"");
  static List<String> extractIngredients(String raw){
    final canon=raw.toLowerCase().replaceAll(RegExp("[\\n\\r]"), " ");
    final 
parts=canon.split(RegExp(r"[;,]")).map((s)=>s.trim()).where((s)=>s.isNotEmpty).toList();
    return parts.map((s)=>s.replaceAll(RegExp("[^a-z0-9 \\-\\(\\)]"), 
"")).toList();
  }
  static Future<AssessResult> assess(List<String> ingredients) async {
    if(baseUrl.isEmpty){
      int score=0; final reasons=<Map<String,String>>[];
      final toks=ingredients.map((e)=>e.trim()).toList();
      
if(toks.any((t)=>t.contains("milk")||t.contains("peanut")||t.contains("egg"))){ 
reasons.add({"code":"ALLERGEN_MATCH","param":"major_allergen"}); 
score+=40; }
      if(toks.any((t)=>t.contains("gelatin")||t.contains("cochineal"))){ 
reasons.add({"code":"VEGAN_CONFLICT","param":"animal"}); score+=30; }
      if(toks.any((t)=>t.contains("e951")||t.contains("aspartame"))){ 
reasons.add({"code":"ADDITIVE_FLAG","param":"E951"}); score+=20; }
      if(reasons.isEmpty){ reasons.add({"code":"UNKNOWN","param":""}); 
score+=10; }
      final verdict= score>=60? "avoid" : (score>=30? "caution" : "safe");
      return AssessResult(score, verdict, reasons);
    }
    final resp=await http.post(Uri.parse("$baseUrl/v1/assess"), 
headers:{"Content-Type":"application/json"}, 
body:jsonEncode({"ingredients":ingredients}));
    if(resp.statusCode>=200&&resp.statusCode<300){
      final m=jsonDecode(resp.body); return AssessResult(m["score"] as 
int, m["verdict"] as String, m["reasons"] as List<dynamic>);
    } else { throw Exception("Backend error: ${resp.statusCode} 
${resp.body}"); }
  }
}
