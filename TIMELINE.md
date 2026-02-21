# 📅 DevSync - Project Timeline & Milestones

## 📌 Project Overview

- **Project Name:** DevSync (AI-Powered Developer Matching Platform)
- **Duration:** 6 Weeks
- **Team Composition:**
  - **Team Leader:** Amr Fathy Elsherif
  - **Team Members:** Verena Samir Adly, Momen Hassan Mohamed, Hala Mahmoud Abdelaziz, Yosef Salah Abdelhamid
- **Work Methodology:** Agile Sprints & Relay System
- **Architecture:** Clean Architecture with Feature-Based Vertical Slicing
- **State Management:** GetX

---

## 🚀 Weekly Sprint Breakdown

### **Week 1: Project Setup & Core Infrastructure**

**Goal:** Establish the foundation, app architecture, and design system.

- **Key Deliverables:**
  - Initialize Flutter project using Clean Architecture.
  - Setup GetX Routing and State Management configurations.
  - Build the Design System (Colors, Typography, Theming).
  - Create global Reusable Widgets (Buttons, TextFields, AppBars).
  - **Documentation:** Initialize `README.md` with project vision and architecture overview.

### **Week 2: Backend Services & Authentication (Vertical Slice 1)**

**Goal:** Connect the application to the database and establish secure user access.

- **Key Deliverables:**
  - Initialize Firebase (Firestore, Auth) and configure security rules.
  - Design Database Schema (Collections for PMs, Developers, Projects).
  - Implement **GitHub OAuth** for developers & Google/Email Auth for PMs.
  - **Documentation:** Document the Database ERD and Authentication flow in the Technical Manual.

### **Week 3: The GitHub Engine (External Data Integration)**

**Goal:** Fetch, process, and cache developer statistics securely.

- **Key Deliverables:**
  - Integrate **GitHub REST API** for repositories, languages, and commits.
  - Implement data caching in Firestore to mitigate API rate limiting.
  - Develop the dynamic Developer Profile UI with real-time GitHub stats.
  - **Documentation:** Document API integration logic and caching strategies.

### **Week 4: The AI Architect (OpenAI Integration)**

**Goal:** Build the Project Manager's AI assistant for project requirement generation.

- **Key Deliverables:**
  - Integrate **OpenAI API** as the "AI Project Architect".
  - Develop Chatbot UI for the PM dashboard.
  - Apply prompt engineering for structured JSON output (Tech stack, roles, timeline).
  - **Documentation:** Technical breakdown of Prompt Engineering and AI response handling.

### **Week 5: Smart Matching & Invitation Workflow**

**Goal:** Connect PM requirements with Developer profiles using the matching algorithm.

- **Key Deliverables:**
  - Develop the Recommendation Algorithm (AI Requirements vs. GitHub Data).
  - Build "Smart Scouting" UI for PMs with Confidence Scores.
  - Implement Invitation System (Accept/Reject logic & Notifications).
  - **Documentation:** Map out the Matching Algorithm logic and User Workflow diagrams.

### **Week 6: Quality Assurance & Comprehensive Documentation**

**Goal:** Final polish, bug fixing, and professional hand-off.

- **Key Deliverables:**
  - Comprehensive bug fixing & Performance optimization.
  - Inject realistic **Demo Data** into Firestore for the final pitch.
  - **Final Documentation:** Complete the **Comprehensive Technical Documentation** and a detailed **README** following industry best practices (Setup instructions, Architecture deep-dive, and Demo GIFs).

---

## 🛡️ Security & Android Best Practices

- **Encrypted Storage:** Using `flutter_secure_storage` for OAuth tokens (Android Keystore).
- **Data Privacy:** Strict Firebase Security Rules to protect user PII.
- **Environment Safety:** Secure `.env` handling for API keys (excluded via `.gitignore`).
- **Runtime Permissions:** Contextual handling of `POST_NOTIFICATIONS` and storage using `permission_handler`.

---

## 📊 Evaluation & KPIs Tracking

_Sprints are evaluated weekly based on completion of deliverables. Success is defined by a 100% stable matching flow and professional-grade documentation ready for final evaluation._
