import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/main.dart';

void main() {
  testWidgets('shows encrypted database spike shell', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Encrypted Database Spike'), findsOneWidget);
  });
}
