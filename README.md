# PULSE — Workout Timer

Aplikasi Android Flutter untuk latihan interval, dengan antaramuka gelap dalam Bahasa Melayu. Semua bunyi tersedia secara luar talian; tiada akaun atau sambungan internet diperlukan.

## Jalankan

Keperluan: Flutter stabil **3.47.6** (versi yang digunakan untuk projek ini), Android SDK, JDK 17 atau lebih baharu, dan telefon/emulator **Android 7.0 / API 24+**. Gunakan versi Gradle/AGP daripada projek ini.

```bash
# Jika menggunakan SDK yang disediakan pada mesin ini:
export PATH="$HOME/.local/share/flutter/bin:$PATH"

cd /Users/aiagent/Project/gym-timer
flutter pub get
flutter devices
flutter run
```

Untuk pemasangan pada mesin lain, ikuti [panduan Flutter Android rasmi](https://docs.flutter.dev/platform-integration/android/setup), kemudian jalankan arahan daripada direktori projek anda.

## Bina APK

```bash
flutter analyze
flutter test
flutter build apk --release
```

APK universal: `build/app/outputs/flutter-apk/app-release.apk`.

Untuk APK lebih kecil bagi setiap seni bina:

```bash
flutter build apk --release --split-per-abi
```

Pasang pada telefon/emulator yang disambungkan:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Konfigurasi lalai menggunakan debug signing bagi APK release untuk pemasangan dan ujian tempatan. Sebelum edaran rasmi/Play Store, konfigurasi kunci release milik anda mengikut [panduan signing Flutter](https://docs.flutter.dev/deployment/android#sign-the-app). Jangan komit fail keystore atau kata laluan.

## Fungsi

- Empat gerakan: Pushup, Diamond Pushup, Widearm Pushup dan Chest Squeeze.
- Setiap gerakan: 20 saat senaman dan 10 saat rehat antara gerakan. Jumlah sesi: **1 minit 50 saat**. Tiada rehat selepas gerakan terakhir.
- Ring `CustomPainter` berkurang secara lancar: hijau untuk senaman, oren untuk rehat. Status juga dilabel dengan teks.
- Nama gerakan semasa, arahan ringkas, gerakan seterusnya dan pelan latihan.
- **MULA LATIHAN**, **JEDA / SAMBUNG**, **SEMULA**, **LANGKAU**.
- Langkau ketika senaman melangkau gerakan tersebut bersama rehatnya. Langkau ketika rehat terus ke gerakan seterusnya. Keadaan jeda dikekalkan.
- Bunyi pendek pada 3, 2, 1; nada menaik ketika mula, nada menurun ketika rehat, melodi ketika tamat. Butang bunyi membolehkan mod senyap.
- Dialog **Workout Finished** membezakan jumlah gerakan selesai dan dilangkau.
- `wakelock_plus` mengekalkan skrin aktif hanya semasa pemasa berjalan di hadapan. Skrin dilepaskan semasa jeda, reset, tamat atau aplikasi berada di latar belakang.
- Tiada gambar/GIF diperlukan untuk preset; medan `assetPath` tersedia untuk aset pilihan dan mempunyai fallback jika aset gagal dimuatkan.

## Tingkah laku latar belakang

Pemasa menggunakan masa berlalu (`Stopwatch`) dan tarikh tamat relatif, bukannya menolak satu saat bagi setiap callback. Apabila aplikasi kembali ke hadapan, semua interval yang telah berlalu diselaraskan sekali gus tanpa memainkan beep lama berulang kali. Sesi dijeda kekal dijeda.

Aplikasi ini **tidak menggunakan Android foreground service**. Bunyi dimainkan ketika aplikasi di hadapan sahaja; proses tidak dijamin kekal hidup ketika Android menggantung atau menamatkannya. Sesi tidak dipulihkan selepas proses ditamatkan. `wakelock_plus` ialah kunci skrin, bukan perkhidmatan latar belakang atau CPU wakelock ([dokumentasi pakej](https://pub.dev/packages/wakelock_plus)).

## Struktur

```text
lib/
  main.dart                       # Tema dan titik mula aplikasi
  data/workout_presets.dart       # Senarai gerakan lalai
  models/exercise.dart            # Nama, masa senaman/rehat, aset pilihan
  screens/workout_screen.dart     # UI, lifecycle, dialog, kawalan
  services/workout_controller.dart # Mesin keadaan dan pengiraan masa
  services/workout_feedback.dart  # audioplayers dan wakelock_plus
  theme/app_theme.dart            # Warna dan gaya komponen
  widgets/
    timer_ring.dart               # Ring tersuai, tiada percent_indicator
    exercise_tile.dart            # Baris senarai gerakan
assets/audio/                     # Empat WAV asli, disertakan dalam APK
scripts/generate_audio.py         # Jana semula WAV tanpa pakej tambahan
test/                             # Ujian logik dan interaksi widget
android/                          # Projek Gradle, manifest, ikon dan splash
```

Ubah senarai atau tempoh latihan dalam `lib/data/workout_presets.dart`. Durasi senaman mesti lebih daripada sifar; durasi rehat boleh sifar. Senarai mesti mempunyai sekurang-kurangnya satu gerakan.

Untuk gambar/GIF, tambah fail ke `assets/exercises/`, daftar direktori tersebut di bawah `flutter.assets` dalam `pubspec.yaml`, kemudian isi `assetPath`, contohnya `assets/exercises/pushup.gif`.

## Pengesahan

Ujian meliputi urutan workout/rest/finished, kira detik 3–2–1, pause/resume separa saat, callback tertangguh merentasi beberapa interval, langkau semasa senaman/rehat/jeda, reset, durasi rehat sifar, satu gerakan, input kosong, butang UI, mute, dialog penamat, pelepasan wakelock serta skrin kecil dengan fon besar.

Bunyi WAV dijana sendiri melalui `python3 scripts/generate_audio.py` dan boleh digunakan bersama projek ini. Pakej dikunci melalui `pubspec.lock`.

Binaan ini telah lulus 13 ujian dan analisis statik, serta berjaya dipasang dan diuji pada emulator Android API 36. Lihat [rekod pengesahan](docs/VERIFICATION.md) dan [tangkapan skrin](docs/screenshots/ready.png).
