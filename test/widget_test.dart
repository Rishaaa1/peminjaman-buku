import 'package:flutter_test/flutter_test.dart';
import 'package:peminjaman_buku/main.dart';

void main() {
  testWidgets('Halaman login tampil', (tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('PustakaKu'), findsOneWidget);
  });
}
