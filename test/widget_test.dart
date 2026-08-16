import 'package:flutter_test/flutter_test.dart';
import 'package:networthy/main.dart';

void main() {
  testWidgets('shows bootstrap loading shell', (tester) async {
    await tester.pumpWidget(const NetworthyBootstrapApp());

    expect(find.text('載入中'), findsOneWidget);
  });
}
