import 'package:flutter/material.dart';

const dendaPerHari = 1000;
const masaPinjamHari = 7;

DateTime today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

String rp(int n) =>
    'Rp${n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
String tgl(DateTime d) => '${d.day}/${d.month}/${d.year}';

class Book {
  int id, stok;
  String judul, pengarang, penerbit, kategori, rak;
  Book(this.id, this.judul, this.pengarang, this.penerbit, this.kategori, this.rak, this.stok);
}

class Member {
  int id;
  String nama, kelas;
  Member(this.id, this.nama, this.kelas);
}

class Loan {
  int id, bookId, memberId;
  String status; // diajukan, dipesan, dipinjam, kembali
  DateTime tgl;
  DateTime? jatuhTempo, kembali;
  Loan({required this.id, required this.bookId, required this.memberId, required this.status,
      required this.tgl, this.jatuhTempo, this.kembali});
  bool get aktif => status != 'kembali';
}

class Store extends ChangeNotifier {
  int _n = 100;
  final books = <Book>[
    Book(1, 'Laskar Pelangi', 'Andrea Hirata', 'Bentang', 'Novel', 'A1', 3),
    Book(2, 'Bumi', 'Tere Liye', 'Gramedia', 'Fantasi', 'A2', 2),
    Book(3, 'Dilan 1990', 'Pidi Baiq', 'Pastel Books', 'Romansa', 'B1', 0),
    Book(4, 'Atomic Habits', 'James Clear', 'Gramedia', 'Pengembangan Diri', 'C1', 4),
    Book(5, 'Sapiens', 'Yuval N. Harari', 'KPG', 'Sejarah', 'D2', 1),
    Book(6, 'Negeri 5 Menara', 'A. Fuadi', 'Gramedia', 'Novel', 'A3', 2),
    Book(7, 'Filosofi Teras', 'Henry Manampiring', 'Kompas', 'Pengembangan Diri', 'C2', 3),
  ];
  final members = <Member>[
    Member(1, 'Budi Santoso', 'XI RPL 1'),
    Member(2, 'Siti Aisyah', 'X TKJ 2'),
    Member(3, 'Raka Pratama', 'XII MM'),
  ];
  late final List<Loan> loans = _seed();

  List<Loan> _seed() {
    final t = today();
    DateTime h(int n) => t.add(Duration(days: n));
    return [
      Loan(id: 1, bookId: 1, memberId: 1, status: 'dipinjam', tgl: h(-10), jatuhTempo: h(-3)),
      Loan(id: 2, bookId: 4, memberId: 1, status: 'kembali', tgl: h(-30), jatuhTempo: h(-23), kembali: h(-24)),
      Loan(id: 3, bookId: 1, memberId: 2, status: 'kembali', tgl: h(-20), jatuhTempo: h(-13), kembali: h(-13)),
      Loan(id: 4, bookId: 2, memberId: 3, status: 'dipinjam', tgl: h(-2), jatuhTempo: h(5)),
      Loan(id: 5, bookId: 1, memberId: 3, status: 'kembali', tgl: h(-40), jatuhTempo: h(-33), kembali: h(-34)),
      Loan(id: 6, bookId: 7, memberId: 2, status: 'diajukan', tgl: t),
    ];
  }

  Book book(int id) => books.firstWhere((b) => b.id == id,
      orElse: () => Book(0, '(buku dihapus)', '-', '-', '-', '-', 0));
  Member member(int id) => members.firstWhere((m) => m.id == id,
      orElse: () => Member(0, '(anggota dihapus)', '-'));

  int denda(Loan l) {
    if (l.jatuhTempo == null || !(l.status == 'dipinjam' || l.status == 'kembali')) return 0;
    final d = (l.kembali ?? today()).difference(l.jatuhTempo!).inDays;
    return d > 0 ? d * dendaPerHari : 0;
  }

  void saveBook(Book? b, String judul, String pengarang, String penerbit, String kategori, String rak, int stok) {
    if (b == null) {
      books.add(Book(_n++, judul, pengarang, penerbit, kategori, rak, stok));
    } else {
      b..judul = judul..pengarang = pengarang..penerbit = penerbit..kategori = kategori..rak = rak..stok = stok;
    }
    notifyListeners();
  }

  String? deleteBook(Book b) {
    if (loans.any((l) => l.bookId == b.id && l.aktif)) return 'Buku masih dipinjam/diajukan.';
    books.remove(b);
    notifyListeners();
    return null;
  }

  void addMember(String nama, String kelas) {
    members.add(Member(_n++, nama, kelas));
    notifyListeners();
  }

  String? deleteMember(Member m) {
    if (loans.any((l) => l.memberId == m.id && l.aktif)) return 'Anggota masih punya pinjaman aktif.';
    members.remove(m);
    notifyListeners();
    return null;
  }

  String? ajukan(int bookId, int memberId) {
    if (loans.any((l) => l.bookId == bookId && l.memberId == memberId && l.aktif)) {
      return 'Kamu sudah mengajukan/meminjam buku ini.';
    }
    loans.add(Loan(id: _n++, bookId: bookId, memberId: memberId,
        status: book(bookId).stok > 0 ? 'diajukan' : 'dipesan', tgl: today()));
    notifyListeners();
    return null;
  }

  String? setujui(Loan l) {
    final b = book(l.bookId);
    if (b.stok <= 0) return 'Stok habis, belum bisa disetujui.';
    b.stok--;
    l..status = 'dipinjam'..tgl = today()..jatuhTempo = today().add(const Duration(days: masaPinjamHari));
    notifyListeners();
    return null;
  }

  int kembalikan(Loan l) {
    l..kembali = today()..status = 'kembali';
    book(l.bookId).stok++;
    notifyListeners();
    return denda(l);
  }

  List<MapEntry<Book, int>> terfavorit() {
    final c = <int, int>{};
    for (final l in loans.where((l) => l.status == 'dipinjam' || l.status == 'kembali')) {
      c[l.bookId] = (c[l.bookId] ?? 0) + 1;
    }
    final e = c.entries.map((e) => MapEntry(book(e.key), e.value)).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return e.take(5).toList();
  }
}

final store = Store();
