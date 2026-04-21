# Maize Doctor — Flutter App

AI-powered maize leaf disease classifier mobile app built with Flutter + Firebase + PyTorch.

---

## Features

- Landing page with app overview
- Email + Google authentication (Firebase Auth)
- Forgot password flow
- Camera and gallery image capture
- Online mode — calls Kaggle/ngrok Flask API
- Offline mode — runs TFLite model on-device automatically
- Input validation — rejects non-leaf images
- Full results screen with confidence scores
- Scan history saved per user
- Disease guide with expandable cards
- Wikipedia disease info (in-app WebView)
- Profile with scan statistics

---

## Project Structure

```
lib/
├── main.dart
├── router.dart
├── constants/
│   ├── theme.dart
│   └── diseases.dart
├── models/
│   └── models.dart
├── providers/
│   └── auth_provider.dart
├── services/
│   ├── auth_service.dart
│   ├── api_service.dart
│   ├── inference_service.dart
│   ├── connectivity_service.dart
│   └── storage_service.dart
├── screens/
│   ├── auth/
│   │   ├── landing_screen.dart
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── forgot_password_screen.dart
│   └── app/
│       ├── main_shell.dart
│       ├── home_tab.dart
│       ├── preview_screen.dart
│       ├── results_screen.dart
│       ├── history_tab.dart
│       ├── guide_tab.dart
│       ├── profile_tab.dart
│       └── disease_info_screen.dart
└── widgets/
    └── confidence_bar.dart
```

---

## Setup Instructions

### Step 1 — Flutter setup

```bash
flutter pub get
```

### Step 2 — Firebase setup

1. Go to console.firebase.google.com
2. Create a new project called "maize-doctor"
3. Add an Android app:
   - Package name: `com.example.maize_doctor`
   - Download `google-services.json`
   - Place it in: `android/app/google-services.json`
4. Enable Authentication → Sign-in methods:
   - Email/Password → Enable
   - Google → Enable

### Step 3 — Add TFLite model

Convert your PyTorch model to TFLite (see Kaggle notebook) then place it at:
```
assets/models/maize_model.tflite
```

### Step 4 — Update API URL

Open `lib/services/api_service.dart` and update:
```dart
static const String baseUrl = 'https://YOUR-NGROK-URL.ngrok-free.app';
```

### Step 5 — Run the app

```bash
flutter run
```

---

## API Contract

**POST** `/predict`

```json
Request:  { "image": "<base64 string>" }
Response: { "disease": "northern_leaf_blight", "confidence": 0.92, "alternatives": [...] }
```

**GET** `/health` → `{ "status": "ok" }`

---

## Class Labels

```
northern_leaf_blight → Northern Leaf Blight
gray_leaf_spot       → Gray Leaf Spot
common_rust          → Common Rust
healthy              → Healthy
```

---

## Tech Stack

| Layer       | Technology                        |
|-------------|-----------------------------------|
| Frontend    | Flutter (Dart)                    |
| Auth        | Firebase Auth + Google Sign-In    |
| State       | Provider                          |
| Navigation  | GoRouter                          |
| HTTP        | Dio                               |
| On-device   | TFLite Flutter                    |
| Storage     | SharedPreferences                 |
| Fonts       | Google Fonts (DM Sans)            |
| ML Backend  | PyTorch + Flask + ngrok (Kaggle)  |
