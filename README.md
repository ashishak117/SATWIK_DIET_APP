# satwik_diet_app

 personalized Ayurvedic meal planning, with meal plans, food explorer and local reminders (Android).  
This repo contains the Flutter app and a small FastAPI backend used for generating 30-day meal plans.


## Getting Started

APK OF THE APP IS PROVIDED JUST DOWNLOAD AND USE IT 

This project is a starting point for a Flutter application.

## Features

- Google Sign-in (Firebase Auth)
- User profile & preferences (Firestore)
- 30-day meal plan generator (backend API)
- Food Explorer: search Ayurvedic properties for Indian foods
- Local notifications & hydration/meal reminders (flutter_local_notifications)
- Resync reminders after device reboot (Android BootReceiver + MethodChannel)
- Light / Dark theme with brand gradient
- Clean UI: grid dashboard, card components, animated transitions

---

## Architecture & Tech Stack

- **Mobile**: Flutter (Material3, Provider)
- **Backend**: FastAPI (Python) — meal plan generation (hosted separately)
- **Database / Auth**: Firebase Firestore & Firebase Auth
- **Local notifications**: flutter_local_notifications + timezone
- **CI / Hosting**: (Optional) GitHub Actions to build APK; Render/Heroku for backend

---

## Getting started (local dev)

### Prerequisites
- Flutter SDK (>= 3.0)
- Android SDK (compileSdk 34/35 depending on plugin warnings)
- Firebase project (credentials)
- Python environment (if running backend locally)
