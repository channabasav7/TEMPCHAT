import 'package:flutter_test/flutter_test.dart';
import 'package:viora/screens/landingpage.dart';

void main() {
  testWidgets('App smoke test on LandingPage', (WidgetTester tester) async {
    await tester.pumpWidget(const LandingPage());
    expect(find.text('TempChat'), findsWidgets);
    expect(find.text('Say it.'), findsOneWidget);
    expect(find.text('Then let it go.'), findsOneWidget);
  });

  testWidgets('Navigate to UsernameSetupScreen on Get a username tap',
      (WidgetTester tester) async {
    await tester.pumpWidget(const LandingPage());

    final usernameBtn = find.text('Get a username');
    expect(usernameBtn, findsOneWidget);

    await tester.tap(usernameBtn);
    await tester.pumpAndSettle();

    expect(find.text('Pick your alias.'), findsOneWidget);
    expect(find.text('Start Private Session'), findsOneWidget);
  });
}
