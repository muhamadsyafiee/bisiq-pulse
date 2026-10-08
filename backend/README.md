# Pelayan pengesahan PULSE Pro

Pelayan Node.js kecil yang mengesahkan pembelian Google Play `pulse_pro_lifetime` untuk `com.pulseworkout.gym_timer` sebelum aplikasi membuka Pro.

## Aliran

1. Aplikasi menghantar `purchaseToken` dan ID pemasangan rawak ke `POST /v1/entitlements/verify`.
2. Pelayan membaca pembelian melalui Google Play Developer API (`purchases.productsv2`), menolak pembelian tertunda, dibatalkan, dibayar balik, digunakan (consumed), sewaan atau pra-tempahan, dan mengakui (acknowledge) pembelian yang sah.
3. Pelayan memulangkan lesen JSON bertandatangan Ed25519 yang terikat pada pakej, produk dan pemasangan itu, sah 7 hari. Aplikasi mengesahkan tandatangan dengan kunci awam dalam `config/pulse_billing.json`.

Kod status: `200` lesen, `403` pembelian tidak sah, `409` bayaran tertunda, `503` pengesahan tidak tersedia (termasuk ralat konfigurasi Play Console; ini tidak membatalkan Pro yang sudah disimpan).

## Deployment semasa

- Projek Google Cloud: `bisiq-backend`, servis Cloud Run `pulse-billing` (`asia-southeast1`).
- URL: `https://pulse-billing-828399106175.asia-southeast1.run.app`
- Identiti: service account `bisiq-play-api@bisiq-backend.iam.gserviceaccount.com` melalui Application Default Credentials. Tiada fail kunci service account digunakan.
- Kunci peribadi Ed25519: Secret Manager `pulse-entitlement-private-key`, dipasang sebagai `PULSE_ENTITLEMENT_PRIVATE_KEY`. Hanya service account di atas boleh membacanya.

```bash
gcloud run deploy pulse-billing --source backend --project bisiq-backend --region asia-southeast1
```

Menukar kunci peribadi memerlukan kunci awam baharu dalam `config/pulse_billing.json` dan APK baharu; lesen yang dikeluarkan dengan kunci lama tidak lagi diterima.

## Status Play Console

Selesai (9 Oktober 2026):

- Aplikasi `com.pulseworkout.gym_timer` wujud dan service account mempunyai akses.
- AAB 1.5.1 (versionCode 7), ditandatangani dengan kunci muat naik, berada dalam trek ujian dalaman sebagai draf.
- Produk `pulse_pro_lifetime`, pilihan beli `lifetime` (legacy compatible), AKTIF pada RM19.90 di Malaysia.

Masih perlu dibuat dalam Play Console:

1. **Ujian dalaman** → tambah senarai penguji (e-mel Google) → semak dan lancarkan keluaran draf 1.5.1.
2. **Tetapan → Ujian lesen** → tambah akaun penguji yang sama supaya pembelian ujian tidak dicaj.
3. Pada telefon penguji, buka pautan opt-in ujian dalaman, nyahpasang APK GitHub jika ada, pasang PULSE daripada Play Store, kemudian uji beli, pembayaran tertunda, bayaran balik dan **Pulihkan Pembelian**.

Membina dan memuat naik AAB baharu:

```bash
scripts/build_play_bundle.sh
```

## Ujian

```bash
cd backend && npm ci && npm test
```
