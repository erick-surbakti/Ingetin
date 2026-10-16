# Arsitektur & Keputusan Teknis

Dokumen hidup. Setiap keputusan besar dicatat di sini beserta alasannya.

## 1. Stack

| Keputusan | Pilihan | Alasan |
|---|---|---|
| Framework | Rails 8 | Satu framework lengkap: auth, job, cron, enkripsi, mailer bawaan |
| Database | SQLite | Skala MVP (≤100 pemilik × ≤100 kamar ≈ 10 ribu tagihan/bulan) jauh di bawah batas SQLite |
| Job & cron | Solid Queue | Recurring task bawaan, tanpa Redis |
| UI | Hotwire | Interaktif tanpa SPA terpisah |
| Deploy | Kamal 2 → VPS lokal | Murah, data tetap di Indonesia (UU PDP) |

Tidak memakai Redis: idempotensi dan anti-dobel ditangani unique index di database.

## 2. Multi-tenancy

- Pemilik kos adalah model `User` (bawaan generator autentikasi Rails). Setiap data milik satu `User`. Semua query lewat relasi pemilik yang sedang login, misalnya `Current.user.properties`, bukan `Property.find`.
- Halaman publik penghuni (tagihan, kuitansi) diakses lewat token acak yang tidak bisa ditebak (`has_secure_token`), bukan ID berurutan.
- Wajib ada test isolasi: pemilik A tidak bisa membaca atau mengubah data pemilik B.

## 3. Uang & waktu

- Nominal disimpan sebagai **integer Rupiah**. Tidak ada float.
- Zona waktu aplikasi `Asia/Jakarta`. Periode tagihan disimpan sebagai tanggal awal bulan (`period = 2026-11-01`).
- Jatuh tempo tanggal 29–31 di bulan yang lebih pendek dipotong ke hari terakhir bulan itu.

## 4. Tagihan otomatis H-3

- Recurring task Solid Queue jalan **setiap hari pukul 01:00 WIB**.
- Membuat tagihan untuk penghuni aktif yang jatuh temponya ≤ 3 hari lagi dan belum punya tagihan periode itu.
- Unique index `(tenant_id, period)` menjamin tidak dobel, walaupun job jalan dua kali.
- Job harus idempoten: aman dijalankan ulang kapan saja.

## 5. Midtrans

### Kredensial per pemilik

- Server key dan client key Midtrans milik tiap pemilik disimpan dengan **Active Record Encryption** (`encrypts :midtrans_server_key`).
- Kunci enkripsi ada di Rails credentials, tidak pernah di repo.

### Link bayar & biaya admin VA

Penghuni memilih metode di halaman Snap, jadi satu link tidak bisa memuat dua nominal berbeda. Solusinya: halaman tagihan menampilkan **dua tombol**, masing-masing membuat transaksi Snap sendiri dengan `enabled_payments` dibatasi:

| Tombol | `enabled_payments` | Nominal |
|---|---|---|
| Bayar QRIS | `other_qris` | Sewa |
| Bayar Virtual Account | VA bank | Sewa + biaya admin VA |

Setiap percobaan bayar adalah satu `Payment` dengan `order_id` unik (`ING-<id tagihan>-<acak>`). Percobaan yang masih terbuka (≤23 jam) dipakai ulang untuk metode yang sama, sehingga penghuni yang menekan tombol dua kali tetap mendapat VA yang sama.

### Routing webhook

- Satu endpoint untuk semua pemilik: `POST /webhooks/midtrans`.
- `order_id` (`ING-<id tagihan>-<acak>`) dipakai untuk menemukan `Payment`, lalu pemiliknya dan server key-nya.
- Pemilik mengisi URL ini di dashboard Midtrans (Settings → Payment → Notification URL). Halaman Pengaturan Pembayaran menampilkan URL-nya.
- Sebagai cadangan, setiap transaksi Snap juga mengirim header `X-Override-Notification` (hanya jika URL HTTPS). Dokumentasi Midtrans menyebut header ini untuk Core API; dukungannya di Snap perlu dicek di sandbox.
- Saat penghuni kembali dari Snap (`?order_id=...`), halaman tagihan langsung menyinkronkan status lewat Get Status API, jadi kuitansi tampil walau webhook terlambat.

### Verifikasi & idempotensi

1. Hitung `SHA512(order_id + status_code + gross_amount + server_key)` dengan server key pemilik tagihan dan bandingkan dengan `signature_key` memakai perbandingan constant-time. Gagal berarti respons 401.
2. Konfirmasi ulang status lewat Get Status API. Isi notifikasi tidak dipercaya untuk mengubah status.
3. `order_id` dan `gross_amount` dari Get Status harus sama dengan `Payment`.
4. `settlement` (atau `capture` + `fraud_status=accept`) berarti **Lunas**. Status lain hanya dicatat di `Payment`.
5. Sinkron berjalan di dalam row lock. Payment yang sudah punya `paid_at` tidak diproses lagi, dan `midtrans_transaction_id` unik.
6. Get Status gagal dihubungi berarti respons 503, sehingga Midtrans mencoba ulang.

## 6. Autentikasi

- MVP memakai generator autentikasi bawaan Rails 8: email + password, dengan reset password via email.
- Login via nomor WA ditunda, karena butuh OTP lewat WA API yang berbayar dan di luar cakupan MVP.

## 7. WhatsApp

- Link `https://wa.me/<nomor>?text=<pesan URL-encoded>`.
- Nomor dinormalisasi ke format internasional (`08xx` menjadi `628xx`).

## 8. Sketsa model data

```
User ──┬─ Property ── Room ── Tenant ── Invoice ─┬─ InvoiceItem (P1)
       │                                         └─ Payment
       └─ MidtransCredential (terenkripsi)
```

| Model | Kolom kunci |
|---|---|
| User (pemilik kos) | name, email_address, password_digest, plan, webhook_token |
| Property | owner_id, name, address |
| Room | property_id, name, monthly_rent |
| Tenant | room_id, name, phone, move_in_on, due_day, moved_out_on |
| Invoice | tenant_id, period, due_on, amount, status, public_token — unique `(tenant_id, period)` |
| Payment | invoice_id, order_id (unique), channel (qris/va), gross_amount, admin_fee, midtrans_transaction_id (unique), status, paid_at |

## 9. Operasional

- SQLite di volume persisten VPS. Backup kontinu (misalnya Litestream ke object storage S3-compatible) wajib sebelum ada pengguna sungguhan.
- Error tracking & uptime monitor ditentukan sebelum rilis.
