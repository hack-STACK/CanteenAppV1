# 🍽️ Canteen Management App

A powerful and user-friendly Flutter application for managing canteen operations, integrated with **Firebase** and **Supabase** for seamless authentication, data management, and cloud services.

## 🚀 Features

✅ **User Authentication** (Firebase Auth)
✅ **Role-based Access Control** (Student/Admin)
✅ **Theme Customization** (Dark & Light Mode)
✅ **Restaurant & Menu Management**
✅ **Firebase App Check Integration** (Enhanced Security)
✅ **Supabase for Real-time Data Management**
✅ **Responsive & Optimized UI**

---

## 🛠️ Setup Instructions

### 1️⃣ Environment Variables
Create a `.env` file in the root directory with the following variables:
```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 2️⃣ Firebase Setup
To enable Firebase services, ensure you have the required configuration files:
- **Android** → `android/app/google-services.json`
- **iOS** → `ios/Runner/GoogleService-Info.plist`

Follow Firebase setup instructions from the **[Firebase Console](https://console.firebase.google.com/)**.

### 3️⃣ Install Dependencies
Run the following command to install all required packages:
```bash
flutter pub get
```

---

## 💻 Development & Deployment

### 🔹 Run the App in Development Mode
```bash
flutter run
```

### 🔹 Build for Production
For Android:
```bash
flutter build apk --release
```
For iOS:
```bash
flutter build ios --release
```

---

## 🏗️ Tech Stack

🛠️ **Flutter** - Frontend framework  
🔥 **Firebase** - Authentication & Security  
📦 **Supabase** - Database & Storage  
🔧 **Provider** - State Management  
🎨 **Customizable Themes** - Dark/Light Mode  

---

## 🤝 Contributing

We welcome contributions! To get started:
1. **Fork** the repository
2. **Create** a new feature branch
3. **Commit** your changes
4. **Push** to the branch
5. **Create** a Pull Request

💡 *Suggestions & bug reports are always appreciated!*

---

## 📜 License
This project is licensed under the **MIT License**. Feel free to use and modify it for your needs.

🚀 **Happy Coding!** 🎉

