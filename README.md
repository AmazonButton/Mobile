# SmartOrder Button — Mobile Application

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![BLE ESP32](https://img.shields.io/badge/IoT-ESP32%20BLE%20GATT-0E6BA8)](https://www.espressif.com/)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-10B981)](#getting-started)

**SmartOrder Button Mobile** is the cross-platform Flutter application for the **SmartOrder Button** one-touch IoT ordering ecosystem. It connects physical ESP32 smart buttons, customers, local stores, and administrators in real time over BLE, Wi-Fi 2.4GHz, and REST/WebSocket APIs.

---

## Key Features

### Role-Based Experience (Synced with Web & Backend)
| Role | Capabilities |
|---|---|
| **Customer** | Landing showcase, store & catalog discovery with live discounts, out-of-stock protection, 1-touch smart button ordering, hardware button rental, real-time order tracking & PayOS checkout, eKYC verification, banking & address book |
| **Store Owner / Manager** | Live operations overview (`Pending` / `In Progress` / `Completed`), store product & inventory management (`StoreProductsScreen`), real-time out-of-stock & low-stock alerts, store IoT button inspection & BLE pairing, order status updates |
| **Administrator** | System-wide operations hub, store listing overview, global IoT button inventory & order monitoring |

### Hardware IoT Pairing (ESP32 BLE GATT)
- **Cross-Platform BLE Support:** Native BLE via `flutter_blue_plus` on Android/iOS and Web Bluetooth API bridge on Chrome/Edge.
- **3-Step Pairing Flow:** `1. Identify Button` → `2. Confirm & Configure Wi-Fi 2.4GHz` → `3. Saved on System`.
- **GATT Specification:**
  - **Advertising Name Prefixes:** `BTN`, `SmartOrder`, `SmartButton`, `ESP`, `SOB`
  - **Primary Service UUID:** `0000fff0-0000-1000-8000-00805f9b34fb`
  - **Device Identity Characteristic (`READ`):** `0000fff1-0000-1000-8000-00805f9b34fb` (JSON `{"deviceId":"..."}`)
  - **Wi-Fi Provisioning Characteristic (`WRITE`):** `0000fff2-0000-1000-8000-00805f9b34fb` (UTF-8 `SSID:PASSWORD`)

---

## Project Architecture

```text
lib/
├── main.dart                     # App entry point, Firebase & MultiProvider setup
├── constants/                    # Brand colors, typography & theme tokens
├── models/                       # Strongly-typed models (Device, Order, Stock, Notification...)
├── providers/                    # ChangeNotifier state management (User, Device, Order, Address, Notification)
├── services/                     # REST API clients, Goong maps, Stock cache & BLE GATT bridge
├── screens/                      # Role-aware screens (Home, StoreProducts, Devices, Orders, Profile, Auth, Splash)
├── utils/                        # Input validators & formatting helpers
└── widgets/                      # Reusable UI components, cards & bottom-sheet modals
```

---

## Getting Started

### Prerequisites
- Flutter SDK `>= 3.24` / Dart SDK `>= 3.5`
- Android Studio / Xcode (for native builds) or Chrome/Edge (for Web Bluetooth testing)

### Install Dependencies
```bash
flutter pub get
```

### Run Locally
```bash
# Run on connected Android/iOS device
flutter run

# Run on Chrome (Web)
flutter run -d chrome

# Override Backend API URL if running a local backend
flutter run --dart-define=API_BASE_URL=http://192.168.1.x:3000/api/v1
```

### Production Builds
```bash
# Android APK
flutter build apk --release

# Flutter Web
flutter build web --release
```

### Verification & Testing
```bash
flutter analyze
flutter test
```

---

## Tech Stack
- **Framework:** Flutter & Dart
- **State Management:** Provider (`ChangeNotifier`)
- **Hardware / IoT:** `flutter_blue_plus`, Web Bluetooth JS Interop (`dart:js_interop`), `network_info_plus`
- **Authentication & Push:** JWT Bearer + Refresh Token, Google Sign-In, Firebase Auth & Cloud Messaging (FCM)
- **UI & Motion:** `lucide_icons_flutter`, `flutter_animate`, `shimmer`, `cached_network_image`, `qr_flutter`
