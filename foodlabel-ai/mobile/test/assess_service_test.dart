import 'package:flutter_test/flutter_test.dart';
import 'package:foodlabel_ai/src/services/assess_service.dart';
void main(){ test('extractIngredients splits on separators', (){
  final tokens = AssessService.extractIngredients('Milk, Sugar; E951 (Aspartame)');
  expect(tokens.any((t)=>t.contains('milk')), true);
  expect(tokens.any((t)=>t.contains('e951')), true);
});}
