# smart_order_button

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

### Goong address suggestions
Copy `goong.example.json` to `goong.local.json`, set your Goong REST API key, then run `./run-local.ps1` (Android emulator) or `flutter run --dart-define-from-file=goong.local.json`. The local configuration is ignored by Git. A full restart is required after changing compile-time configuration. Customer address CRUD also requires the backend `/addresses` endpoints. Distances are straight-line estimates from the selected delivery address.
