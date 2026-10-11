import 'package:flutter/material.dart';
import 'data.dart';

const _warna = [
  Color(0xFFE63946), Color(0xFF2A9D8F), Color(0xFF6A4C93), Color(0xFFF4A261),
  Color(0xFF264653), Color(0xFF3A86FF), Color(0xFFB5179E), Color(0xFF588157),
];

void snack(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

class Cover extends StatelessWidget {
  final Book b;
  final bool small;
  const Cover(this.b, {super.key, this.small = false});
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(small ? 4 : 8),
        alignment: Alignment.bottomLeft,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [_warna[b.id % 8], Colors.black87]),
        ),
        child: Text(b.judul,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: small ? 8 : 12)),
      );
}

/// Kartu peminjaman. Tombol aksi (mis. "Kembalikan") responsif:
/// layar lebar -> di kanan; layar sempit -> di bawah, selebar kartu.
class LoanTile extends StatelessWidget {
  final Loan loan;
  final Widget? action;
  final bool showMember;
  const LoanTile(this.loan, {super.key, this.action, this.showMember = false});

  @override
  Widget build(BuildContext context) {
    final b = store.book(loan.bookId);
    final d = store.denda(loan);
    final info = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(b.judul, style: const TextStyle(fontWeight: FontWeight.bold)),
      if (showMember) Text(store.member(loan.memberId).nama),
      Text(
        loan.kembali != null
            ? 'Kembali ${tgl(loan.kembali!)}'
            : loan.jatuhTempo != null ? 'Jatuh tempo ${tgl(loan.jatuhTempo!)}' : 'Diajukan ${tgl(loan.tgl)}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 4),
      Wrap(spacing: 6, children: [
        Chip(label: Text(loan.status), visualDensity: VisualDensity.compact),
        if (d > 0)
          Chip(label: Text('Denda ${rp(d)}'), backgroundColor: Colors.red.shade100, visualDensity: VisualDensity.compact),
      ]),
    ]);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(builder: (c, box) {
          final narrow = box.maxWidth < 420;
          final head = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 52, height: 72, child: Cover(b, small: true)),
            const SizedBox(width: 12),
            Expanded(child: info),
            if (action != null && !narrow) ...[const SizedBox(width: 8), action!],
          ]);
          if (action == null || !narrow) return head;
          return Column(children: [
            head,
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: action!),
          ]);
        }),
      ),
    );
  }
}
