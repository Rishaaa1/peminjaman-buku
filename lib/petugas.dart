import 'package:flutter/material.dart';
import 'data.dart';
import 'widgets.dart';

/// Dashboard Petugas: beranda/laporan, kelola buku, kelola anggota, sirkulasi.
class PetugasPage extends StatefulWidget {
  const PetugasPage({super.key});
  @override
  State<PetugasPage> createState() => _PetugasPageState();
}

class _PetugasPageState extends State<PetugasPage> {
  int tab = 0;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: store,
        builder: (c, _) => Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard Petugas'),
            actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pop(context))],
          ),
          body: [_beranda, _buku, _anggota, _sirkulasi][tab](),
          floatingActionButton: tab == 1
              ? FloatingActionButton(onPressed: () => _bukuDialog(), child: const Icon(Icons.add))
              : tab == 2
                  ? FloatingActionButton(onPressed: _anggotaDialog, child: const Icon(Icons.person_add))
                  : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (i) => setState(() => tab = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Beranda'),
              NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Buku'),
              NavigationDestination(icon: Icon(Icons.people_outline), label: 'Anggota'),
              NavigationDestination(icon: Icon(Icons.swap_horiz), label: 'Sirkulasi'),
            ],
          ),
        ),
      );

  Widget _beranda() {
    final done = store.loans.where((l) => l.status == 'dipinjam' || l.status == 'kembali');
    final stat = [
      ['Total peminjaman', '${done.length}'],
      ['Sedang dipinjam', '${store.loans.where((l) => l.status == 'dipinjam').length}'],
      ['Terlambat', '${store.loans.where((l) => l.status == 'dipinjam' && l.jatuhTempo!.isBefore(today())).length}'],
      ['Total denda', rp(store.loans.fold(0, (s, l) => s + store.denda(l)))],
    ];
    final top = store.terfavorit();
    final mx = top.isEmpty ? 1 : top.first.value;
    return ListView(padding: const EdgeInsets.all(12), children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final s in stat)
          SizedBox(
            width: 155,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s[1], style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  Text(s[0]),
                ]),
              ),
            ),
          ),
      ]),
      const Padding(padding: EdgeInsets.only(top: 16, bottom: 8), child: Text('Buku Terfavorit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
      for (final e in top)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${e.key.judul} · ${e.value}x'),
            LinearProgressIndicator(value: e.value / mx, minHeight: 8, borderRadius: BorderRadius.circular(4)),
          ]),
        ),
    ]);
  }

  Widget _buku() => ListView(padding: const EdgeInsets.only(bottom: 80), children: [
        for (final b in store.books)
          ListTile(
            leading: SizedBox(width: 40, height: 56, child: Cover(b, small: true)),
            title: Text(b.judul),
            subtitle: Text('${b.pengarang} · ${b.penerbit}\n${b.kategori} · Rak ${b.rak} · Stok ${b.stok}'),
            isThreeLine: true,
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit), onPressed: () => _bukuDialog(b)),
              IconButton(icon: const Icon(Icons.delete_outline), onPressed: () {
                final err = store.deleteBook(b);
                if (err != null) snack(context, err);
              }),
            ]),
          ),
      ]);

  Widget _anggota() => ListView(padding: const EdgeInsets.only(bottom: 80), children: [
        for (final m in store.members)
          ListTile(
            leading: CircleAvatar(child: Text(m.nama[0])),
            title: Text(m.nama),
            subtitle: Text('${m.kelas} · ${store.loans.where((l) => l.memberId == m.id && l.status == 'dipinjam').length} pinjaman aktif'),
            trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () {
              final err = store.deleteMember(m);
              if (err != null) snack(context, err);
            }),
          ),
      ]);

  Widget _sirkulasi() {
    final req = store.loans.where((l) => l.status == 'diajukan' || l.status == 'dipesan');
    final pinjam = store.loans.where((l) => l.status == 'dipinjam');
    const h = TextStyle(fontWeight: FontWeight.bold, fontSize: 16);
    return ListView(padding: const EdgeInsets.all(12), children: [
      const Text('Pengajuan & Pemesanan', style: h),
      if (req.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('Tidak ada pengajuan.')),
      for (final l in req)
        LoanTile(l, showMember: true,
            action: FilledButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Setujui'),
              onPressed: () {
                final err = store.setujui(l);
                if (err != null) snack(context, err);
              },
            )),
      const SizedBox(height: 8),
      const Text('Sedang Dipinjam', style: h),
      if (pinjam.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('Tidak ada.')),
      for (final l in pinjam)
        LoanTile(l, showMember: true,
            action: FilledButton.icon(
              icon: const Icon(Icons.assignment_return),
              label: const Text('Kembalikan'),
              onPressed: () {
                final d = store.kembalikan(l);
                snack(context, d > 0 ? 'Dikembalikan. Denda ${rp(d)}' : 'Buku dikembalikan.');
              },
            )),
      const Padding(padding: EdgeInsets.all(8), child: Text('Denda Rp1.000/hari, masa pinjam 7 hari.', style: TextStyle(fontSize: 12))),
    ]);
  }

  void _bukuDialog([Book? b]) {
    final f = [b?.judul, b?.pengarang, b?.penerbit, b?.kategori, b?.rak, b?.stok.toString()]
        .map((e) => TextEditingController(text: e ?? '')).toList();
    const lb = ['Judul', 'Pengarang', 'Penerbit', 'Kategori', 'Rak', 'Stok'];
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(b == null ? 'Tambah Buku' : 'Ubah Buku'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < 6; i++)
              TextField(controller: f[i], keyboardType: i == 5 ? TextInputType.number : null, decoration: InputDecoration(labelText: lb[i])),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              final v = f.map((e) => e.text.trim()).toList();
              if (v.sublist(0, 5).any((e) => e.isEmpty)) return;
              store.saveBook(b, v[0], v[1], v[2], v[3], v[4], int.tryParse(v[5]) ?? 0);
              Navigator.pop(d);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _anggotaDialog() {
    final n = TextEditingController(), k = TextEditingController();
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Tambah Anggota'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: n, decoration: const InputDecoration(labelText: 'Nama siswa')),
          TextField(controller: k, decoration: const InputDecoration(labelText: 'Kelas')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (n.text.trim().isEmpty) return;
              store.addMember(n.text.trim(), k.text.trim());
              Navigator.pop(d);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
