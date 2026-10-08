# Pengesahan binaan 1.1.0+2

Tarikh: 8 Oktober 2026

- Flutter 3.47.6 stable, Dart 3.13.5.
- `flutter analyze`: tiada isu.
- `flutter test`: kesemua 26 ujian lulus (13 pemasa terdahulu + 13 pengurusan rutin/onboarding).
- `flutter build apk --release`: berjaya, APK universal kira-kira 50.9 MB.
- `apksigner verify`: tandatangan APK sah; masih menggunakan kunci debug untuk ujian tempatan.
- APK dipasang sebagai kemas kini pada emulator Android API 36, arm64.

## Semakan emulator versi 1.1

1. Tanpa simpanan terdahulu, aplikasi memaparkan pilihan **Guna template** dan **Cipta latihan sendiri**.
2. Import template **Upper Body** membuka editor dengan empat gerakan, masa senaman dan rehat diisi.
3. Simpan template membawa pengguna ke **Latihan Saya**.
4. Cipta rutin kedua **Latihan pagi**, dengan gerakan **Squat**, durasi senaman **45 saat**; kedua-dua rutin muncul berasingan.
5. Hentikan proses aplikasi (`am force-stop`) dan buka semula. **Latihan Saya** terus dibuka, kedua-dua rutin masih wujud dan onboarding tidak berulang.
6. Buka pemasa rutin tersimpan: nama **Latihan pagi**, gerakan **Squat**, dan **45 saat** dipaparkan dengan betul.
7. Tiada exception Flutter dalam log sesi pemeriksaan.

Ujian automatik turut meliputi edit/padam, pembatalan pemadaman, ubah susunan gerakan, tambah/buang gerakan, validasi nama/durasi, kegagalan simpan dengan retry tanpa kehilangan input, data rosak tanpa ditimpa, pembatalan onboarding, dialog perubahan belum disimpan, dan paparan editor sempit dengan fon besar.

Fungsi pemasa asas, audio dan wakelock diliputi ujian regresi. Semakan manual versi 1.0 sebelumnya telah mengesahkan peralihan workout/rest, jeda/sambung, kunci skrin, kembali dari latar belakang dan penamat 4/4. Output bunyi pembesar suara fizikal belum diuji; emulator menggunakan output audio hos yang dimatikan.

APK: `build/app/outputs/flutter-apk/app-release.apk`

SHA-256:

```text
3fc9f31ec53cc8212e3b4124693292a987b1ba61b251bce910fd34c4061ad506
```

Tangkapan skrin versi 1.1:

- [Onboarding](screenshots/onboarding.png)
- [Editor](screenshots/editor.png)
- [Latihan Saya selepas restart](screenshots/library.png)

Tangkapan skrin pemasa versi 1.0: [Sedia](screenshots/ready.png), [Rehat](screenshots/rest.png), [Selesai](screenshots/finished.png).
