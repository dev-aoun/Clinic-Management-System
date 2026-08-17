import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('Clinic Management app loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ClinicManagementApp(initialThemeMode: ThemeMode.system),
    );

    expect(find.text('Clinic Management'), findsOneWidget);
    expect(find.text('SIGN IN'), findsOneWidget);
  });
}
