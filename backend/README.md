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

## Langkah Play Console yang masih diperlukan

1. Cipta aplikasi `com.pulseworkout.gym_timer` dan muat naik AAB yang dibina dengan `--dart-define-from-file=config/pulse_billing.json` ke trek ujian dalaman. AAB memerlukan kunci muat naik (upload key) sendiri, bukan kunci debug.
2. Cipta produk sekali beli (one-time product) `pulse_pro_lifetime`, harga RM19.90, dan aktifkan.
3. **Pengguna dan kebenaran** → jemput `bisiq-play-api@bisiq-backend.iam.gserviceaccount.com` dengan kebenaran *View financial data* dan *Manage orders and subscriptions* untuk aplikasi PULSE.
4. Tambah akaun penguji lesen, pasang daripada trek ujian dalaman, kemudian uji beli, bayaran tertunda, bayaran balik dan **Pulihkan Pembelian**.

Semakan pantas selepas langkah 3: permintaan dengan token palsu sepatutnya memulangkan `403`, bukan `503`.

## Ujian

```bash
cd backend && npm ci && npm test
```
