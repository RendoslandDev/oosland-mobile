import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osland/app.dart';
import 'package:osland/shared/repositories/app_repository.dart';

void main() {
  testWidgets('osland app loads dashboard shell', (tester) async {
    final container = ProviderContainer();
    await container.read(appRepositoryProvider).initialize();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const OslandApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('osland.'), findsOneWidget);
  });
}
