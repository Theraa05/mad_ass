import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_ass/models/report.dart';
import 'package:mad_ass/routes.dart';
import 'package:mad_ass/services/auth_service.dart';
import 'package:mad_ass/services/report_store.dart';
import 'package:mad_ass/theme/app_theme.dart';

Finder request(String id) => find.byKey(ValueKey('request-$id'));

Future<void> pumpQueue(
  WidgetTester tester, {
  Size size = const Size(1000, 3000),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  AuthService.signIn('management@tarc.edu.my');
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      initialRoute: AppRoutes.management,
      routes: AppRoutes.table,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> showAll(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('status-all')));
  await tester.pumpAndSettle();
}

void expectOrder(WidgetTester tester, List<String> ids) {
  for (var i = 0; i < ids.length - 1; i++) {
    expect(
      tester.getTopLeft(request(ids[i])).dy,
      lessThan(tester.getTopLeft(request(ids[i + 1])).dy),
    );
  }
}

void main() {
  tearDown(AuthService.signOut);

  testWidgets('Starts with new requests and offers all existing statuses', (
    tester,
  ) async {
    await pumpQueue(tester);

    expect(find.text('Incoming Requests'), findsOneWidget);
    expect(find.text('New (1)'), findsOneWidget);
    expect(find.text('Needs information (1)'), findsOneWidget);
    expect(request('RPT-005'), findsOneWidget);
    expect(request('RPT-001'), findsNothing);

    await showAll(tester);
    for (var i = 1; i <= 5; i++) {
      expect(request('RPT-${i.toString().padLeft(3, '0')}'), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Search matches location, equipment and reporter without case', (
    tester,
  ) async {
    await pumpQueue(tester);
    await showAll(tester);
    final search = find.byKey(const ValueKey('incoming-search'));

    for (final query in [
      '  BLOCK c 305  ',
      'socket-c305-04',
      'AMIR@student.tarc.edu.my',
    ]) {
      await tester.enterText(search, query);
      await tester.pumpAndSettle();
      expect(request('RPT-002'), findsOneWidget);
      expect(request('RPT-001'), findsNothing);
      expect(find.text('1 request'), findsOneWidget);
    }
  });

  testWidgets('Category and status combine, and empty results can be cleared', (
    tester,
  ) async {
    await pumpQueue(tester);
    await showAll(tester);
    await tester.tap(find.byKey(const ValueKey('incoming-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Electrical').last);
    await tester.pumpAndSettle();

    expect(request('RPT-002'), findsOneWidget);
    expect(request('RPT-005'), findsNothing);
    expect(find.text('All (1)'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('status-submitted')));
    await tester.pumpAndSettle();
    expect(find.text('No matching requests'), findsOneWidget);
    expect(find.text('0 requests'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('incoming-clear-filters')));
    await tester.pumpAndSettle();
    expect(find.text('All (5)'), findsOneWidget);
    expect(request('RPT-002'), findsOneWidget);
    expect(request('RPT-005'), findsOneWidget);
  });

  testWidgets('FIFO, newest and reported urgency preserve chronological ties', (
    tester,
  ) async {
    await pumpQueue(tester);
    await showAll(tester);
    expectOrder(tester, [
      'RPT-004',
      'RPT-001',
      'RPT-002',
      'RPT-003',
      'RPT-005',
    ]);

    await tester.tap(find.byKey(const ValueKey('incoming-order')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Newest first').last);
    await tester.pumpAndSettle();
    expectOrder(tester, [
      'RPT-005',
      'RPT-003',
      'RPT-002',
      'RPT-001',
      'RPT-004',
    ]);

    await tester.tap(find.byKey(const ValueKey('incoming-order')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reporter urgency first').last);
    await tester.pumpAndSettle();
    expectOrder(tester, [
      'RPT-002',
      'RPT-005',
      'RPT-001',
      'RPT-003',
      'RPT-004',
    ]);
    expect(
      find.textContaining('Confirm the repair priority during review'),
      findsOneWidget,
    );
  });

  testWidgets('Tapping a request opens the existing details route', (
    tester,
  ) async {
    await pumpQueue(tester);
    await tester.tap(request('RPT-005'));
    await tester.pumpAndSettle();

    expect(find.text('RPT-005'), findsOneWidget);
    expect(
      find.text('Wi-Fi drops every few minutes in the lab.'),
      findsOneWidget,
    );
    expect(find.text('Update status'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Incoming Requests'), findsOneWidget);
    expect(request('RPT-005'), findsOneWidget);
  });

  testWidgets('Shared store changes immediately refresh the queue and counts', (
    tester,
  ) async {
    final store = ReportStore.instance;
    final report = store.byId('RPT-005')!;
    final previousStatus = report.status;
    final previousUpdate = report.updatedAt;
    addTearDown(() {
      store.updateStatus(report.id, previousStatus);
      report.updatedAt = previousUpdate;
    });
    await pumpQueue(tester);
    expect(request(report.id), findsOneWidget);

    store.updateStatus(report.id, ReportStatus.needsInfo);
    await tester.pumpAndSettle();
    expect(request(report.id), findsNothing);
    expect(find.text('New (0)'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('status-needsInfo')));
    await tester.pumpAndSettle();
    expect(request(report.id), findsOneWidget);
    expect(request('RPT-001'), findsOneWidget);
    expect(find.text('Needs information (2)'), findsOneWidget);
  });

  testWidgets('Narrow screens and large text remain usable', (tester) async {
    await pumpQueue(tester, size: const Size(320, 1600), textScale: 2);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('incoming-search')), findsOneWidget);
  });

  testWidgets('Sign out returns to the shared sign-in screen', (tester) async {
    await pumpQueue(tester);
    await tester.tap(find.byTooltip('Sign out'));
    await tester.pumpAndSettle();

    expect(AuthService.current, isNull);
    expect(find.text('Sign in to MYREPAIR'), findsOneWidget);
    expect(find.text('Incoming Requests'), findsNothing);
  });
}
