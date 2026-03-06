import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seasons/core/navigation/corporate_page_transition.dart';

void main() {
  test('shouldTriggerBackSwipePop respects trigger distance', () {
    expect(shouldTriggerBackSwipePop(71), isFalse);
    expect(shouldTriggerBackSwipePop(72), isTrue);
    expect(shouldTriggerBackSwipePop(120), isTrue);
  });

  testWidgets('left-edge swipe pops corporate route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      buildCorporatePageRoute(
                        const Scaffold(body: Center(child: Text('Details'))),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsOneWidget);

    final gesture = await tester.startGesture(const Offset(2, 300));
    await gesture.moveBy(const Offset(120, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Details'), findsNothing);
  });

  testWidgets('short left-edge swipe does not pop corporate route', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      buildCorporatePageRoute(
                        const Scaffold(body: Center(child: Text('Details'))),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsOneWidget);

    final gesture = await tester.startGesture(const Offset(2, 300));
    await gesture.moveBy(const Offset(30, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Details'), findsOneWidget);
  });
}
