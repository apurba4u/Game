import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamehub/core/common_widgets/glass_container.dart';
import 'package:gamehub/core/common_widgets/cyber_button.dart';

void main() {
  testWidgets('System compilation smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GlassContainer(
              child: CyberButton(
                text: 'SYSTEM ONLINE',
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(CyberButton), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
