# 🍱 CanteenAppV1

<div align="center">
  <img src="assets/images/app_logo.png" alt="CanteenApp Logo" width="200"/>
  <br>
  <p><strong>A modern Flutter-based canteen management system</strong></p>
</div>

## 🌟 Features

- 🔐 **Secure Authentication**
  - Firebase integration for user management
  - Role-based access control (Student/Stall Owner)

- 👤 **User Management**
  - Student profile management
  - Stall owner dashboard
  - Personal information updates

- 🏪 **Stall Management**
  - Menu management
  - Order tracking
  - Real-time updates

- 📱 **Modern UI/UX**
  - Intuitive interface
  - Responsive design
  - Cross-platform support

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have:

- 📱 Flutter SDK installed ([Install Flutter](https://flutter.dev/docs/get-started/install))
- 🔥 Firebase account ([Create Firebase Project](https://firebase.google.com/))
- 🗄️ Supabase account ([Create Supabase Project](https://supabase.io/))

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/hack-STACK/CanteenAppV1.git
   cd CanteenAppV1
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Add `google-services.json` to `android/app/`
   - Add `GoogleService-Info.plist` to `ios/Runner/`

4. **Setup Supabase**
   ```env
   SUPABASE_URL=your_supabase_url
   SUPABASE_API_KEY=your_api_key
   ```

## 📱 App Structure

```
lib/
├── Models/         # Data models
├── Services/       # Business logic & API services
├── pages/         # UI screens
└── Components/    # Reusable widgets
```

## 🛠️ Built With

- [Flutter](https://flutter.dev/) - UI Framework
- [Firebase](https://firebase.google.com/) - Authentication & Cloud Services
- [Supabase](https://supabase.io/) - Backend Database

## 📸 Screenshots

<div align="center">
  <img src="screenshots/login.png" width="200" alt="Login Screen"/>
  <img src="screenshots/dashboard.png" width="200" alt="Dashboard"/>
  <img src="screenshots/orders.png" width="200" alt="Orders"/>
</div>

## 🤝 Contributing

1. Fork the repo
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter Team
- Firebase
- Supabase
- All contributors

## 📞 Contact

Project Link: [https://github.com/hack-STACK/CanteenAppV1](https://github.com/hack-STACK/CanteenAppV1)

---

<div align="center">
  Made with ❤️ by hack-STACK
</div>