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
- AAB 1.5.1 (versionCode 7), ditandatangani dengan kunci muat naik, aktif dalam trek ujian dalaman; Play Console menunjukkan **Available to internal testers**, dilancarkan pada 9 Oktober, 2:00 pagi.
- Produk `pulse_pro_lifetime`, pilihan beli `lifetime` (legacy compatible), AKTIF pada RM19.90 di Malaysia.
- Senarai e-mel **Bisiq internal** dipilih untuk ujian dalaman dan ujian lesen, dengan respons `RESPOND_NORMALLY`. Akaun penguji yang diberikan pengguna sudah berada dalam senarai dan sudah menyertai program ujian.

Ujian seterusnya pada telefon:

1. Log masuk Play Store menggunakan akaun penguji yang didaftarkan. Buka [pautan ujian dalaman](https://play.google.com/apps/internaltest/4701082394880794363) dan pilih **Download test app**.
2. Jika APK GitHub masih dipasang, simpan video yang diperlukan ke galeri dan catat rutin dahulu, kemudian nyahpasang APK itu. Kunci tandatangan Play Store berbeza; nyahpasang memadam data tempatan aplikasi.
3. Pasang PULSE daripada Play Store dan buka **Tetapan → PULSE Pro**. Pilih kaedah ujian seperti **Test card, always approves**; jangan teruskan jika dialog menunjukkan kaedah bayaran sebenar. Sahkan ciri Pro dibuka selepas pengesahan pelayan.
4. Uji **Pulihkan Pembelian**, pembayaran tertunda/ditolak dan pembatalan/bayaran balik ujian. Rekod hasil sebelum keluaran awam; ujian ini belum dilakukan pada telefon.

Nama sementara `com.pulseworkout.gym_timer (unreviewed)` masih digunakan sehingga persediaan aplikasi dan semakan Google Play selesai. Ujian dalaman ini bukan keluaran awam.

Membina dan memuat naik AAB baharu:

```bash
scripts/build_play_bundle.sh
```

## Ujian

```bash
cd backend && npm ci && npm test
```
