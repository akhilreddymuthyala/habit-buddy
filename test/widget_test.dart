// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_buddy/widgets/progress_ring.dart';

void main() {
  testWidgets('ProgressRing renders its child label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ProgressRing(progress: 0.5, child: Text('50%')),
          ),
        ),
      ),
    );
    expect(find.text('50%'), findsOneWidget);
  });
}