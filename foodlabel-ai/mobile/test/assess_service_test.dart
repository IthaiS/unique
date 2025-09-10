import "package:flutter_test/flutter_test.dart";
import "package:foodlabel_ai/src/services/assess_service.dart";

void main(){ test("extractIngredients",(){ final 
t=AssessService.extractIngredients("Milk, Sugar; E951"); 
expect(t.any((e)=>e.contains("milk")), true); }); }
