import 'package:flutter_test/flutter_test.dart';
import 'package:money_management/main.dart';
import 'package:provider/provider.dart';
import 'package:money_management/providers/app_provider.dart';

void main() {
  testWidgets('App launches without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const MoneyManagerApp(),
      ),
    );
    expect(find.byType(MoneyManagerApp), findsOneWidget);
  });
}
