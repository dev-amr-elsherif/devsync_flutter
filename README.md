# 🚀 DevSync: AI-Powered Developer Matching Platform

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=white" alt="Firebase" />
  <img src="https://img.shields.io/badge/OpenAI-412991?style=for-the-badge&logo=openai&logoColor=white" alt="OpenAI" />
  <img src="https://img.shields.io/badge/GitHub_API-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub API" />
</div>

## 📖 About The Project

**DevSync** is an innovative cross-platform mobile application developed using Flutter. It aims to revolutionize how Project Managers (PMs) and Developers connect by utilizing an AI-driven matching ecosystem.

Unlike traditional project management tools, DevSync prioritizes verifiable technical competence by analyzing real-world public GitHub activity, ensuring that project requirements meet the most qualified talent.

### ⚠️ The Problem

- **Verification Gap:** PMs struggle to evaluate the true technical proficiency of developers beyond self-declared CVs.
- **Discovery Friction:** Talented developers often go unnoticed if they lack "keyword-optimized" profiles.
- **Efficiency Loss:** Manual searching and vetting lead to wasted time and mismatched expectations.

---

## ⭐ Core Features

- **AI Project Architect:** Chatbot-based project setup that simplifies project definition for PMs through natural language processing.
- **GitHub Scraper & Analyzer:** Objective skill evaluation via public data using the GitHub REST API to analyze public commits, languages used, and contribution patterns.
- **Smart Matching Recommendation Engine:** Proprietary logic and AI algorithm that ranks developers based on their actual coding history relative to project needs.
- **Secure Auth & Invitation Workflow:** Integration with GitHub and Google OAuth, along with a controlled system for professional outreach.

---

## 🛠️ Technology Stack

| Component            | Technology                                  |
| :------------------- | :------------------------------------------ |
| **Frontend**         | Flutter (Dart)                              |
| **State Management** | GetX                                        |
| **Backend**          | Firebase (Firestore, Cloud Functions, Auth) |
| **AI/LLM**           | OpenAI API (GPT Models)                     |
| **External APIs**    | GitHub REST API                             |

---

## 🏗️ Architecture & Security

DevSync is built with scalability and security in mind:

- **Architecture:** Utilizes Clean Architecture with Feature-Based Vertical Slicing.
- **Token Management:** Implementation of `flutter_secure_storage` for encrypted GitHub OAuth token management, adhering to the Android Keystore system.
- **API Rate Mitigation:** Implements Firestore Caching to store retrieved GitHub profiles for 24 hours, mitigating GitHub API rate limiting risks.
- **Data Privacy:** Enforces strict Firebase Security Rules to protect user Personally Identifiable Information (PII).
- **Environment Security:** Proper handling of `.env` configurations to secure OpenAI API keys from version control.

---

## 📊 Key Performance Targets (MVP)

- **Time-to-Match:** < 2 Minutes (From project creation to invite list).
- **Skill Match Accuracy:** ≥ 80% alignment between GitHub history and project needs.
- **System Uptime:** ≥ 99.9%.

---

## 👨‍💻 Team

- **Team Leader:** Amr Fathy Mokhtar Elsherif
- **Team Members:**
  - Verena Samir Adly
  - Momen Hassan Mohamed
  - Hala Mahmoud Abdelaziz
  - Yosef Salah Abdelhamid

---

> "DevSync aspires to become the standard for skill-first professional networking by replacing subjective resumes with objective code analysis and AI-driven insights."
