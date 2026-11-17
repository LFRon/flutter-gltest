import 'package:flutter/widgets.dart';
import 'package:flutter_gltest/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the graphics test and stops its ticker', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GlTestApp());
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.textContaining('frames:'), findsOneWidget);
    expect(find.textContaining('fps:'), findsOneWidget);
    expect(find.textContaining('display:'), findsOneWidget);

    // Unmount the app so the ticker and timings callback are released.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
