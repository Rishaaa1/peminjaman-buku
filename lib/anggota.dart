import 'package:flutter/material.dart';
import 'data.dart';
import 'widgets.dart';

/// Dashboard Anggota (Siswa): katalog, pengajuan/pemesanan, pengingat & riwayat.
class AnggotaPage extends StatefulWidget {
  final int memberId;
  const AnggotaPage({super.key, required this.memberId});
  @override
  State<AnggotaPage> createState() => _AnggotaPageState();
}

class _AnggotaPageState extends State<AnggotaPage> {
  int tab = 0;
  String q = '', cat = 'Semua';

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: store,
        builder: (c, _) => Scaffold(
          appBar: AppBar(
            title: Text('Halo, ${store.member(widget.memberId).nama}'),
            actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pop(context))],
          ),
          body: tab == 0 ? _katalog() : _pinjaman(),
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (i) => setState(() => tab = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Jelajah'),
              NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Pinjaman Saya'),
            ],
          ),
        ),
      );

  Widget _katalog() {
    final cats = ['Semua', ...{...store.books.map((b) => b.kategori)}];
    final list = store.books
        .where((b) => (cat == 'Semua' || b.kategori == cat) && '${b.judul} ${b.pengarang}'.toLowerCase().contains(q.toLowerCase()))
        .toList();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Cari judul atau pengarang',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))),
          onChanged: (v) => setState(() => q = v),
        ),
      ),
      SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            for (final k in cats)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(label: Text(k), selected: cat == k, onSelected: (_) => setState(() => cat = k)),
              ),
          ],
        ),
      ),
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 150, childAspectRatio: 0.55, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: list.length,
          itemBuilder: (c, i) {
            final b = list[i];
            return InkWell(
              onTap: () => _detail(b),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: SizedBox(width: double.infinity, child: Cover(b))),
                const SizedBox(height: 6),
                Text(b.judul, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(b.stok > 0 ? 'Stok ${b.stok}' : 'Habis',
                    style: TextStyle(fontSize: 12, color: b.stok > 0 ? Colors.teal : Colors.red)),
              ]),
            );
          },
        ),
      ),
    ]);
  }

  void _detail(Book b) => showModalBottomSheet(
        context: context,
        builder: (c) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(b.judul, textAlign: TextAlign.center, style: Theme.of(c).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text('${b.pengarang} · ${b.penerbit}\n${b.kategori} · Rak ${b.rak} · Stok ${b.stok}', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final err = store.ajukan(b.id, widget.memberId);
                Navigator.pop(c);
                snack(context, err ?? (b.stok > 0 ? 'Pengajuan terkirim ke petugas.' : 'Buku dipesan.'));
              },
              child: Text(b.stok > 0 ? 'Ajukan Peminjaman' : 'Pesan Buku'),
            ),
          ]),
        ),
      );

  Widget _pinjaman() {
    final mine = store.loans.where((l) => l.memberId == widget.memberId).toList()..sort((a, b) => b.tgl.compareTo(a.tgl));
    final reminders = <Widget>[];
    for (final l in mine.where((l) => l.status == 'dipinjam')) {
      final sisa = l.jatuhTempo!.difference(today()).inDays;
      final judul = store.book(l.bookId).judul;
      if (sisa < 0) {
        reminders.add(_alert('$judul terlambat ${-sisa} hari. Denda ${rp(store.denda(l))}.', Colors.red));
      } else if (sisa <= 2) {
        reminders.add(_alert('$judul harus dikembalikan ${sisa == 0 ? 'hari ini' : '$sisa hari lagi'}.', Colors.orange));
      }
    }
    final aktif = mine.where((l) => l.aktif), riwayat = mine.where((l) => !l.aktif);
    return ListView(padding: const EdgeInsets.all(12), children: [
      ...reminders,
      const Text('Sedang Berjalan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      if (aktif.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('Belum ada.')),
      for (final l in aktif) LoanTile(l),
      const SizedBox(height: 8),
      const Text('Riwayat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      if (riwayat.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('Belum ada riwayat.')),
      for (final l in riwayat) LoanTile(l),
    ]);
  }

  Widget _alert(String t, Color c) => Card(
        color: c.withOpacity(.12),
        child: ListTile(leading: Icon(Icons.notifications_active, color: c), title: Text(t)),
      );
}
