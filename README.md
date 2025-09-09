# satwik_diet_app

 personalized Ayurvedic meal planning, with meal plans, food explorer and local reminders (Android).  
This repo contains the Flutter app and a small FastAPI backend used for generating 30-day meal plans.

---

## Getting Started

APK OF THE APP IS PROVIDED JUST DOWNLOAD AND USE IT 

This project is a starting point for a Flutter application.

---

##SnapShots

![WhatsApp Image 2025-09-09 at 08 17 20_18ab6180](https://github.com/user-attachments/assets/468e7137-336c-48de-92b5-2350236fbb6e)
![WhatsApp Image 2025-09-09 at 08 17 17_10b929ee](https://github.com/user-attachments/assets/87960cba-b621-4435-a7fd-621e24c67f71)
![WhatsApp Image 2025-09-09 at 08 17 18_fff89bcc](https://github.com/user-attachments/assets/f89173cc-d871-4af0-a859-0f4f79fd1ab8)
![WhatsApp Image 2025-09-09 at 08 17 18_9382b617](https://github.com/user-attachments/assets/1c4b5df2-372f-4d17-963d-2a8ea05a8128)
![WhatsApp Image 2025-09-09 at 08 17 20_8eb2944a](https://github.com/user-attachments/assets/4a4feb38-e44a-405c-ae5a-590f10f65892)

---

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

### Prerequisites
- Flutter SDK (>= 3.0)
- Android SDK (compileSdk 34/35 depending on plugin warnings)
- Firebase project (credentials)
- Python environment (if running backend locally)
