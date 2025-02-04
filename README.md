# CanteenAppV1

CanteenAppV1 is a Flutter application designed to manage canteen operations, including user registration, student and stall management, and order tracking. The app integrates with Firebase for authentication and Supabase for database operations.

## Features

- User registration and authentication
- Profile management for students and stall owners
- Order management and tracking
- Integration with Firebase and Supabase

## Getting Started

### Prerequisites

- Flutter SDK: [Install Flutter](https://flutter.dev/docs/get-started/install)
- Firebase account: [Create a Firebase project](https://firebase.google.com/)
- Supabase account: [Create a Supabase project](https://supabase.io/)

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/your-username/CanteenAppV1.git
   cd CanteenAppV1
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Configure Firebase:

   - Follow the instructions to add Firebase to your Flutter app: [Add Firebase to your Flutter app](https://firebase.google.com/docs/flutter/setup)
   - Place the `google-services.json` file in the `android/app` directory.
   - Place the `GoogleService-Info.plist` file in the `ios/Runner` directory.

4. Configure Supabase:

   - Create a `.env` file in the root directory and add your Supabase URL and API key:

     ```env
     SUPABASE_URL=https://your-supabase-url.supabase.co
     SUPABASE_API_KEY=your-supabase-api-key
     ```

### Running the App

1. Run the app on an emulator or physical device:

   ```bash
   flutter run
   ```

## Usage

### User Registration

- Users can register as either students or stall owners.
- After registration, users need to complete their profile information.

### Profile Management

- Students can update their personal information, including name, address, and phone number.
- Stall owners can manage their stall information, including name, owner name, phone number, and description.

### Order Management

- Stall owners can view and manage active orders.
- Orders can be tracked and updated as needed.

## Contributing

Contributions are welcome! Please follow these steps to contribute:

1. Fork the repository.
2. Create a new branch: `git checkout -b feature/your-feature-name`
3. Make your changes and commit them: `git commit -m 'Add some feature'`
4. Push to the branch: `git push origin feature/your-feature-name`
5. Open a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgements

- [Flutter](https://flutter.dev/)
- [Firebase](https://firebase.google.com/)
- [Supabase](https://supabase.io/)