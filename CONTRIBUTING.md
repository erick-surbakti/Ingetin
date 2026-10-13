# Panduan Kontribusi

## Alur kerja

1. Buat branch dari `main`: `feat/...`, `fix/...`, `chore/...`, atau `docs/...`.
2. Commit kecil dan fokus. Format pesan mengikuti [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat: buat tagihan otomatis H-3`
   - `fix: webhook dobel tidak lagi diproses dua kali`
3. Buka pull request ke `main`. CI wajib hijau sebelum merge.
4. Merge memakai **squash merge**.

## Standar kode

- Ikuti RuboCop (`bin/rubocop`). Jangan matikan cop tanpa alasan tertulis.
- Setiap fitur P0 punya test, terutama:
  - isolasi data antar pemilik kos
  - pembuatan tagihan yang tidak dobel
  - verifikasi signature dan idempotensi webhook Midtrans
- Nominal uang selalu integer Rupiah.
- Jangan pernah commit rahasia: `.env`, `config/master.key`, atau server key Midtrans.

## Midtrans

- Development dan CI hanya memakai **sandbox**.
- Untuk menguji webhook di lokal, expose server dengan tunnel (misalnya `cloudflared` atau `ngrok`).
