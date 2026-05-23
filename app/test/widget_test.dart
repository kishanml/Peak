// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:peak/pages/profile_setup_screen.dart';

void main() {
  testWidgets('profile setup renders required fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileSetupScreen()));

    expect(find.text('Create Profile'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Age'), findsOneWidget);
    expect(find.text('Weight'), findsOneWidget);
  });
}
