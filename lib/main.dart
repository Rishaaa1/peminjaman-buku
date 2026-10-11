import 'package:flutter/material.dart';
import 'data.dart';
import 'anggota.dart';
import 'petugas.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'PustakaKu',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6122)),
        ),
        home: const LoginPage(),
      );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  int memberId = 1;

  @override
  Widget build(BuildContext context) {
    final o = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('PustakaKu', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: o)),
              const SizedBox(height: 4),
              const Text('Perpustakaan di genggamanmu', textAlign: TextAlign.center),
              const SizedBox(height: 32),
              DropdownButtonFormField<int>(
                value: memberId,
                decoration: const InputDecoration(labelText: 'Anggota', border: OutlineInputBorder()),
                items: [for (final m in store.members) DropdownMenuItem(value: m.id, child: Text('${m.nama} (${m.kelas})'))],
                onChanged: (v) => setState(() => memberId = v ?? memberId),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => AnggotaPage(memberId: memberId))),
                child: const Text('Masuk sebagai Anggota'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PetugasPage())),
                child: const Text('Masuk sebagai Petugas'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
