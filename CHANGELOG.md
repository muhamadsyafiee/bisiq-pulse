# Changelog

## [1.5.0] — 2026-10-08

### Ditambah

- **PULSE Pro** sebagai pembelian sekali bayar melalui Google Play Billing (produk `pulse_pro_lifetime`; harga permulaan dirancang RM19.90 dan dibaca terus daripada Google Play). Tiada langganan atau iklan.
- Versi percuma: pemasa penuh, bunyi, semua bahasa, sehingga 3 rutin sendiri dan rakaman penuh dengan watermark PULSE pada pratonton serta MP4 eksport. Panel pemasa menggunakan kedudukan asas (bawah) dan tema Standard.
- Pro: rutin tanpa had, rakaman baharu tanpa watermark, panel boleh diseret ke mana-mana dan tema Lutsinar.
- Halaman Pro dalam Tetapan, serta tawaran Pro hanya apabila pengguna mencipta rutin keempat atau memilih ciri kamera Pro sebelum merakam. Rakaman yang sedang berjalan tidak diganggu.
- **Pulihkan Pembelian** untuk telefon baharu atau pemasangan semula; pembelian disemak semula secara automatik apabila aplikasi dibuka.
- Pelayan pengesahan (`backend/`) yang menyemak pembelian dengan Google Play Developer API, mengakui (acknowledge) pembelian, kemudian mengeluarkan lesen bertandatangan Ed25519 untuk pemasangan itu. Pro boleh digunakan luar talian sehingga 7 hari sebelum disahkan semula.

### Keserasian

- Rutin sedia ada tidak dipadam atau dikunci walaupun melebihi 3; semuanya kekal boleh dibuka, diedit dan dirakam. Hanya rutin baharu yang memerlukan Pro.
- Rakaman lama dan video yang sudah dieksport tidak diubah; rakaman sebelum versi ini dieksport tanpa watermark seperti asal.
- APK GitHub versi lama kekal boleh digunakan.

### Had diketahui

- **Pembelian belum boleh dibuat lagi.** Aplikasi `com.pulseworkout.gym_timer` belum wujud dalam akaun Play Console yang boleh diakses oleh pelayan pengesahan, dan produk `pulse_pro_lifetime` belum dicipta. Sehingga itu, halaman Pro memaparkan mesej bahawa Google Play tidak dapat dihubungi dan semua ciri percuma kekal berfungsi.
- Google Play Billing hanya berfungsi untuk pemasangan daripada Play Store. APK GitHub ini (ditandatangani dengan kunci debug tempatan) memaparkan had versi percuma tetapi tidak boleh membeli Pro.
- Pengguna yang mengalihkan pemasangan daripada APK GitHub ke Play Store perlu nyahpasang dahulu kerana kunci tandatangan berbeza; rutin dan rakaman dalam aplikasi tidak dipindahkan secara automatik.

## [1.4.0] — 2026-10-08

### Ditambah

- Enam pakej bahasa luar talian: Bahasa Malaysia, English, Bahasa Indonesia, Cina ringkas, Tamil dan Arab; Bahasa Malaysia menjadi lalai pada pemasangan pertama.
- Pemilihan bahasa pada onboarding dan halaman Tetapan, dengan perubahan serta-merta dan simpanan untuk pelancaran seterusnya.
- Terjemahan 187 mesej merangkumi semua skrin, dialog, validasi, ralat, aksesibiliti, template, pemasa dan paparan kamera.
- Susun atur kanan ke kiri untuk Arab; eksport video menggunakan pembentukan tulisan native bagi skrip Arab/Tamil.
- Bahasa disimpan bersama rakaman supaya eksport/retry kekal mengikut bahasa sesi asal.
- Katalog JSON dan penjana yang mengesahkan kelengkapan kunci serta placeholder bagi setiap bahasa.

### Keserasian dan pengesahan

- Nama/nota pengguna kekal seperti ditaip. Medan template yang tidak disunting mengikuti bahasa pilihan; template lama yang sepadan sepenuhnya dikenal pasti secara automatik.
- Video yang sudah siap tidak ditulis semula. Bahasa dialog sistem/galeri bergantung pada Android; penyelarasan bahasa sistem tersedia pada Android 13+.
- 62 ujian lulus, termasuk keenam-enam bahasa pada onboarding, Tetapan selepas simpan rutin, kamera pada skrin kecil, pemulihan pilihan bahasa dan payload eksport video.
- `flutter analyze` tiada isu; APK release dibina untuk versi `1.4.0+5`.
- Pertukaran/pemulihan bahasa dan eksport video Arab/Tamil ke galeri disahkan pada emulator Android API 36.
- APK menggunakan kunci debug tempatan yang sama untuk pemasangan/ujian. Pengesahan kamera menggunakan emulator sintetik; telefon fizikal belum diuji.


## [1.3.0] — 2026-10-08

### Ditambah

- Seret panel pemasa dalam bingkai kamera sebelum mula merakam, termasuk bahagian atas dan tengah.
- Pilihan tema **Standard** (latar gelap) dan **Transparent** (tanpa latar dengan bayang teks).
- Tetapan kedudukan/tema disimpan untuk sesi seterusnya; butang **Reset paparan** memulihkan paparan asal.
- Kedudukan dan tema turut digunakan dalam MP4 eksport, serta disimpan bersama metadata setiap rakaman untuk retry yang konsisten.
- Tindakan pembaca skrin untuk memindahkan panel ke atas, tengah atau bawah.

