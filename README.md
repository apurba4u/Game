# 🎮 GameHub – Multiplayer & Single-Player Gaming Platform

## 📖 Description

GameHub is a modern Flutter-based gaming platform that combines both single-player and peer-to-peer multiplayer games in one application. The project features a cyber-themed UI, secure authentication, real-time networking, player profiles, leaderboards, and multiple custom-built games developed using Flutter's CustomPainter and animation framework.

The application supports automatic multiplayer discovery over local networks and falls back to Supabase Realtime channels for web platforms, providing a seamless cross-platform gaming experience.

---

## 🌐 Live Project

> ⚠️ **No live demo is currently available.**
>
> This project was developed locally as a Flutter application and has not been deployed.

---

# 🚀 Technologies Used

### Framework

- Flutter
- Dart

### State Management

- Riverpod / Provider

### Backend

- Supabase

### Database

- Supabase PostgreSQL

### Authentication

- Supabase Authentication

### Networking

- UDP Broadcast
- UDP Multicast
- Supabase Realtime Channels
- Socket Communication

### Graphics & Animation

- CustomPainter
- AnimationController
- Canvas API

---

# 📌 Project Overview

GameHub is designed as an all-in-one gaming platform where users can enjoy multiple arcade-style games while interacting with other players through real-time multiplayer functionality.

The application includes secure authentication, player profiles, leaderboards, and advanced networking features. Multiplayer synchronization is achieved using host-authoritative architecture with client-side interpolation, ensuring smooth gameplay and minimizing latency.

---

# ✨ Core Features

## 👤 User Authentication

- Secure sign up and login
- Password strength validation
- Supabase authentication
- User profile management

---

## 🎮 Multiple Games

- Neon Checkers
- Highway Overdrive
- Traffic Dodger
- Space Shooter
- Endless Runner
- Node Slicer

---

## 🌐 Multiplayer Support

- Peer-to-peer multiplayer
- UDP broadcast discovery
- UDP multicast support
- Automatic room discovery
- Supabase Realtime fallback for web
- Host-authoritative synchronization
- Smooth client interpolation

---

## 📊 Dashboard

- Player statistics
- Leaderboard
- User profile
- Game progress
- Achievement tracking

---

## 🎨 UI Features

- Cyberpunk-inspired interface
- Smooth animations
- Responsive layouts
- Custom game rendering
- High-performance graphics

---

# 📦 Dependencies

### Core Packages

- flutter
- flutter_riverpod / provider
- supabase_flutter
- shared_preferences
- flutter_animate
- google_fonts
- flutter_svg
- intl

### Networking

- dart:io
- UDP Socket APIs
- Supabase Realtime

### Graphics

- CustomPainter
- AnimationController
- Canvas

---

# ⚙️ Run Locally

## 1. Clone the repository

```bash
git clone https://github.com/your-username/gamehub.git
```

## 2. Navigate to the project

```bash
cd gamehub
```

## 3. Install dependencies

```bash
flutter pub get
```

## 4. Configure Supabase

Create a `.env` file (or update your configuration) with your Supabase credentials.

Example:

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
```

## 5. Run the project

```bash
flutter run
```

---

# 📂 Project Structure

```
lib/
│
├── core/
│   ├── app_router.dart
│   ├── app_theme.dart
│   └── base_game_controller.dart
│
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── profile/
│   └── games/
│
└── main.dart
```

---

# 🕹️ Game Modules

- Neon Checkers
- Highway Overdrive
- Traffic Dodger
- Space Shooter
- Endless Runner
- Node Slicer

Each game is built with its own gameplay mechanics, animations, collision detection, and scoring system using Flutter's rendering engine.

---

# 🔒 Security Features

- Secure authentication
- Password strength validation
- Protected user sessions
- Secure Supabase integration
- Input validation

---

# 🌟 Highlights

- Multiple arcade games in one application
- Real-time multiplayer architecture
- Cross-platform networking support
- Custom game engine using Flutter
- Responsive cyber-themed UI
- Smooth animations and high-performance rendering

---

# 🔗 Resources

### Repository

https://github.com/your-username/gamehub

> **Note:** There is currently **no live deployment** available for this project.

---

# 📝 Notes

- This project currently contains **only one commit** in the public GitHub repository.
- Due to an issue during development, the remaining local commit history was **not pushed** to the remote repository.
- The current repository still contains the complete source code of the project.

---

# 📄 License

This project was developed for learning, portfolio, and demonstration purposes.
