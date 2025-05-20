# 👩‍💼 Women Safety App 🚨

A cross-platform mobile application developed using **Flutter**, **Dart**, and **Firebase**, designed to enhance women's safety by providing emergency SOS alerts, real-time location tracking, complaint submission, and more.

---

## 📱 Features

### 👤 User Features
- **Secure Login/Signup** (Role-based: User/Admin)
- **SOS Alert System**: Instantly send SMS with location to trusted contacts
- **Fake Call Simulation**: Helps divert or avoid dangerous situations
- **Trusted Contacts Management**
- **Live Location Sharing** via Firestore & Google Maps
- **Nearby Police Stations & Hospitals** (Map view)
- **Latest Women's News Feed** via API
- **Online Complaint Submission** with image support
- **Edit Profile** functionality

### 🛠️ Admin Features
- **Admin Dashboard**: Monitor users, complaints, and app activities
- **Emergency Configuration Management** (e.g. helpline numbers, alerts)
- **View/Manage Complaints**

---

## 🧰 Tech Stack

| Category        | Tools/Frameworks                    |
|----------------|-------------------------------------|
| UI Development | Flutter, Dart                       |
| Backend        | Firebase (Firestore, Auth, Storage) |
| Maps & Location| Google Maps SDK, Geolocator         |
| Communication  | SMS Launcher, url_launcher          |
| Others         | Image Picker, Permission Handler    |

---

## 📦 Modules Overview

- `Splash Screen` - Initial branding load
- `Authentication` - Firebase Auth with role-based navigation
- `Home Screen` - Central hub for safety features
- `Trusted Contacts` - Manage emergency contact list
- `Realtime Location` - Track and update live location to Firestore
- `Complaint Form` - Submit complaints with category, image, and description
- `Admin Dashboard` - Complaint review and alert management
- `Notifications` - In-app alert indicators for messages and events

---

## ✅ Advantages

- 🔁 Cross-platform with single codebase
- 📡 Real-time updates with Firestore
- 🔒 Role-based secure access
- 🚀 Fast development using Firebase & Flutter
- 🧭 Intuitive, clean UI/UX

---

## ⚠️ Limitations

- 📶 SMS depends on mobile network availability
- 🔋 Battery consumption from location tracking
- ❌ SOS alert won't work if app is force-closed
- 🍎 iOS support may need permission handling (future scope)
- 📈 Firebase usage limitations (free tier)

---

## 🔍 Use Cases

- Emergency alert system for women's safety
- Crime or harassment complaint submission
- Real-time location tracking and monitoring
- Safety awareness through live news
- Admin panel for organizational or law enforcement use

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK installed
- Firebase project configured
- Android/iOS device or emulator

### Installation

```bash
git clone https://github.com/yourusername/women-safety-app.git
cd women-safety-app
flutter pub get
flutter run
