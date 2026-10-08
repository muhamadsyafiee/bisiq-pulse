# Pengesahan binaan 1.2.0+3

Tarikh: 8 Oktober 2026

- Flutter 3.47.6 stable, Dart 3.13.5; Android API 24 minimum.
- `flutter analyze`: tiada isu.
- `flutter test`: 37 ujian lulus, termasuk 11 ujian kamera/arkib/paparan baharu.
- `flutter build apk --release`: berjaya, APK universal 53,780,900 bait (53.8 MB).
- `apksigner verify`: tandatangan sah, kunci debug tempatan yang sama.
- APK dipasang sebagai kemas kini pada emulator Android API 36 arm64; rutin dan onboarding sedia ada dikekalkan.

## Semakan kamera versi 1.2

- Izin kamera muncul apabila mod kamera dibuka. Pratonton kamera depan dan belakang sintetik berjaya; kamera boleh ditukar sebelum mula.
- Mikrofon dimatikan secara lalai. Menghidupkannya meminta izin audio Android.
- Mula memaparkan indikator REC dan menggerakkan pemasa; wakelock aktif semasa rakaman.
- Kamera belakang: hentikan secara manual selepas kira-kira 20 saat, eksport MP4 dan simpan ke MediaStore/galeri berjaya.
- Bingkai daripada video eksport diperiksa pada saat 2 dan 10: pemasa berubah daripada 0:18 ke 0:10, dengan nama rutin, gerakan dan penunjuk gerakan seterusnya.
- Kamera depan: sesi Upper Body penuh berjalan melalui senaman dan rehat, kemudian berhenti sendiri selepas empat gerakan (1 minit 50 saat).
- Video kamera depan dieksport dan disimpan ke galeri: durasi kira-kira 110.1 saat, H.264 dan trek audio. Bingkai saat 22 menunjukkan REHAT 0:08 (oren), dan saat 32 menunjukkan Diamond Pushup 0:18, gerakan 2/4 (hijau).
- APK akhir: menekan Home semasa rakaman menghentikan dan menyimpan video, memaparkan notis gangguan, dan tidak memulakan rakaman semula apabila kembali. `dumpsys window` mengesahkan kunci skrin kekal aktif semasa eksport selepas pembetulan lifecycle.

Ujian automatik meliputi izin ditolak dengan retry, kegagalan mula, masa hanya bermula setelah kamera bersedia, tekan mula/henti berulang, penamat automatik, aplikasi diganggu ketika mula, kegagalan storan dengan retry, pemulihan arkib selepas restart, metadata rosak, eksport gagal mengekalkan rakaman asal, dan skrin kecil dengan fon besar. Ujian pemasa/rutin terdahulu kekal lulus.

Kamera emulator menggunakan corak sintetik, bukan kamera hos. Kamera depan/belakang dan output mikrofon/bunyi pada telefon fizikal belum diuji. Mod kamera sengaja menggunakan satu rakaman berterusan; tiada jeda atau langkau semasa rakaman. Gangguan proses sebelum video mentah sempat disimpan masih boleh kehilangan rakaman aktif.

APK: `build/releases/pulse-v1.2.0.apk`

SHA-256:

```text
850b1b632890455f32a1903b1949db1cc08437dc022df040a2ac333dfc24065f
```

Bukti visual: [Kamera dan pemasa](screenshots/camera.png), [Rehat semasa rakaman](screenshots/camera-rest.png), [Bingkai senaman daripada MP4 eksport](screenshots/video-workout.png), [Bingkai rehat daripada MP4 eksport](screenshots/video-rest.png), [Rakaman Saya](screenshots/recordings.png).

---

# Rekod terdahulu: 1.1.0+2

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
