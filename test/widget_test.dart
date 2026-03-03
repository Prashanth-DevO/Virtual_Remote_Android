import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/main.dart';

void main() {
  testWidgets('renders discovery screen', (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('Find Servers'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
  });
}
