import 'package:flutter_test/flutter_test.dart';
import 'package:your_package/case_model.dart';

void main() {
  test('Case Model should create an instance correctly', () {
    final caseModel = CaseModel(id: 1, title: 'Test Case');
    expect(caseModel.id, 1);
    expect(caseModel.title, 'Test Case');
  });
}