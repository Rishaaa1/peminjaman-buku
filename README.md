# PustakaKu (Flutter)

Aplikasi peminjaman buku perpustakaan. Dua dashboard terpisah: Petugas dan Anggota.

## Cara menjalankan
1. Masuk ke folder proyek ini, lalu jalankan:
   flutter create . --project-name pustakaku
   (membuat folder android/ios/web; file di lib/ tidak diubah. Hapus test/widget_test.dart jika muncul error.)
2. flutter pub get
3. flutter run

Data masih disimpan di memori (hilang saat aplikasi ditutup) dan login belum memakai password.
Kode data ada di lib/data.dart, mudah diganti ke API/database.
