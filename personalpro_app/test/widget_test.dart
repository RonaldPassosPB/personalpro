import 'package:flutter_test/flutter_test.dart';
import 'package:personalpro_app/main.dart';

void main() {
  testWidgets('PersonalProApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PersonalProApp());
    expect(find.byType(PersonalProApp), findsOneWidget);
  });
}
