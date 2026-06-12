# DevSync: Secure AI Project Collaborator
**Date: April 12, 2026**

## 🌟 Overview
DevSync is a premium, AI-powered platform designed for developers to find high-impact collaborators for open-source and private projects. By leveraging **Google Gemini AI**, the platform moves beyond simple keyword Matching to analyze developer expertise through **GitHub Activity** and skill sets.

## 🚀 Recent Architectural Updates
- **Role-First Onboarding**: Complete UI overhaul replacing generic login screens with a luxurious, glassmorphism role-selector (Developer vs Project Manager).
- **Native OAuth Flow**: Removed Firebase UI in favor of native Google Sign-In and GitHub OAuth token interception via Chrome Custom Tabs.
- **Dedicated Python Backend (FastAPI)**: Successfully spun off heavy processing to a local Python server (`localhost:8000`).
- **Instant Algorithmic GitHub Profiling**: Replaced slow GenAI constraints with a blazing-fast Python algorithmic engine that instantly reads GitHub metadata to dictate Seniority, compute Top Programming Languages, and construct automated professional Bios in milliseconds.

## 🤖 Core AI Implementation (Prompt Engineering)
The platform features a sophisticated AI-driven discovery engine:
- **Expertise Matching**: Uses a refined Gemini-1.5-flash prompt that evaluates a developer's real-world expertise by analyzing their **GitHub Repository activity**, top languages, and public contributions.
- **Feedback-Driven Optimization**: Implements a dedicated **Feedback Loop** where users can rate the accuracy of AI matches. This data is logged to evaluate and optimize prompt performance over time.
- **Project Proposal Architect**: An AI assistant that helps owners structure their projects into professional JSON-based proposals.

## 🔐 Technical Architecture & Security
- **Authentication**: Implements **Firebase UI Auth** for a multi-platform, secure sign-in experience supporting:
  - **Google OAuth**: One-tap secure login.
  - **Email/Password**: Traditional secure authentication.
- **Security model**: Adheres to the Android software stack security model, utilizing `proguard` for **Code Obfuscation** and strict **Runtime Permission Management** via `permission_handler`.
- **FCM Integration**: Leverages **Firebase Cloud Messaging** (FCM) to deliver real-time collaboration alerts and project updates directly to user devices.

## 🎭 Advanced UI & UX
- **Glassmorphism Design**: A modern, premium aesthetic using soft gradients, translucent cards, and high-fidelity blur effects.
- **Advanced Animations**: 
  - **Implicit Animations**: Smooth transitions between app states.
  - **Tween & Transition Widgets**: Custom `TweenAnimationBuilder` implementations for glowing network effects and fluid content entry (Advanced Networking Experience).
  - Built with `flutter_animate` for high-performance micro-interactions.

## 📦 Deployment & Flavors
The project is architected for production-grade deployment:
- **Build Flavors**: Configured with multiple `productFlavors` in Gradle:
  - `free`: Basic matching and project limits.
  - `pro`: Unlimited AI matching and advanced discovery features.
- **Code Protection**: Uses **R8/ProGuard obfuscation** to protect intellectual property before being released as an **Android App Bundle (.aab)**.

## 📂 Project Structure
```text
lib/
├── app/          # Routes (GetX) and Flavor configs
├── core/         # Premium Theme, Constants, Strings
├── data/
│   ├── models/   # Project, User, and Invitation models
│   ├── providers/# Firebase Firestore & Auth providers
│   └── services/ # AI (Gemini), GitHub, FCM, and Analytics
├── presentation/
│   ├── modules/  # Feature-based architecture (Auth, Dashboard, Projects)
│   └── widgets/  # Custom UI (GlassCard, Advanced Animations)
└── main.dart     # Multi-platform entry point
```

## 🛠 Tech Stack
- **Framework**: Flutter (Dart)
- **Local Backend API**: Python 3.12+ (FastAPI, Uvicorn, Pydantic)
- **Cloud Backend**: Firebase (Auth, Firestore, Messaging, Analytics, Remote Config)
- **Analytics**: Real-time event tracking and role-selection logging.
- **State Management**: GetX (Performance & Navigation)

---
*Developed with focus on Android Software Stack security and modern AI architecture.*
