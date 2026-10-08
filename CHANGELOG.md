# Changelog

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
