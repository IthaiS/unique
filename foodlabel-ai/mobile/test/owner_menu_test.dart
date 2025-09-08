
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/src/app_shell.dart';

void main() {
  testWidgets('Owner menu shows all entries and logout works', (tester) async {
    await tester.pumpWidget(MaterialApp(
      routes: {
        '/owner/profile': (_) => const Scaffold(body: Text('Owner profile page')),
        '/owner/settings': (_) => const Scaffold(body: Text('Owner settings page')),
        '/login': (_) => const Scaffold(body: Text('Login page')),
      },
      home: MediaQuery(
        data: const MediaQueryData(size: Size(1200, 800)),
        child: const AppShell(isOwner: true, onLocaleChange: _noop, translations: {},),
      ),
    ));

    final adminIcon = find.byTooltip('Owner menu');
    expect(adminIcon, findsOneWidget);
    await tester.tap(adminIcon);
    await tester.pumpAndSettle();

    expect(find.text('Owner profile'), findsOneWidget);
    expect(find.text('Owner settings'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Moderation'), findsOneWidget);
    expect(find.text('Backend health'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Login page'), findsOneWidget);
  });
}

void _noop(Locale _) {}
