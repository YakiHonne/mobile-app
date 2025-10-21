# YakiHonne Mobile App

YakiHonne is a decentralized social platform built on the Nostr protocol, providing users with a censorship-resistant and privacy-focused social media experience.

## 📱 About

YakiHonne is a cross-platform mobile application built with Flutter that enables users to:

- Connect to the Nostr decentralized social network
- Share content, articles, and media
- Engage with a global community
- Maintain privacy and data ownership
- Experience a modern, responsive UI across all devices

**Current Version:** 1.9.1+158

## ✨ Features

- **Nostr Protocol Integration**: Built on the decentralized Nostr protocol for censorship-resistant communication
- **Multi-Platform Support**: Android, iOS, Web, Windows, macOS, and Linux
- **Rich Media Support**: Images, videos, GIFs, and audio playback
- **Real-time Updates**: Live feed updates and notifications
- **Secure Storage**: Encrypted local storage for sensitive data
- **Multi-Language Support**: Internationalization with automatic translation
- **Dark/Light Theme**: Customizable themes for user preference
- **Lightning Network**: Bitcoin Lightning integration for tipping and payments
- **QR Code Scanner**: Easy profile and content sharing
- **Markdown Support**: Rich text formatting for posts and articles
- **AI Integration**: ChatGPT integration for enhanced features
- **Push Notifications**: Stay updated with UnifiedPush support

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: >= 3.0.1 < 4.0.0
- **Dart SDK**: Included with Flutter
- **IDE**: Android Studio, VS Code, or IntelliJ IDEA
- **Platform-specific requirements**:
  - Android: Android Studio with Android SDK
  - iOS: Xcode (macOS only)
  - Web: Chrome browser
  - Desktop: Platform-specific build tools

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/YakiHonne/mobile-app.git
   cd mobile-app
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Set up environment variables**

   - Create a `.env` file in the root directory
   - Add required API keys and configuration (see `.env.example` if available)

4. **Generate launcher icons**

   ```bash
   flutter pub run flutter_launcher_icons
   ```

5. **Generate native splash screens**
   ```bash
   flutter pub run flutter_native_splash:create
   ```

### Running the App

**Development mode:**

```bash
flutter run
```

**Run on specific platform:**

```bash
flutter run -d android
flutter run -d ios
flutter run -d chrome
flutter run -d windows
flutter run -d macos
flutter run -d linux
```

**Build for production:**

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Desktop
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

## 🏗️ Project Structure

```
lib/
├── logic/              # Business logic (Cubits/Blocs)
├── routes/             # App routing configuration
├── utils/              # Utility functions and helpers
├── views/              # UI components and screens
│   └── widgets/        # Reusable widgets
├── initializers.dart   # App initialization logic
└── main.dart           # App entry point
```

## 🔧 Key Dependencies

- **State Management**: `flutter_bloc`, `flutter_hooks`
- **Networking**: `dio`, `connectivity_plus`
- **Nostr Protocol**: `nostr_core_enhanced`, `amberflutter`
- **UI Components**: `flutter_svg`, `lottie`, `cached_network_image`
- **Media**: `video_player`, `chewie`, `just_audio`, `image_picker`
- **Storage**: `flutter_secure_storage`, `shared_preferences`
- **Localization**: `flutter_localizations`, `slang`
- **Crypto**: `bip340`, `crypto`, `aescryptojs`
- **Error Tracking**: `sentry_flutter`
- **Lightning Network**: `bolt11_decoder`

## 🧪 Testing

Run tests with:

```bash
flutter test
```

## 📦 Build Configuration

### Shorebird (Code Push)

This project uses Shorebird for over-the-air updates. Configuration is in `shorebird.yaml`.

### Sentry (Error Tracking)

Error tracking is configured in `sentry.properties`. Make sure to set up your Sentry DSN.

## 🌍 Localization

The app supports multiple languages using the `slang` package. Configuration is in `slang.yaml`.

To add a new language:

1. Add translation files in the appropriate directory
2. Run code generation: `flutter pub run build_runner build`

## 🎨 Theming

The app uses a custom theme with:

- **Font**: DM Sans (weights: 400-900)
- **Responsive Design**: Breakpoints for mobile, tablet, desktop, and 4K displays
- **Material Design**: Material 3 components

## 🔐 Security

- Secure storage for private keys and sensitive data
- End-to-end encryption for Nostr messages
- No central server storing user data
- User controls their own identity and keys

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Copyright (c) 2025 Yakihonne

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📞 Support

For support, please:

- Open an issue on GitHub
- Visit our website: [yakihonne.com](https://yakihonne.com)
- Join our community on Nostr

## 🙏 Acknowledgments

- Built on the [Nostr Protocol](https://github.com/nostr-protocol/nostr)
- Powered by [Flutter](https://flutter.dev)
- Community-driven and open source

---

**Made with ❤️ by the YakiHonne Team**
