# PRD Aplikasi Tagihan Kos

13 Okt 2026

MVP aplikasi tagihan otomatis untuk pemilik kos: tagihan bulanan dengan link bayar QRIS/VA, status lunas otomatis, dan pengingat WhatsApp.

## Masalah dan tujuan

Pemilik kos menagih sewa manual lewat WhatsApp, mengecek mutasi rekening satu per satu, dan sering lupa siapa yang belum bayar. Akibatnya waktu terbuang tiap awal bulan dan pembayaran telat tidak terpantau.

Tujuan MVP:

- Pemilik kos tidak perlu lagi cek mutasi: status lunas berubah otomatis dari notifikasi payment gateway.
- Membuat tagihan satu bulan untuk semua kamar butuh kurang dari 5 menit.
- 10 pemilik kos aktif memakai MVP dan minimal 5 lanjut setelah masa gratis.

## Pengguna

Ada dua pengguna: pemilik kos yang membayar atau mendaftar, dan penghuni yang hanya menerima tagihan.

| Pengguna | Siapa | Butuh | Cara pakai |
|---|---|---|---|
| Pemilik kos | Punya 5–100 kamar, kadang beberapa rumah kos; tidak teknis | Tahu siapa yang belum bayar tanpa cek mutasi; menagih tanpa sungkan | Web app di HP, login dengan nomor WA atau email |
| Penghuni | Mahasiswa atau pekerja | Bayar cepat dengan metode yang biasa dipakai; bukti bayar | Tanpa akun: buka link tagihan dari WA, bayar, lihat kuitansi |

User story utama:

- Sebagai pemilik kos, saya ingin tagihan bulanan terbuat otomatis supaya tidak perlu menghitung ulang tiap bulan.
- Sebagai pemilik kos, saya ingin melihat dalam satu layar siapa yang sudah dan belum bayar bulan ini.
- Sebagai pemilik kos, saya ingin mengirim tagihan dan pengingat ke WA penghuni dengan satu tap per orang.
- Sebagai penghuni, saya ingin bayar lewat QRIS atau VA tanpa harus transfer manual dan kirim bukti.

## Alur tagihan

Pemilik kos hanya terlibat saat menekan kirim; pembuatan tagihan dan perubahan status lunas berjalan otomatis. Penghuni yang lewat jatuh tempo masuk daftar pengingat.

## Fitur MVP

P0 wajib ada saat rilis pertama; P1 dikerjakan kalau P0 selesai sebelum target.

| Prioritas | Fitur | Kriteria terima |
|---|---|---|
| P0 | Daftar & login pemilik kos | Daftar dengan nomor WA atau email; data satu pemilik tidak terlihat pemilik lain |
| P0 | Properti & kamar | Tambah properti, kamar, harga sewa per kamar |
| P0 | Data penghuni | Nama, nomor WA, kamar, tanggal masuk, tanggal jatuh tempo; tandai keluar tanpa menghapus riwayat |
| P0 | Tagihan bulanan otomatis | Tagihan terbuat otomatis H-3 sebelum jatuh tempo; satu tagihan per penghuni per periode, tidak dobel |
| P0 | Link bayar QRIS/VA | Tiap tagihan punya link bayar unik dari payment gateway; nominal sesuai tagihan |
| P0 | Status lunas otomatis | Webhook payment gateway mengubah status jadi Lunas dalam hitungan detik; webhook diverifikasi dan tidak diproses dua kali |
| P0 | Kirim tagihan via WA (klik kirim) | Satu halaman berisi tombol per penghuni yang membuka WA dengan pesan + link terisi |
| P0 | Dashboard bulan ini | Jumlah lunas / belum / telat, total diterima, daftar belum bayar di urutan teratas |
| P0 | Kuitansi digital | Halaman kuitansi bisa dibuka penghuni lewat link setelah bayar |
| P1 | Pengingat telat | Daftar penghuni yang lewat jatuh tempo, siap dikirimi pengingat via klik kirim |
| P1 | Tagihan tambahan | Tambah item sekali bayar (listrik, air, laundry) ke tagihan bulan itu |
| P1 | Catat bayar tunai | Pemilik bisa menandai lunas manual untuk pembayaran di luar aplikasi |
| P1 | Ekspor laporan | Unduh rekap pembayaran per bulan dalam CSV |

## Di luar cakupan MVP

- WhatsApp API otomatis (paket Otomatis menyusul setelah ada pelanggan yang minta)
- Denda keterlambatan otomatis
- Aplikasi Android/iOS native; MVP berupa web app yang nyaman di HP
- Portal atau akun penghuni
- Niche lain (bimbel, daycare, gym)
- Laporan pajak dan integrasi akuntansi

## Integrasi

**Payment gateway: Midtrans.** Setiap pemilik kos mendaftar akun Midtrans atas namanya sendiri (perorangan cukup KTP + NPWP), lalu menghubungkannya ke aplikasi kita. Aplikasi membuat transaksi memakai akun mereka, jadi dana sewa masuk langsung ke pemilik kos dan tidak pernah lewat rekening kita. Biaya Midtrans dipotong dari akun pemilik kos: VA Rp4.000 + PPN, QRIS 0,7% (biaya Midtrans). Midtrans tidak mencantumkan fitur sub-akun atau split payment untuk platform di halaman publiknya, jadi penghasilan kita dari langganan.

- Gunakan webhook untuk status lunas; verifikasi tanda tangan dan simpan ID transaksi supaya notifikasi ganda tidak diproses dua kali.
- Biaya admin VA dibebankan ke penghuni; biaya QRIS tidak boleh dibebankan ke penghuni, jadi dipotong dari dana yang diterima pemilik kos.

**WhatsApp.** MVP memakai mode klik kirim: sistem membuat link `wa.me` berisi pesan + link bayar, pemilik kos tap untuk mengirim dari WA-nya sendiri. Biayanya Rp0 dan tanpa risiko blokir. WA API resmi (utility sekitar Rp357 per pesan sejak Oktober 2026) baru dipakai di paket Otomatis.

## Model harga

MVP diluncurkan dengan paket Gratis dan Pro. Biaya admin VA yang dibayar penghuni (misalnya Rp5.000) masuk ke akun Midtrans pemilik kos untuk menutup biaya VA Rp4.000 + PPN; penghasilan kita dari langganan.

| Paket | Pemilik kos bayar | Isi |
|---|---|---|
| Gratis | Rp0 | Maks 10 kamar, semua fitur P0 |
| Pro | Rp29–49 ribu/bulan | Kamar tak terbatas, fitur P1 |
| Otomatis (setelah MVP) | Per kamar | WA API otomatis |

20–50 pelanggan pertama mendapat harga founding member yang dikunci.

## Metrik, risiko, dan pertanyaan terbuka

| Metrik | Target 3 bulan setelah rilis |
|---|---|
| Pemilik kos aktif (minimal 1 tagihan terbayar per bulan) | 10 |
| Pembayaran lewat link bayar dibanding total tagihan | 60% |
| Pemilik kos yang lanjut setelah masa gratis | 5 |

Risiko:

- Penghuni tetap transfer manual ke rekening pribadi; mitigasi: fitur catat bayar tunai dan pesan tagihan yang menonjolkan kemudahan bayar.
- Pemilik kos harus mendaftar dan verifikasi akun Midtrans sendiri, sehingga sebagian bisa batal di tengah jalan; mitigasi: dampingi proses daftar dan bantu menyiapkan dokumen.
- Pemilik kos merasa biaya admin memberatkan penghuni; mitigasi: uji nominal Rp4.000 vs Rp5.000.
