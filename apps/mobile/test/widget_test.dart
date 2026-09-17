import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paridhan_mobile/main_consumer.dart';
import 'package:paridhan_mobile/core/routing/app_router.dart';
import 'package:paridhan_mobile/core/constants/app_constants.dart';
import 'test_utils.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  testWidgets('Renders Guest Consumer Home and Navigation to Login', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appFlavorProvider.overrideWith(() => FlavorNotifier(AppFlavor.consumer)),
        ],
        child: const ParidhanApp(flavorTitle: 'Paridhan Test'),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Guest Consumer Discovery elements
    expect(find.textContaining('Jaipur'), findsWidgets);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Shop by Category'), findsOneWidget);
    expect(find.text('Women Ethnic'), findsOneWidget);

    // Tap on Sign In
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Login Screen is displayed
    expect(find.text('Welcome to Paridhan'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
  });
}
