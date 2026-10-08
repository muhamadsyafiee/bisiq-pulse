# Pengesahan binaan

Tarikh: 8 Oktober 2026

- Flutter 3.47.6 stable, Dart 3.13.5.
- `flutter analyze`: tiada isu.
- `flutter test`: kesemua 13 ujian lulus.
- `flutter build apk --release`: berjaya, APK universal kira-kira 46.2 MB.
- `apksigner verify --verbose`: tandatangan APK sah (v2, kunci debug untuk ujian tempatan).
- APK berjaya dipasang dan dijalankan pada emulator Android API 36, arm64.
- Semakan emulator: mula, pertukaran automatik senaman/rehat, ring hijau/oren, jeda/sambung, masa tetap ketika jeda, kembali daripada latar belakang, dan penamat semula jadi dengan 4/4 gerakan selesai.
- `dumpsys window` mengesahkan `KEEP_SCREEN_ON` aktif semasa berjalan, dilepaskan ketika jeda dan tamat, serta dipulihkan ketika kembali ke aplikasi.
- Tiada ralat Flutter/audio atau crash aplikasi ditemui dalam log sesi pemeriksaan. Output bunyi pembesar suara fizikal belum diuji; emulator dijalankan tanpa output audio hos.

APK: `build/app/outputs/flutter-apk/app-release.apk`

SHA-256:

```text
8d362d347c381e067d4d8a0958371c14cb6051bb10103f2c1bcc40ca5b288771
```

Tangkapan skrin daripada APK release:

- [Sedia](screenshots/ready.png)
- [Rehat](screenshots/rest.png)
- [Selesai](screenshots/finished.png)
