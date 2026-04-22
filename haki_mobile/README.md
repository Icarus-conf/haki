# <div align="center">HAKI Mobile</div>

<div align="center">
  <p align="center">
    <strong>Connect Securely. Communicate Instantly.</strong>
    <br />
    The flagship mobile experience for the HAKI ecosystem, built with Flutter.
  </p>

  <p align="center">
    <a href="#-features">Features</a> •
    <a href="#-tech-stack">Tech Stack</a> •
    <a href="#-getting-started">Getting Started</a> •
    <a href="#-security">Security</a> •
    <a href="#-structure">Structure</a>
  </p>
</div>

---

## 🌟 Overview

**HAKI Mobile** is a feature-rich, high-performance messaging application designed for modern communication needs. By combining cutting-edge security with a fluid, intuitive user interface, HAKI provides a premium chat experience that includes real-time messaging, high-quality audio/video calls, and robust data privacy.

## 🚀 Features

### 🔐 Uncompromised Security
- **End-to-End Encryption (E2EE)**: Powered by RSA and custom cryptographic protocols to ensure your data stays yours.
- **Secure Key Management**: Integration with BIP39 for mnemonic-based identity and PointyCastle for robust encryption.
- **Secure Storage**: Sensitive information is protected using industry-standard encrypted local storage.

### 📞 Premium Communication
- **Real-time Messaging**: Instant, low-latency chat powered by Socket.io.
- **HD Video & Audio Calls**: Crystal-clear calling experience integrated via WebRTC.
- **Voice Messages**: Seamless recording and playback of audio messages.

### 🎨 Rich User Experience
- **Fluid Animations**: Beautifully crafted micro-interactions and animations using Lottie.
- **Modern UI**: A sleek, dark-themed interface built with the Poppins typography system.
- **Media Support**: High-performance image handling with cached network images and gallery integration.

### 📱 Advanced Capabilities
- **QR Connectivity**: Fast contact sharing and secure login via built-in QR scanning and generation.
- **Permissions Management**: Granular control over camera, microphone, and gallery access.
- **Offline Resilience**: Intelligent caching and optimistic UI updates for a smooth experience in any network condition.

## 🛠️ Tech Stack

| Category | Technology |
| :--- | :--- |
| **Framework** | [Flutter](https://flutter.dev/) |
| **Language** | [Dart](https://dart.dev/) |
| **Real-time** | [Socket.io Client](https://pub.dev/packages/socket_io_client) |
| **Encryption** | [Fast RSA](https://pub.dev/packages/fast_rsa) / [Cryptography](https://pub.dev/packages/cryptography) |
| **VoIP/WebRTC** | [Flutter WebRTC](https://pub.dev/packages/flutter_webrtc) |
| **Animations** | [Lottie](https://pub.dev/packages/lottie) |
| **State Mgmt** | [Provider](https://pub.dev/packages/provider) |

## 📦 Getting Started

### Prerequisites
- **Flutter SDK**: `^3.10.4` or higher
- **Dart SDK**: `^3.10.4` or higher
- **Android Studio** or **Xcode** for mobile simulation/builds

### Installation

1. **Clone the Project**
   ```bash
   git clone https://github.com/your-repo/haki-mobile.git
   cd haki-mobile
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Environment**
   Update your API endpoints in the relevant service files (e.g., `lib/services/api_service.dart`).

4. **Run the App**
   ```bash
   flutter run
   ```

## 🛡️ Security Protocol

HAKI Mobile implements a multi-layered security architecture:
1. **Identity**: Keys are generated using BIP39 mnemonics.
2. **Transport**: All WebSocket and HTTP traffic is secured via TLS.
3. **Payload**: Message contents are encrypted client-side before transmission.

## 📁 Project Structure

```text
lib/
├── models/         # Data models & JSON serialization
├── providers/      # State management logic
├── screens/        # UI Pages & Layouts
├── services/       # API, Socket, & WebRTC integration
├── widgets/        # Reusable UI components
└── utils/          # Cryptography & Helper functions
```

---

<div align="center">
  <p>Crafted with precision by <strong>Muhammad Fathy</strong></p>
  <img src="https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Security-E2EE-green?style=flat-square" alt="Security" />
</div>
