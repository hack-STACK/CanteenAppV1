# Canteen Management App

A Flutter application for managing canteen operations with Firebase and Supabase integration.

## Setup Instructions

1. **Environment Variables**
   Create a `.env` file in the root directory with the following variables:
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

2. **Firebase Setup**
   - Ensure you have Firebase configuration files:
     - For Android: `google-services.json`
     - For iOS: `GoogleService-Info.plist`
   - Follow Firebase setup instructions in the Firebase console

3. **Dependencies**
   Run the following command to install dependencies:
   ```bash
   flutter pub get
   ```

## Features

- User Authentication
- Role-based Access Control (Student/Admin)
- Theme Customization
- Restaurant Management
- Firebase App Check Integration
- Supabase Data Management

## Tech Stack

- Flutter
- Firebase
- Supabase
- Provider State Management

## Development

To run the project in development mode:
```bash
flutter run
```

## Building for Production

```bash
flutter build apk --release  # For Android
flutter build ios --release  # For iOS
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request
