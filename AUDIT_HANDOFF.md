# Mobile Capstone audit — 2026-10-25

Status: PARTIAL. Full report and raw logs: `D:\Doan\audit\mobile-2026-10-25\REPORT.md`.

Scope: 14 resident FRs and Mobile-related NFRs from supplied Capstone document; local isolated backend only. Preserve pre-existing uncommitted changes. No business/API implementation was changed by this audit.

Added:
- `audit_tests/capstone_requirements_test.dart`: 8 spec assertions, 3 passed / 5 failed.
- `audit_tests/provisioning_requirements_test.dart`: 2 spec assertions, both failed because success callbacks fire without hardware ACK.
- `integration_test/local_mobile_test.dart`: real-local-HTTP Android read smoke; explicit local fixture inputs required, no production fallback. Not executed against a backend yet.
- `integration_test/provisioning_audit_test.dart`: Android wrapper for the provisioning assertions.
- Flutter SDK `integration_test` dev dependency and resolved lockfile entries.

Verified:
- `flutter test --coverage --reporter expanded`: 184 passed / 7 failed (existing tests).
- `flutter test audit_tests/capstone_requirements_test.dart --reporter expanded`: 3 passed / 5 failed.
- `flutter test audit_tests/provisioning_requirements_test.dart --reporter expanded`: 0 passed / 2 failed.
- `dart analyze integration_test/local_mobile_test.dart audit_tests`: no issues.
- `flutter test integration_test/provisioning_audit_test.dart -d emulator-5554 --dart-define=API_BASE_URL=http://127.0.0.1:3301/api/v1 --reporter expanded`: Android retry completed, 0 passed / 2 failed on expected missing-ACK assertions. APK installation needed one manual non-streaming retry; see environment report.
- Logic line coverage (models/providers/services represented in baseline LCOV): 1109/1924 = 57.64%.

Known defects: 60-second cancellation vs required 120 seconds; missing/malformed battery shown as 100%; empty product image array crashes order parsing; BLE/Wi-Fi screen success is timer-driven. Missing resident UI entry points for rental, rename and disable; see report for evidence and limits.

Remaining: local database/backend unavailable due Docker startup failure; no fixtures seeded, no API p95/FCM SLA/BOLA or eight-flow mutation E2E run. User started Android Small Phone emulator (`emulator-5554`); provisioning assertions ran and reproduced both failures. No physical ESP32.

Next: recover Docker runtime, construct isolated backend fixtures, run local smoke and implement mutation E2E; fix business defects only with separate authorized scope. Do not replace spec assertions with today's behavior to make tests green.

## 2026-10-25 — Resident button rename implemented

User authorized adding the missing rename action after the audit.
- Device overview now offers “Đổi tên” beneath the name; the dialog pre-fills the current name, trims input, rejects blank/over-100-character names and disables actions while saving.
- `DeviceProvider.renameDevice` sends only `buttonName` to the existing customer-config endpoint. Shared state changes only after the server returns a saved name; errors leave the old name and draft intact for retry. Other device configuration stays unchanged.
- Added `lib/widgets/modals/rename_device_dialog.dart` and `test/rename_device_test.dart`; updated device provider/detail screen without replacing pre-existing edits.
- Verified: `flutter test test/rename_device_test.dart test/device_settings_flow_test.dart test/device_settings_entry_test.dart --reporter expanded` — 12/12 PASS. Log: `D:\Doan\audit\mobile-2026-10-25\rename-device-tests.log`.
- Verification uses mock HTTP; live backend persistence and Android E2E rename are not yet verified. The earlier audit's missing rename UI finding is now addressed in code; other audit findings remain unchanged.
- Static verification: `dart analyze lib/widgets/modals/rename_device_dialog.dart lib/screens/device_detail_screen.dart lib/providers/device_provider.dart test/rename_device_test.dart` — no issues found.
