# 🚀 DevSync: The AI Project Architect Platform

**DevSync** is a professional ecosystem designed to bridge the gap between visionary project owners and elite developers using advanced AI-driven matchmaking and GitHub-based skill analysis.

---

## 🧠 Core Innovation: The AI Project Architect
Unlike generic chat assistants, DevSync features a specialized **Project Architect** (powered by Gemini 1.5 Flash) that actively collaborates with users:

*   **For Owners**: The AI discusses project dimensions, suggests tech stacks, generates full project proposals, and instantly ranks the best developer matches from the database.
*   **For Developers**: The AI acts as a technical mentor, analyzing GitHub skills to recommend projects and offering career growth insights.

---

## ✨ Key Features

### 🛡️ Smart Authentication & Sync
- **Google Sign-In**: Seamless authentication.
- **Gmail Data Sync**: Every login automatically synchronizes user profile names and photos from Google to Firestore for a consistently updated identity.
- **Role-Based Routing**: Automatic redirection to the appropriate experience based on the user's role (Developer or Owner).

### 📱 Unified Navigation (MainShell)
- A crystalline, glassmorphic navigation shell that adapts its tabs dynamically based on the user's role.
- **Developer Tabs**: Dashboard, Projects, Matches, Profile.
- **Owner Tabs**: Dashboard, Create, My Projects, Profile.

### 🤖 Global AI Assistant
- A floating, high-utility AI button accessible from any screen.
- **Brainstorming Mode**: Discuss and refine project ideas in real-time.
- **One-Click Creation**: Finalize a discussion to generate a full project entry in the database instantly.

### 📊 AI Matchmaking Engine
- **GitHub Analysis**: Developer skills are parsed and analyzed directly from their GitHub activity.
- **Ranked Recommendations**: Owners receive a full list of developers ranked by their match percentage (from "Perfect Match" down to "Weak Match").
- **Tiered Badges**: Visual indicators (Green, Blue, Orange, Red) provide immediate feedback on the strength of a developer-project pairing.

---

## 🛠️ Technical Stack
- **Framework**: [Flutter](https://flutter.dev/) (3.x)
- **State Management**: [GetX](https://pub.dev/packages/get)
- **Backend/DB**: [Firebase](https://firebase.google.com/) (Auth, Firestore)
- **AI Core**: [Google Gemini 1.5 Flash](https://ai.google.dev/)
- **Network Layer**: [Dio](https://pub.dev/packages/dio) for GitHub API integration
- **Styling**: Custom Glassmorphism UI System & `flutter_animate`

---

## 📂 Project Architecture
```text
lib/
├── app/              # Routes and Global Config
├── core/             # Themes, Constants, Networking
├── data/
│   ├── models/       # UserModel, ProjectModel
│   ├── providers/    # Firebase, GitHub API
│   └── services/     # Gemini, Analytics
└── presentation/
    ├── modules/      # Feature modules (Auth, Shell, AI, Dashboards)
    └── widgets/      # Shared Glassmorphic UI components
```

---

## 🚀 Getting Started
1.  **Sign In**: Use your Google account.
2.  **Select Role**: Choose whether you are looking to build or looking for work.
3.  **Collaborate**: Open the AI Architect and start defining your next vision.

---
*DevSync - Empowering developers and owners through the power of AI.*
