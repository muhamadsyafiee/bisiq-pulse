# Project delivery workflow

The user has explicitly requested that every completed change to this project
be committed, pushed to GitHub, and delivered with an updated APK and changelog.
This is standing authorization for that workflow; do not ask for confirmation
again for routine commits, pushes, release tags, or APK release uploads.

Repository: https://github.com/muhamadsyafiee/bisiq-pulse

For each completed application change:

1. Increment the version and Android build number in `pubspec.yaml`. Use a new
   version for each release; never replace a published version or its APK.
2. Add a dated entry to `CHANGELOG.md` describing user-visible additions,
   fixes, and any relevant limitations. Keep README and verification notes
   consistent with the delivered version.
3. Format changed Dart files, run `flutter analyze` and relevant tests, then
   build `flutter build apk --release`. Resolve failures before publishing.
   Reuse successful verification and a matching APK from the same change when
   only delivery documentation has changed since the build.
4. Commit the source, tests, documentation, and changelog. Exclude build output,
   SDK caches, local configuration, signing keys, and credentials from Git.
5. Push the commit to the working branch on `origin`, without force-pushing.
   Publish releases from `main` unless the user specifies another branch.
6. Tag the release `v<version>` at the delivered commit and push the tag.
   Create a GitHub Release with notes from that version's changelog; upload
   the matching APK as `pulse-v<version>.apk` and its SHA-256 checksum.
7. Verify the remote commit, tag, release, and uploaded assets. Return the
   release/download links and a concise summary of the completed checks.

APK signing currently uses the local Android debug key for sideload testing.
State this in release notes until a production signing configuration is added.
Do not commit the keystore or change signing identity without considering
compatibility with installed copies.

On this machine Flutter is available at
`/Users/aiagent/.local/share/flutter/bin/flutter`.