### Diperbaiki

- Panel dihadkan dalam sempadan video supaya teks tidak terpotong apabila diseret ke tepi.
- Pratonton menggunakan nisbah kamera sebenar; kawalan diletakkan di luar bingkai rakaman.
- Rakaman lama tanpa tetapan paparan mengekalkan susun atur eksport versi 1.2.

### Pengesahan dan nota

- 42 ujian lulus, termasuk seretan, had kedudukan, tema, pemulihan tetapan dan metadata rakaman lama.
- Eksport Transparent di atas dan Standard di tengah disahkan pada emulator, termasuk simpan ke galeri dan tetapan selepas restart.
- Kedudukan/tema dikunci semasa rakaman; ubah sebelum menekan **MULA & RAKAM**.
- Versi `1.3.0+4`; APK menggunakan kunci debug tempatan yang sama.
- Kamera sintetik emulator digunakan untuk pengesahan; telefon fizikal belum diuji.

## [1.2.0] — 2026-10-08

### Ditambah

- **RAKAM LATIHAN** pada setiap rutin: pilih kamera depan atau belakang sebelum mula.
- **MULA & RAKAM** memulakan pemasa serta rakaman video; berhenti automatik selepas gerakan terakhir atau hentikan lebih awal.
- Paparan langsung gerakan, masa berbaki, rehat hijau/oren dan gerakan seterusnya di atas kamera.
- Eksport MP4 dengan nama rutin, gerakan dan pemasa tertera dalam video menggunakan Media3.
- **Rakaman Saya**: simpan ke galeri, cuba semula eksport yang gagal dan padam salinan aplikasi.
- Mikrofon pilihan dengan izin Android; rakaman senyap secara lalai.
- Simpan rakaman asal sebelum eksport, pemulihan senarai selepas restart dan retry apabila simpanan gagal.
- Rakaman dihentikan dan disimpan apabila aplikasi terganggu atau masuk latar belakang.
- Paparan kamera boleh ditatal pada skrin kecil atau fon besar.

### Pengesahan

- 37 ujian lulus; `flutter analyze` tiada isu; APK release berjaya dibina.
- Rakaman kamera sintetik emulator, eksport pemasa dan simpanan galeri diuji pada Android API 36.

### Nota

- Mod kamera merakam satu sesi berterusan dalam potret; tukar kamera/mikrofon sebelum mula. Jeda dan langkau tersedia dalam mod pemasa biasa.
- Kekalkan aplikasi terbuka semasa pemprosesan video; rakaman asal boleh diproses semula jika eksport terganggu.
- Kamera/mikrofon telefon fizikal belum diuji. APK menggunakan kunci debug yang sama untuk pemasangan/ujian tempatan.
- Versi aplikasi `1.2.0+3`.

## [1.1.0] — 2026-10-08

### Ditambah

- Onboarding penggunaan pertama: pilih template atau cipta latihan sendiri.
- Halaman **Latihan Saya** untuk menyimpan dan memilih banyak rutin.
- Tiga template boleh ubah: Upper Body, Cardio Express dan Regangan Ringkas.
- Editor nama rutin, nama gerakan, masa senaman, masa rehat dan nota pilihan.
- Tambah, buang dan susun semula gerakan; edit dan padam rutin tersimpan.
- Simpanan tempatan yang kekal selepas aplikasi ditutup dan dibuka semula.
- Validasi nama/durasi, pengesahan perubahan belum disimpan dan pemadaman.
- Pengendalian kegagalan baca/simpan dengan pilihan cuba lagi tanpa membuang data.
- Aliran penerbitan projek: changelog, commit/push, tag versi dan APK pada GitHub Releases.

### Dikemas kini

- Pemasa menggunakan nama, gerakan dan tempoh daripada rutin yang dipilih.
- Versi aplikasi `1.1.0+2`.

### Pengesahan

- 26 ujian lulus; `flutter analyze` tiada isu.
- APK release berjaya dibina dan tandatangannya disahkan.
- Emulator Android API 36: import template, cipta rutin kedua, simpanan selepas
  restart dan pemasa dengan durasi tersuai disahkan.

### Nota

- APK menggunakan kunci debug untuk pemasangan/ujian tempatan.
- Simpanan rutin berada pada peranti; tiada penyegerakan awan.
- Audio dimainkan ketika aplikasi di hadapan; tiada Android foreground service.

## [1.0.0] — 2026-10-08

- Projek Android Flutter PULSE dengan empat gerakan Upper Body.
- Pemasa senaman/rehat automatik, ring hijau/oren, dan penunjuk gerakan seterusnya.
- Kawalan mula, jeda/sambung, reset, langkau dan dialog tamat sesi.
- Isyarat audio luar talian untuk kira detik, mula, rehat dan tamat.
- Skrin kekal aktif semasa latihan menggunakan `wakelock_plus`.
- 13 ujian lulus; APK release dibina dan diuji pada emulator.

[1.1.0]: https://github.com/muhamadsyafiee/bisiq-pulse/releases/tag/v1.1.0

[1.2.0]: https://github.com/muhamadsyafiee/bisiq-pulse/releases/tag/v1.2.0

[1.3.0]: https://github.com/muhamadsyafiee/bisiq-pulse/releases/tag/v1.3.0
