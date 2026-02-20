# 📅 DevSync - Project Timeline & Milestones

## 📌 Project Overview
- **Project Name:** DevSync (AI-Powered Developer Matching Platform)
- **Duration:** 6 Weeks
- **Team Size:** 5 Developers
- **Work Methodology:** Agile Sprints & Relay System
- **Architecture:** Clean Architecture with Feature-Based Vertical Slicing.
- **State Management:** GetX.

---

## 🚀 Weekly Sprint Breakdown

### **Week 1: Project Setup & Core Infrastructure**
**Goal:** Establish the foundation, app architecture, and design system. No external API integration yet.
* **Key Deliverables:**
  - Initialize Flutter project using Clean Architecture.
  - Setup GetX Routing and State Management configurations.
  - Build the Design System (Colors, Typography, Theming).
  - Create global Reusable Widgets (Buttons, TextFields, AppBars).
  - Develop the UI Shell for Authentication (Login/Signup) and Role Selection (PM vs. Developer).

### **Week 2: Backend Services & Authentication (Vertical Slice 1)**
**Goal:** Connect the application to the database and establish secure user access.
* **Key Deliverables:**
  - Initialize Firebase (Firestore, Auth) and configure security rules.
  - Design Database Schema (Collections for PMs, Developers, Projects).
  - Implement **GitHub OAuth** for developers to securely sync accounts.
  - Implement Google Auth / Email Auth for Project Managers.
  - Make Authentication UI completely dynamic and functional.

### **Week 3: The GitHub Engine (External Data Integration)**
**Goal:** Fetch, process, and cache developer statistics securely.
* **Key Deliverables:**
  - Integrate **GitHub REST API** to fetch public repositories, languages, and commit history.
  - Implement data caching in Firestore to mitigate API rate limiting.
  - Develop the dynamic Developer Profile UI to display real-time GitHub badges and stats.

### **Week 4: The AI Architect (OpenAI Integration)**
**Goal:** Build the Project Manager's AI assistant for project requirement generation.
* **Key Deliverables:**
  - Integrate **OpenAI API** to act as the "AI Project Architect".
  - Develop the Chatbot UI interface for the PM dashboard.
  - Apply prompt engineering to output structured JSON data (Tech stack, roles, timeline) based on PM's natural language input.
  - Save generated project requirements to Firestore.

### **Week 5: Smart Matching & Invitation Workflow (The Core Value)**
**Goal:** Connect PM requirements with Developer profiles using the matching algorithm.
* **Key Deliverables:**
  - Develop the Recommendation Algorithm (matching AI project requirements with cached GitHub data).
  - Build the "Smart Scouting" UI for PMs to view ranked candidates with Confidence Scores.
  - Implement the Invitation System (PM sends invite -> Developer receives notification -> Accept/Reject logic).

### **Week 6: Quality Assurance, Polish & Demo Preparation**
**Goal:** Ensure a crash-free, visually appealing MVP ready for the final evaluation.
* **Key Deliverables:**
  - Comprehensive bug fixing and Error Handling (network failures, API timeouts).
  - UI/UX refinements and minor GetX animations for smoother transitions.
  - Performance optimization.
  - Inject realistic **Demo Data** into Firestore for pitching purposes.

---

## 🛡️ Security & Android Best Practices Integration
*Note: Security and Runtime Permissions are treated as cross-cutting concerns and integrated throughout the sprints to meet Android software stack security models:*
- **Sprint 2:** Implementation of `flutter_secure_storage` for encrypted GitHub OAuth token management (Adherence to the Android Keystore system).
- **Sprint 2 & 3:** Enforcing strict Firebase Security Rules to protect user PII (Personally Identifiable Information).
- **Sprint 4 & 5:** Proper handling of `.env` configurations to secure OpenAI API keys from version control (excluding them via `.gitignore`).
- **Sprint 5:** Implementation of Android Runtime Permissions (e.g., `POST_NOTIFICATIONS` for invites, `READ_EXTERNAL_STORAGE` for profile adjustments) using the `permission_handler` package. Permissions are requested contextually *only* when the specific feature is accessed by the user, adhering to modern Android best practices.

---

## 📊 Evaluation & KPIs Tracking
*Sprints are evaluated weekly based on the completion of the Key Deliverables. The ultimate success metric for this MVP phase is a 100% stable matching flow with zero critical API blocking or security breaches during the final demo.*