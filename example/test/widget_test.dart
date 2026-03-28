import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventiv_critic_flutter_example/main.dart';

void main() {
  testWidgets('CriticExampleApp renders the main UI elements', (tester) async {
    await tester.pumpWidget(const CriticExampleApp());

    // App bar title
    expect(find.text('Critic Example'), findsOneWidget);

    // Bug report form heading
    expect(find.text('Submit a Bug Report'), findsOneWidget);

    // Text fields
    expect(find.widgetWithText(TextField, 'Description'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Steps to Reproduce'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextField, 'User Identifier (optional)'),
      findsOneWidget,
    );

    // Submit buttons
    expect(find.text('Submit Report'), findsOneWidget);
    expect(find.text('Submit with Attachment'), findsOneWidget);

    // API configuration line
    expect(find.textContaining('API:'), findsOneWidget);
  });
}
