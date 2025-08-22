// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resource_allocator_app/main.dart';

void main() {
  testWidgets('Resource Allocator App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ResourceAllocatorApp());

    // Verify that the app loads with the login screen
    expect(find.text('Resource Allocator'), findsOneWidget);
    expect(find.text('Welcome back!'), findsOneWidget);

    // Verify that login form elements are present
    expect(find.byType(TextFormField), findsWidgets);
    expect(find.text('Login'), findsWidgets);
  });
}
