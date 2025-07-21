import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/main.dart';

void main() {
  testWidgets('Приложение строится без ошибок', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);
  });
}
