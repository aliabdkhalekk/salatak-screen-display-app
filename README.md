# Salatak Smart Display

Fullscreen Flutter application for Android TV and large-screen Android APK deployments. The app is offline-first and focuses on prayer times, Hijri date, context-aware Islamic reminders, post-prayer sequences, Friday mode, and integrated Nawawi hadith rotation.

## Features

- Local prayer times calculation with selectable city and method
- Countdown to the next prayer with highlighted prayer row
- Local Hijri date with manual offset and optional online sync
- Dynamic content engine with:
  - before-prayer reminders
  - prayer-specific content in the final 20 minutes
  - post-prayer sequence: dhikr -> sunnah -> Nawawi hadith
  - Friday-focused reminders with occasional Nawawi blending
- Offline local JSON assets for adhkar, Sunnah reminders, general hadith, and Nawawi hadith
- Android TV-friendly fullscreen dashboard and settings screen

## Project Structure

```text
lib/
  core/
  features/
    content_engine/
    dashboard/
    friday/
    hijri/
    nawawi/
    prayer/
    settings/
assets/json/
android/
```

## Build Instructions

1. Install Flutter stable and Android SDK on the build machine.
2. From the project root run:

```bash
flutter pub get
flutter build apk --release
```

3. For Android TV deployment, ensure the target device is configured for landscape fullscreen use.

## Build Without Installing Flutter Locally

If you do not want to install Flutter SDK or Android Studio on your computer, use the GitHub Actions workflow in [.github/workflows/build-apk.yml](.github/workflows/build-apk.yml).

1. Push this project to a GitHub repository.
2. Open the repository `Actions` tab.
3. Run the `Build Android APK` workflow manually, or push to `main` or `master`.
4. When the workflow finishes, download the `salatak-smart-display-release-apk` artifact.
5. Install the downloaded `app-release.apk` on your Android device or Android TV.

This build is suitable for direct device installation and testing. The Android project currently uses the debug signing key for release builds, so it is not intended for Play Store publishing without adding a proper signing configuration.

## Laptop Preview In Browser

If you want to inspect the UI on your laptop without installing Flutter locally, use the GitHub Pages preview workflow in [.github/workflows/deploy-web-preview.yml](.github/workflows/deploy-web-preview.yml).

1. Push this project to GitHub.
2. In the repository settings, open `Pages` and set the source to `GitHub Actions`.
3. Open the `Actions` tab.
4. Run the `Deploy Web Preview` workflow manually, or push to `main` or `master`.
5. When the workflow finishes, open the deployed GitHub Pages URL on your laptop.

The preview is wrapped in a centered 16:9 frame so the layout is easier to inspect on desktop screens. This is the closest no-install option to an emulator. It is useful for visual verification, but it is not a replacement for final testing on a real Android device or Android TV.

## Notes

- The project is designed to keep working with no internet connection.
- Online sync is optional and only enhances Hijri accuracy and remote content overrides when endpoints are configured.
- Remote content sync can be enabled by setting `remoteContentBundleUrl` in `lib/core/config/app_config.dart`.
- The optional remote bundle may expose either a flat `items` array or grouped keys such as `hadith_general`, `adhkar`, `friday_content`, `sunnah`, and `nawawi`.
- Nawawi hadiths are integrated into the dynamic rotation and post-prayer sequence, not only the library screen.
