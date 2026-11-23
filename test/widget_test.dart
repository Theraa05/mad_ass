import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_ass/main.dart';
import 'package:mad_ass/services/auth_service.dart';

void main() {
  tearDown(AuthService.signOut);

  testWidgets('App opens the shared sign-in screen', (tester) async {
    await tester.pumpWidget(const MyRepairApp());

    expect(find.text('Sign in to MYREPAIR'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Management demo account opens Incoming Requests', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyRepairApp());

    await tester.ensureVisible(find.text('management@tarc.edu.my'));
    await tester.tap(find.text('management@tarc.edu.my'));
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Incoming Requests'), findsOneWidget);
    expect(AuthService.current?.role, UserRole.management);
    expect(tester.takeException(), isNull);
  });
}
