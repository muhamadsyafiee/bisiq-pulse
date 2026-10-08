# Pengesahan binaan 1.4.0+5

Tarikh: 8 Oktober 2026

- `flutter analyze`: tiada isu.
- `flutter test`: 62 ujian lulus.
- Penjana mengesahkan enam katalog lengkap, 187 mesej setiap bahasa dan placeholder yang sama; ujian membandingkan JSON dengan katalog Dart yang digunakan aplikasi.
- `flutter build apk --release`: berjaya, APK universal 55,927,836 bait.
- `apksigner verify --verbose`: tandatangan v2 sah, kunci debug tempatan yang sama.
- `aapt dump badging`: versi 1.4.0, versionCode 5, minimum API 24, sasaran API 36.
- APK akhir dipasang sebagai kemas kini pada emulator API 36 arm64. Tiga rutin sedia ada serta rakaman terdahulu kekal tersedia.

## Semakan bahasa

- Enam bahasa diuji melalui onboarding, Tetapan, import/simpan template dan pertukaran bahasa selepas rutin disimpan. Susun atur Arab ialah kanan ke kiri; ujian menggunakan lebar 360 piksel logik.
- Keenam-enam bahasa diuji pada kamera dan pemasa dengan skrin 320 × 640 serta skala teks 1.3; tiada overflow. Kawalan mula/rakam, tukar kamera dan pemasa kekal berfungsi.
- Lalai Bahasa Malaysia, pemulihan bahasa tersimpan, kegagalan simpan tanpa menukar pilihan lama, pemeliharaan teks peribadi dan pengenalpastian template lama diuji secara automatik.
- Emulator menunjukkan template Upper Body lama diterjemah apabila memilih Arab/Tamil. Nama peribadi “Latihan pagi” dan “Squat” kekal seperti asal.
- Pilihan Arab kekal selepas pemasangan APK akhir; pilihan Tamil kekal selepas proses dihentikan dan dibuka semula. Pilihan dipulihkan ke Bahasa Malaysia selepas QA.
- Video Arab 10.66 saat dan Tamil 7.118 saat berjaya dieksport serta disimpan ke galeri. Bingkai saat 2 menunjukkan nama rutin, status, gerakan, unit, gerakan seterusnya dan pemasa 0:18 dalam bahasa sesi. Tulisan bersambung/kompleks dirender menggunakan StaticLayout Android.
- Ujian arkib mengesahkan bahasa sesi disimpan dalam metadata, label/template diterjemah dalam payload native dan bahasa dikekalkan selepas eksport. Rakaman baharu Arab kekal berbahasa Arab walaupun senarai aplikasi kemudian ditukar ke Tamil.
- Tiada exception AndroidRuntime atau Flutter error dalam log semasa QA.

Kamera sintetik emulator digunakan, bukan kamera hos. Telefon fizikal belum diuji. Enam bahasa disertakan secara luar talian; tiada terjemahan automatik bagi bahasa lain. Kandungan pengguna dan video siap lama tidak diterjemah semula. Bahasa dialog OS/galeri bergantung pada versi dan sokongan Android.

APK: `build/releases/pulse-v1.4.0.apk`

SHA-256:

```text
bb72c9a40644466036e26d3720270002c268b9eacf22075937727df1b4185c05
```

Bukti visual:

- [Pilihan bahasa](screenshots/language-settings-v1.4.png)
- [Rutin dalam Arab](screenshots/library-arabic-v1.4.png)
- [Rutin dalam Tamil](screenshots/library-tamil-v1.4.png)
- [MP4 dengan teks Arab](screenshots/video-arabic-v1.4.png)
- [MP4 dengan teks Tamil](screenshots/video-tamil-v1.4.png)

---

# Rekod terdahulu: 1.3.0+4

Tarikh: 8 Oktober 2026

- `flutter analyze`: tiada isu.
- `flutter test`: 42 ujian lulus; lima kes baharu dan ujian arkib sedia ada diperluas untuk metadata paparan.
- `flutter build apk --release`: berjaya, APK universal 54,043,012 bait (54.0 MB).
- `apksigner verify --verbose`: tandatangan v2 sah menggunakan kunci debug tempatan.
- `aapt dump badging`: versi 1.3.0, versionCode 4, minimum Android API 24.
- APK dipasang sebagai kemas kini pada emulator Android API 36 arm64; rutin dan rakaman versi 1.2 kekal tersedia.

## Semakan paparan kamera

1. Seret panel dari bawah ke atas kiri dalam pratonton kamera depan. Panel berhenti pada margin video dan mengikuti keseluruhan pergerakan jari.
2. Pilih **Transparent**: latar panel hilang, teks dan pemasa kekal dengan bayang. Rakaman 10.55 saat berjaya dieksport dan disimpan ke galeri. Bingkai MP4 pada saat 2 menunjukkan panel atas kiri tanpa latar serta pemasa 0:18.
3. Pilih **Standard**, seret ke tengah kanan dan tukar ke kamera belakang. Rakaman 12.12 saat berjaya dieksport/disimpan; bingkai MP4 pada saat 2 menunjukkan panel gelap pada kedudukan yang dipilih, dengan pemasa 0:18.
4. Hentikan proses aplikasi dan buka semula kamera. Tema Standard dan kedudukan tengah kanan dipulihkan.
5. Semasa rakaman, pemilihan tema/reset/seretan dikunci. Pilihan setiap sesi disimpan dalam metadata dan dihantar kepada eksport Media3.
6. Tiada exception AndroidRuntime semasa semakan.

Ujian automatik turut mengesahkan koordinat dihadkan dalam julat, nilai rosak menggunakan fallback, seretan berbilang event sebelum satu frame tidak kehilangan jarak, reset paparan, fon besar pada skrin kecil, tetapan selepas membuka semula skrin, metadata eksport selepas retry, dan pembacaan metadata lama tanpa tetapan paparan.

Kamera sintetik emulator digunakan, bukan kamera hos. Telefon fizikal belum diuji. Tema Transparent sengaja tidak mempunyai latar; kontras bergantung pada imej kamera. Tetapan diubah sebelum rakaman, bukan semasa rakaman.

APK: `build/releases/pulse-v1.3.0.apk`

SHA-256:

```text
2e79c857cfb35e83eb19c3dd37e6cc05522ad98266e46e7c613931fa9b2260e4
```

Bukti visual:

- [Pratonton Transparent di atas](screenshots/camera-transparent-v1.3.png)
- [Video Transparent yang dieksport](screenshots/video-transparent-v1.3.png)
- [Pratonton Standard di tengah](screenshots/camera-standard-v1.3.png)
- [Video Standard yang dieksport](screenshots/video-standard-v1.3.png)

Rujukan pelaksanaan native: [Media3 StaticOverlaySettings](https://developer.android.com/reference/androidx/media3/effect/StaticOverlaySettings.Builder).

---

# Rekod terdahulu: 1.2.0+3

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
