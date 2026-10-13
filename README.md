# Ingetin

Aplikasi tagihan sewa otomatis untuk pemilik kos. Tagihan bulanan dibuat otomatis, penghuni bayar lewat link QRIS/VA Midtrans, status lunas berubah sendiri lewat webhook, dan pengingat dikirim ke WhatsApp dengan sekali tap.

> **Status:** pra-MVP. Repo baru berisi fondasi (dokumen, CI, konvensi). Kode aplikasi menyusul.

## Fitur MVP

| Prioritas | Fitur |
|---|---|
| P0 | Daftar & login pemilik kos (data terisolasi per pemilik) |
| P0 | Properti, kamar, harga sewa per kamar |
| P0 | Data penghuni (masuk, jatuh tempo, tandai keluar tanpa hapus riwayat) |
| P0 | Tagihan bulanan otomatis H-3, satu tagihan per penghuni per periode |
| P0 | Link bayar QRIS/VA unik per tagihan (Midtrans Snap) |
| P0 | Status lunas otomatis via webhook (terverifikasi, idempoten) |
| P0 | Kirim tagihan via WA (link `wa.me`, klik kirim) |
| P0 | Dashboard bulan ini (lunas / belum / telat, total diterima) |
| P0 | Kuitansi digital untuk penghuni |
| P1 | Pengingat telat, tagihan tambahan, catat bayar tunai, ekspor CSV |

Detail lengkap: [`docs/PRD.md`](docs/PRD.md). Keputusan teknis: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Tech stack

| Lapisan | Pilihan |
|---|---|
| Bahasa / framework | Ruby 3.3 + Rails 8 |
| UI | Hotwire (Turbo + Stimulus), mobile-first |
| Database | SQLite (production-grade di Rails 8) |
| Background job & cron | Solid Queue (recurring tasks) |
| Cache | Solid Cache |
| Payment | Midtrans Snap API (akun Midtrans milik tiap pemilik kos) |
| WhatsApp | Link `wa.me` (tanpa WA API di MVP) |
| Deploy | Kamal 2 ke VPS lokal |

Tanpa Redis, tanpa Postgres terpisah, tanpa layanan eksternal selain Midtrans.

## Prasyarat

- Ruby 3.3.6 (lihat [`.ruby-version`](.ruby-version))
- SQLite 3.45+ dengan header development (`libsqlite3-dev`)
- Akun Midtrans **sandbox** untuk development

## Menjalankan secara lokal

> Berlaku setelah kode aplikasi masuk.

```bash
git clone https://github.com/erick-surbakti/Ingetin.git
cd Ingetin
cp .env.example .env
bin/setup        # install gem, siapkan database, jalankan server
```

Perintah harian:

| Perintah | Fungsi |
|---|---|
| `bin/dev` | Jalankan server + asset watcher |
| `bin/rails test` | Jalankan test |
| `bin/rubocop` | Lint |
| `bin/brakeman` | Scan keamanan |
| `bin/jobs` | Jalankan Solid Queue (cron tagihan H-3) |

## Variabel lingkungan

Lihat [`.env.example`](.env.example). Rahasia aplikasi (kunci enkripsi, dsb.) disimpan di Rails credentials, bukan di `.env`. Server key Midtrans tiap pemilik kos disimpan terenkripsi di database.

## Struktur repo

```
.github/          CI, Dependabot, template issue & PR
docs/             PRD dan keputusan arsitektur
```

## Kontribusi

Lihat [`CONTRIBUTING.md`](CONTRIBUTING.md).
