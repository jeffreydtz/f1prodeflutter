# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter application for Formula 1 betting/predictions called "F1 Prode". Users can:
- Register and authenticate
- Create/join private tournaments 
- Place bets (pole position, top 10, DNF) for each F1 race
- View statistics and tournament rankings
- Receive push notifications about bet closures and results

## Common Commands

### Development
- `flutter pub get` - Install dependencies
- `flutter run` - Run the app (Android/iOS emulators or physical devices)
- `flutter run -d chrome` - Run for web
- `flutter analyze` - Run static analysis
- `flutter test` - Run tests

### Build
- `flutter build apk` - Build APK for Android
- `flutter build web` - Build for web deployment

## Architecture

### Core Structure
```
lib/
├── main.dart               # Entry point, routing, app initialization
├── screens/                # UI screens organized by feature
├── services/
│   └── api_service.dart    # Singleton service for all backend communication
├── models/                 # Data models (User, Race, Tournament, BetResult, etc.)
├── widgets/                # Reusable UI components
├── theme/                  # App theming (F1 dark theme)
└── utils/                  # Helper utilities (logger, image picker)
```

### Key Components

**ApiService** (`lib/services/api_service.dart`):
- Singleton service managing all backend communication
- Handles JWT authentication with automatic token refresh
- Backend URL: `https://f1prodedjango.vercel.app/api`
- Implements request caching and retry logic
- Methods for user auth, races, bets, tournaments, etc.

**Main App Flow** (`lib/main.dart`):
- Uses MaterialApp with named routes
- Dark theme (F1 themed)
- Custom checkered flag transition animation
- Conditional web imports for URL strategy

**Screen Organization**:
- Authentication: `login_screen.dart`, `register_screen.dart`, `forgot_password_screen.dart`
- Main app: `home_screen.dart`, `tournaments_screen.dart`, `bet_screen.dart`, `results_screen.dart`
- User management: `profile_screen.dart`, `edit_profile_screen.dart`

**Models**:
- All models have `fromJson()` constructors for API deserialization
- Key models: `User`, `Race`, `Tournament`, `BetResult`, `Sanction`

### Authentication Flow
1. App initializes through `SplashScreen`
2. Checks for stored JWT tokens
3. Automatically refreshes expired tokens
4. Routes to appropriate screen based on auth state

### State Management
- No external state management library used
- State handled through StatefulWidget and ApiService singleton
- User data cached in ApiService and SharedPreferences

### Backend Integration
- Django REST API backend
- JWT authentication
- Comprehensive error handling and retry logic
- Automatic token refresh
- Request caching for performance

### Dependencies
Key packages:
- `http` - API calls
- `shared_preferences` - Local storage
- `jwt_decoder` - Token parsing
- `image_picker` - Avatar/profile images
- `permission_handler` - File permissions
- `dropdown_search` - Enhanced dropdowns
- `intl` - Internationalization

### Testing
Uses standard Flutter testing framework (`flutter_test`).