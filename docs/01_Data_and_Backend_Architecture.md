# 📁 docs/01_Data_and_Backend_Architecture.md

## DevSync — Phase 1: Data Layer & Backend Architecture

> **Document Version:** 1.0  
> **Date:** July 2026  
> **Author:** Lead Enterprise Software Architect  
> **Scope:** Complete micro-level documentation of `lib/data/` (Models, Providers, Services), `python_backend/`, `functions/`, and all supporting infrastructure (`core/network`, `core/errors`, `core/constants`).

---

## Table of Contents

1. [Executive Architecture Overview](#1-executive-architecture-overview)
2. [Data Models Layer (`lib/data/models/`)](#2-data-models-layer)
3. [Provider Layer (`lib/data/providers/`)](#3-provider-layer)
4. [Service Layer (`lib/data/services/`)](#4-service-layer)
5. [Core Infrastructure (`lib/core/`)](#5-core-infrastructure)
6. [Python Backend (`python_backend/`)](#6-python-backend)
7. [Firebase Cloud Functions (`functions/`)](#7-firebase-cloud-functions)
8. [Firestore Security Rules](#8-firestore-security-rules)
9. [Application Bootstrap (`main.dart`)](#9-application-bootstrap-maindart)
10. [Cross-Cutting Concerns & Edge Cases](#10-cross-cutting-concerns--edge-cases)
11. [Defense Q&A — 25 Aggressive Examiner Questions](#11-defense-qa--25-aggressive-examiner-questions)

---

## 1. Executive Architecture Overview

### 1.1 High-Level Architecture Diagram

```text
┌───────────────────────────────────────────────────────────────────────┐
│                        FLUTTER CLIENT                                │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │  Presentation Layer (Screens, Widgets, Controllers via GetX)  │   │
│  └──────────────────────────┬────────────────────────────────────┘   │
│                             │                                        │
│  ┌──────────────────────────▼────────────────────────────────────┐   │
│  │                   SERVICE LAYER                               │   │
│  │  ┌────────────┐ ┌──────────┐ ┌────────────┐ ┌────────────┐   │   │
│  │  │GroqService │ │FCMService│ │AnalyticsSvc│ │RemoteCfgSvc│   │   │
│  │  └─────┬──────┘ └────┬─────┘ └──────┬─────┘ └──────┬─────┘   │   │
│  └────────┼─────────────┼──────────────┼──────────────┼────────┘    │
│           │             │              │              │              │
│  ┌────────▼─────────────▼──────────────▼──────────────▼────────┐    │
│  │                   PROVIDER LAYER                            │    │
│  │  ┌──────────────────┐  ┌──────────────────────┐             │    │
│  │  │ FirebaseProvider │  │  GitHubApiProvider   │             │    │
│  │  └────────┬─────────┘  └──────────┬───────────┘             │    │
│  └───────────┼───────────────────────┼─────────────────────────┘    │
│              │                       │                              │
│  ┌───────────▼───────────────────────▼─────────────────────────┐    │
│  │                    MODEL LAYER                              │    │
│  │  UserModel │ ProjectModel │ InvitationModel │ ReviewModel   │    │
│  └─────────────────────────────────────────────────────────────┘    │
└───────────────────────────┬───────────────────────────────────────────┘
                            │
            ┌───────────────┼───────────────┐
            ▼               ▼               ▼
   ┌────────────────┐ ┌───────────┐ ┌──────────────────┐
   │  Cloud         │ │ GitHub    │ │  Python Backend  │
   │  Firestore     │ │ REST API  │ │  (FastAPI)       │
   │  + Auth + FCM  │ │           │ │  AI Analyzer +   │
   │  + RemoteConfig│ │           │ │  Matching Engine │
   │  + Analytics   │ │           │ │                  │
   └────────────────┘ └───────────┘ └──────────────────┘
         │                                     │
         ▼                                     ▼
   ┌────────────────┐                ┌──────────────────┐
   │ Cloud Functions│                │  Groq LLM API    │
   │ (Token Broker) │                │  (llama-3.3-70b) │
   └────────────────┘                └──────────────────┘
```

### 1.2 Architectural Justifications

- **Why a Layered Architecture (Model → Provider → Service)?**
  - **Separation of Concerns (SoC):** Each layer has a single, well-defined responsibility. Models handle pure data representation and serialization. Providers handle raw data access (Firestore queries, HTTP calls). Services orchestrate provider calls and add business logic (AI prompt engineering, match calculation).
  - **Testability:** By isolating Firestore interactions in `FirebaseProvider`, the service and presentation layers can be unit-tested with mock providers without requiring a live Firebase instance.
  - **Replaceability:** If the team decides to migrate from Firestore to Supabase or PostgreSQL, only the `FirebaseProvider` class needs rewriting — the service and presentation layers remain untouched.
  - **Defense-grade reasoning:** This follows the Clean Architecture principles (Robert C. Martin, 2012) and the Repository Pattern, which is the industry standard for mobile applications interacting with remote data sources.

- **Why Firebase (Firestore + Auth + FCM + Analytics + Remote Config)?**
  - **Serverless scalability:** Firestore auto-scales horizontally. For a graduation project with variable user load (0 to hundreds during demo), Firestore eliminates infrastructure provisioning entirely.
  - **Real-time sync:** Firestore's snapshot listeners (`snapshots()`) provide real-time UI updates (e.g., invitation status changes, new join requests) without polling, which would drain battery and waste bandwidth.
  - **Integrated ecosystem:** Firebase Auth handles JWT token management, session persistence, and multi-provider authentication (Google Sign-In, GitHub OAuth) with zero custom backend code. FCM provides cross-platform push notifications. Analytics provides event tracking. Remote Config provides feature flagging without app store re-deployment.
  - **Cost efficiency:** The Spark (free) plan covers 50,000 reads/day, 20,000 writes/day, and 20,000 deletes/day — more than sufficient for a graduation project.

- **Why GetX for State Management and DI?**
  - **Minimal boilerplate:** GetX's `Get.put()` and `Get.find()` provide dependency injection with a single line — no Provider tree nesting, no BuildContext dependency.
  - **Reactive state:** `GetBuilder` and `Obx` provide fine-grained widget rebuilding without `setState()` or `ChangeNotifier` overhead.
  - **Navigation:** GetX provides named routing (`GetMaterialApp`, `getPages`) with zero-boilerplate transition animations.
  - **Trade-off awareness:** GetX is criticized for being "too magical" and coupling navigation/state/DI into one package. For a graduation project, the productivity gain outweighs the coupling concern. In a production enterprise app, `Riverpod` or `Bloc` would be preferred for their stricter separation.

- **Why a Separate Python Backend (FastAPI)?**
  - **Computational isolation:** The AI analysis pipeline (GitHub data fetching → metric computation → seniority classification → skill extraction) is CPU-bound and involves multiple sequential API calls. Running this in a Cloud Function would risk cold-start latency (3-7 seconds). A persistent FastAPI server eliminates cold starts.
  - **Python ecosystem:** The matching algorithm uses advanced string normalization, regex-based keyword matching, and weighted scoring — all of which are more naturally expressed in Python.
  - **Separation from the mobile app:** The Python backend runs independently, meaning it can be tested, deployed, and scaled without affecting the Flutter app. This is a microservice architecture pattern.
  - **Why FastAPI specifically?** FastAPI provides automatic request validation via Pydantic models, automatic OpenAPI/Swagger documentation, native `async/await` support for non-blocking I/O, and is the fastest Python web framework (benchmarked against Django REST Framework and Flask).

- **Why Groq API (not OpenAI, not Google Gemini) for client-side AI?**
  - **Latency:** Groq's custom LPU (Language Processing Unit) hardware delivers inference at 500+ tokens/second, 10x faster than OpenAI's GPT-4 Turbo. For a mobile app where users expect instant responses, this is critical.
  - **Cost:** Groq's free tier provides 14,400 requests/day with the `llama-3.3-70b-versatile` model — sufficient for a graduation demo.
  - **Model quality:** Llama 3.3 70B Versatile matches GPT-4 on most benchmarks while being open-source, aligning with academic project requirements.
  - **Migration history:** The code comments indicate a migration from Google Gemini (`gemini_service.dart` → `groq_service.dart`), likely due to Gemini's rate limits or regional availability issues.

- **Why Dual AI Architecture (Client-side Groq + Server-side Python)?**
  - **Client-side Groq (GroqService):** Handles interactive, user-facing AI features — chat with AI Architect, project idea expansion, match percentage calculation. These require low latency and conversational context.
  - **Server-side Python (ai_service.py):** Handles one-time, computationally heavy analysis — GitHub profile analysis, seniority classification, skill extraction. These are triggered once during profile setup and cached in Firestore.
  - **Resilience:** If Groq goes down, the Python backend's matching engine (which uses algorithmic scoring, not LLM-based) still functions. If the Python backend is unavailable, client-side Groq can still power chat and project ideation.

---

## 2. Data Models Layer

**Directory:** `lib/data/models/`

### 2.1 Architectural Role

- The Model Layer is the **single source of truth** for data shape in the entire application.
- Every model is a **Plain Dart Object (PDO)** — no framework dependencies except `cloud_firestore` (for `Timestamp` conversion).
- Every model implements the **Serialization Triad:** `fromMap()` (deserialization), `toMap()` (serialization), and optionally `copyWith()` (immutable updates).
- **Why not use `json_serializable` or `freezed`?** For a project with 4 models totaling ~430 lines, the overhead of build_runner code generation (freezed/json_serializable) adds complexity without proportional benefit. Manual serialization provides full visibility during defense and avoids "generated code" black boxes.

---

### 2.2 `UserModel` — The Central Entity

**File:** `lib/data/models/user_model.dart` (138 lines)

#### 2.2.1 Why This Model Exists

- Represents every authenticated user in the system.
- DevSync has a **dual-role architecture:** every user is either a `developer` (seeking projects) or an `owner` (posting projects). This is modeled via the `role` field, not separate classes, to avoid polymorphic deserialization complexity.

#### 2.2.2 Field-by-Field Breakdown

| Field | Type | Required | Default | Firestore Type | Purpose |
| --- | --- | --- | --- | --- | --- |
| `uid` | `String` | ✅ | — | `string` | Firebase Auth UID. Used as Firestore document ID. Immutable after creation. |
| `email` | `String` | ✅ | — | `string` | User's email from Firebase Auth. Used for search and display. |
| `name` | `String` | ✅ | — | `string` | Display name. Defaults to empty string if null in Firestore. |
| `photoUrl` | `String?` | ❌ | `null` | `string?` | Profile photo URL from Google/GitHub OAuth. Nullable for email-only signups. |
| `role` | `String` | ✅ | `'developer'` | `string` | Either `'developer'` or `'owner'`. Stored as string (not enum value) for Firestore compatibility. |
| `skills` | `List<String>` | ❌ | `[]` | `array<string>` | Developer's technical skills (e.g., `['Flutter', 'Python', 'Firebase']`). Populated from GitHub analysis or manual input. |
| `githubUrl` | `String?` | ❌ | `null` | `string?` | Full GitHub profile URL (e.g., `https://github.com/username`). Set after GitHub OAuth and AI analysis. |
| `aiBio` | `String?` | ❌ | `null` | `string?` | AI-generated professional biography. Generated by the Python backend's `analyze_developer_metrics()` function. |
| `githubSeniority` | `String?` | ❌ | `null` | `string?` | AI-classified seniority level: `'Junior'`, `'Mid-Level'`, `'Senior'`, or `'Lead'`. Computed from a composite score of repos, stars, and account age. |
| `topAiSkills` | `List<String>?` | ❌ | `null` | `array<string>?` | Top 8 languages + 3 trending topics, extracted from GitHub repositories by the Python backend. |
| `publicRepos` | `int?` | ❌ | `null` | `number?` | Total public repositories count from GitHub API. |
| `followers` | `int?` | ❌ | `null` | `number?` | GitHub followers count. |
| `accountAgeYears` | `int?` | ❌ | `null` | `number?` | Years since GitHub account creation. Computed from `created_at` timestamp. |
| `ratingCount` | `int` | ❌ | `0` | `number` | Total number of reviews received (developer only). Incremented atomically in Firestore transactions. |
| `avgRating` | `double` | ❌ | `0.0` | `number` | Running average rating (1.0-5.0). Computed via cumulative moving average formula: `newAvg = ((oldAvg * oldCount) + newRating) / newCount`. |
| `location` | `String?` | ❌ | `null` | `string?` | Geographic location from GitHub profile. Used for display only. |
| `topRepositories` | `List<dynamic>?` | ❌ | `null` | `array?` | Top 5 repositories (sorted by stars, then last updated). Each entry contains `name`, `description`, `language`, `stargazers_count`, `forks_count`, `html_url`. |

#### 2.2.3 Enum: `UserRole`

```dart
enum UserRole { developer, owner, unknown }
```

- **Why defined but not used in the model fields?** The enum exists as a type-safe convenience for presentation-layer logic (e.g., `if (role == UserRole.developer)`), but the model itself stores `role` as `String` because Firestore does not natively support Dart enums.
- **Why `unknown`?** Defensive programming. If a user document has a corrupted or missing `role` field, the app can handle it gracefully instead of crashing.

#### 2.2.4 Serialization Details

- **`fromMap(Map<String, dynamic> map)`:**
  - Note: Takes only a `Map`, not a document ID. The `uid` is stored **inside** the map (field `'uid'`), not derived from the Firestore document ID. This is because the User document ID IS the uid (they are the same value).
  - **Null safety:** Every field uses the null-coalescing operator (`??`) with sensible defaults: empty string for `name`/`email`, empty list for `skills`, `0` for counts, `0.0` for averages.
  - **Type coercion:** `avgRating` uses `.toDouble()` to handle Firestore returning `int` when the value is a whole number (e.g., `3` instead of `3.0`).
  - **List casting:** `skills` uses `List<String>.from()` to cast from Firestore's `List<dynamic>`. This will throw a `TypeError` at runtime if any element is not a `String` — an acceptable trade-off since skills are always written as strings.

- **`toMap()`:**
  - Serializes all 17 fields. The `uid` is included in the map because `saveUser()` in `FirebaseProvider` uses `.set(user.toMap())`, which writes the entire document body.
  - **No `FieldValue.serverTimestamp()`:** Unlike other models, `UserModel.toMap()` does not use server timestamps because timestamps are not fields in this model.

- **`copyWith()`:**
  - Returns a new `UserModel` instance with selectively overridden fields.
  - **Why immutable updates?** GetX's `GetBuilder` detects state changes by reference comparison. Creating a new object (rather than mutating) ensures UI rebuilds correctly.

#### 2.2.5 Helper Getters

```dart
bool get isDeveloper => role == 'developer';
bool get isOwner => role == 'owner';
bool get hasGithubProfile => githubUrl != null;
```

- **Why not methods?** These are pure derived values with no side effects, making getters the idiomatic Dart choice.
- **`hasGithubProfile`:** Used to conditionally show GitHub-related UI (seniority badge, repo list, skills) only when the user has completed GitHub OAuth.

#### 2.2.6 Edge Cases

- **Missing `role` field in Firestore:** Defaults to `'developer'`. This is the safer default because developers have fewer permissions than owners.
- **Empty `skills` array:** The app still functions — the matching algorithm assigns a base score of 5.0 (floor) even with zero skill matches.
- **`avgRating` precision drift:** After many ratings, floating-point arithmetic can introduce tiny precision errors (e.g., `4.333333333333334` instead of `4.33`). The UI rounds to one decimal place for display.
- **`topRepositories` typed as `List<dynamic>`:** This is intentional — each repository is a `Map<String, dynamic>` with heterogeneous value types (strings, ints, nulls). Using `List<dynamic>` avoids nested generic type parameters.

---

### 2.3 `ProjectModel` — The Work Unit

**File:** `lib/data/models/project_model.dart` (62 lines)

#### 2.3.1 Why This Model Exists

- Represents a project posted by an `owner` that `developers` can join via invitations.
- The project is the **central business entity** around which invitations, matching, and reviews revolve.

#### 2.3.2 Field-by-Field Breakdown

| Field | Type | Required | Default | Purpose |
| --- | --- | --- | --- | --- |
| `id` | `String` | ✅ | — | Firestore document ID. Auto-generated by `.add()`. |
| `ownerId` | `String` | ✅ | — | Firebase Auth UID of the project creator. Used for access control in Firestore rules. |
| `ownerName` | `String` | ✅ | — | Denormalized owner display name. Avoids an extra Firestore read when rendering project cards. |
| `ownerPhotoUrl` | `String?` | ❌ | `null` | Denormalized owner photo URL. Same denormalization rationale. |
| `title` | `String` | ✅ | — | Project title (e.g., "AI-Powered E-Commerce Platform"). |
| `description` | `String` | ✅ | — | Detailed project description. Used as input to the matching algorithm's description keyword analysis. |
| `techStack` | `List<String>` | ❌ | `[]` | Required technologies (e.g., `['Flutter', 'Firebase', 'Python']`). This is the PRIMARY input to the matching engine. |
| `repoUrl` | `String?` | ❌ | `null` | GitHub repository URL. Optional — not all projects have a repo at creation time. |
| `websiteUrl` | `String?` | ❌ | `null` | Deployed website URL. Optional. |
| `status` | `String` | ❌ | `'active'` | Lifecycle status. Values: `'active'`, `'paused'`, `'ready_for_review'`, `'completed'`, `'cancelled'`. |
| `internalNotes` | `String` | ❌ | `''` | Private notes from the owner. Not visible to developers. |

#### 2.3.3 Enum: `ProjectStatus`

```dart
enum ProjectStatus { active, paused, completed, cancelled }
```

- **Defined but not used in the model:** Same rationale as `UserRole` — Firestore stores strings, the enum provides type-safety in presentation logic.
- **Missing `readyForReview`:** The enum doesn't include `ready_for_review` despite it being a valid status in `FirebaseProvider.getProject()`. This is an **architectural gap** — the enum should be updated for completeness.

#### 2.3.4 Denormalization Strategy

- **Why store `ownerName` and `ownerPhotoUrl` in the project document?**
  - Firestore charges per document read. Displaying a project card requires the project title, owner name, and owner photo. Without denormalization, every project card would require TWO reads (project + user).
  - With denormalization, it's ONE read per project card.
  - **Trade-off:** If an owner changes their name/photo, existing project documents become stale. This is acceptable because name changes are rare and the inconsistency is cosmetic.

#### 2.3.5 Project Status Lifecycle

```text
┌──────────┐     all devs finish     ┌────────────────────┐     owner submits review    ┌───────────┐
│  active  │ ──────────────────────▶ │  ready_for_review  │ ─────────────────────────▶ │ completed │
└──────────┘                         └────────────────────┘                            └───────────┘
     │                                                                                      
     │  owner pauses                                                                        
     ▼                                                                                      
┌──────────┐                                                                                
│  paused  │                                                                                
└──────────┘                                                                                
     │                                                                                      
     │  owner cancels                                                                       
     ▼                                                                                      
┌───────────┐                                                                               
│ cancelled │                                                                               
└───────────┘                                                                               
```

- The `active → ready_for_review` transition is **automatically triggered** by `FirebaseProvider.getProject()` and `updateDevWorkStatus()` when all accepted developers mark their work as `finished`.
- The `ready_for_review → completed` transition occurs in `submitReview()` as part of a Firestore transaction.

#### 2.3.6 Edge Cases

- **Project with no `status` field in Firestore:** `FirebaseProvider.getProject()` detects this and auto-fills `'active'` with a write-back update. This handles legacy documents created before the status field was introduced.
- **Empty `techStack`:** The matching algorithm treats this as a universal match (returns base score), not a zero score. Rationale: an owner who hasn't specified tech stack shouldn't be penalized — they need all possible matches.
- **No `copyWith()` method:** Unlike `UserModel` and `InvitationModel`, `ProjectModel` lacks `copyWith()`. Project updates go through `FirebaseProvider.updateProjectState()` which accepts a partial `Map<String, dynamic>`, making `copyWith()` unnecessary.

---

### 2.4 `InvitationModel` — The Collaboration Bridge

**File:** `lib/data/models/invitation_model.dart` (176 lines — the most complex model)

#### 2.4.1 Why This Model Exists

- An invitation is the **atomic unit of collaboration** in DevSync. Every developer-project relationship begins and ends through an invitation.
- Supports **bidirectional invitations:** an owner can invite a developer (standard invitation), OR a developer can request to join a project (join request). Both are represented by the same model.

#### 2.4.2 Field-by-Field Breakdown

| Field | Type | Required | Default | Purpose |
| --- | --- | --- | --- | --- |
| `id` | `String` | ✅ | — | Firestore document ID |
| `senderId` | `String` | ✅ | — | UID of the user who initiated the invitation/request |
| `senderName` | `String` | ✅ | — | Denormalized sender name |
| `senderPhotoUrl` | `String?` | ❌ | `null` | Denormalized sender photo |
| `receiverId` | `String` | ✅ | — | UID of the target user |
| `receiverName` | `String?` | ❌ | `null` | Denormalized receiver name |
| `receiverPhotoUrl` | `String?` | ❌ | `null` | Denormalized receiver photo |
| `projectId` | `String` | ✅ | — | Associated project's Firestore ID |
| `projectTitle` | `String` | ✅ | — | Denormalized project title |
| `status` | `InvitationStatus` | ✅ | `pending` | Current lifecycle state (enum) |
| `devWorkStatus` | `DevWorkStatus?` | ❌ | `null` | Developer's work progress. Only meaningful when status is `accepted`. |
| `timestamp` | `DateTime` | ✅ | — | Creation timestamp. Falls back to `DateTime.now()` if Firestore `Timestamp` is null. |
| `declineReason` | `String?` | ❌ | `null` | Reason provided when declining an invitation/request. |
| `apologyNote` | `String?` | ❌ | `null` | Note from owner when proposing cancellation of an accepted invitation. |

#### 2.4.3 Enum: `InvitationStatus` (6 States)

```dart
enum InvitationStatus {
  pending,              // Owner invited a developer, awaiting response
  accepted,             // Developer accepted the invitation
  declined,             // Developer declined the invitation  
  joinRequest,          // Developer requested to join (reverse flow)
  cancellationProposed, // Owner wants to cancel after acceptance
  cancelled;            // Cancellation was approved by developer
}
```

- **Why 6 states instead of the typical 3 (pending/accepted/rejected)?**
  - `joinRequest`: Enables the **reverse invitation flow** where developers can proactively seek projects. This differentiates DevSync from platforms that only support owner-initiated invitations.
  - `cancellationProposed` + `cancelled`: Implements a **graceful cancellation protocol**. When an owner needs to cancel an accepted invitation (e.g., project pivot), they can't unilaterally remove the developer — they must propose cancellation with an apology, and the developer must approve. This protects developer interests.

- **`toFirestoreString()` and `fromString()`:**
  - Firestore stores enum values as snake_case strings (e.g., `'join_request'`, `'cancellation_proposed'`). These methods handle the bidirectional conversion.
  - **Why not use `.name`?** Dart enum `.name` returns `'joinRequest'` (camelCase), but the Firestore convention in this project is snake_case. Using custom serialization ensures consistency.

- **Convenience getters:**

  ```dart
  bool get isPending              => status.isPending;
  bool get isAccepted             => status.isAccepted;
  bool get isDeclined             => status.isDeclined;
  bool get isJoinRequest          => status.isJoinRequest;
  bool get isCancellationProposed => status.isCancellationProposed;
  bool get isCancelled            => status.isCancelled;
  ```

  - Delegate to the enum's own getters for cleaner presentation-layer code.

#### 2.4.4 Enum: `DevWorkStatus` (2 States)

```dart
enum DevWorkStatus {
  inProgress,  // Developer is actively working
  finished;    // Developer has completed their tasks
}
```

- **Why a separate enum from `InvitationStatus`?**
  - `DevWorkStatus` tracks **work progress**, not **invitation lifecycle**. An invitation can be `accepted` with `devWorkStatus: inProgress` or `devWorkStatus: finished`.
  - When ALL accepted developers for a project have `devWorkStatus: finished`, the project automatically transitions to `ready_for_review`.

- **`fromString()` returns nullable:**

  ```dart
  static DevWorkStatus? fromString(String? value)
  ```

  - Returns `null` for unknown/missing values, unlike `InvitationStatus.fromString()` which returns `pending`. This is because `devWorkStatus` is genuinely optional (irrelevant before acceptance).

#### 2.4.5 Invitation Lifecycle State Machine

```text
                     Owner invites Developer
                             │
                             ▼
                      ┌──────────┐
                      │ pending  │◄────────────────────┐
                      └────┬─────┘                     │
                    ┌──────┴──────┐                    │
              Dev accepts    Dev declines              │
                    │              │                    │
                    ▼              ▼                    │
             ┌──────────┐  ┌───────────┐               │
             │ accepted │  │ declined  │     Developer requests to join
             └────┬─────┘  └───────────┘               │
                  │                                    │
         Owner proposes                                ▼
         cancellation                          ┌──────────────┐
                  │                            │ joinRequest  │
                  ▼                            └──────┬───────┘
   ┌──────────────────────────┐              ┌────────┴────────┐
   │ cancellationProposed     │        Owner accepts     Owner declines
   └──────────┬───────────────┘              │                  │
         ┌────┴────┐                         ▼                  ▼
    Dev approves  Dev rejects         ┌──────────┐      ┌───────────┐
         │              │             │ accepted │      │ declined  │
         ▼              ▼             └──────────┘      └───────────┘
  ┌───────────┐  ┌──────────┐
  │ cancelled │  │ accepted │
  └───────────┘  │(restored)│
                 └──────────┘
```

#### 2.4.6 Edge Cases

- **Null `timestamp` in Firestore:** Falls back to `DateTime.now()`. This prevents crashes on legacy documents but introduces a minor data integrity issue (the displayed timestamp won't match the actual creation time).
- **Unknown `status` string in Firestore:** Defaults to `pending`. This is the safest default because pending invitations require action — they'll be surfaced to the user for resolution.
- **Self-invitation:** Nothing in the model prevents `senderId == receiverId`. This must be validated at the UI/controller layer.

---

### 2.5 `ReviewModel` — The Feedback Loop

**File:** `lib/data/models/review_model.dart` (53 lines)

#### 2.5.1 Why This Model Exists

- Captures an owner's assessment of a developer's work on a project.
- Directly feeds into the developer's `avgRating` and `ratingCount` in `UserModel`, creating a reputation system.

#### 2.5.2 Field-by-Field Breakdown

| Field | Type | Required | Default | Purpose |
| --- | --- | --- | --- | --- |
| `id` | `String` | ✅ | — | Firestore document ID |
| `projectId` | `String` | ✅ | — | The reviewed project |
| `projectTitle` | `String` | ✅ | — | Denormalized for display |
| `ownerId` | `String` | ✅ | — | The reviewer's UID (always the project owner) |
| `ownerName` | `String` | ✅ | — | Denormalized reviewer name |
| `developerId` | `String` | ✅ | — | The reviewed developer's UID |
| `rating` | `double` | ✅ | — | Numeric rating, 1.0 to 5.0 |
| `comment` | `String` | ✅ | — | Textual feedback |
| `timestamp` | `DateTime` | ✅ | — | Review submission time |

#### 2.5.3 Serialization Details

- **`fromMap()` timestamp handling:**

  ```dart
  timestamp: (map['timestamp'] as Timestamp).toDate(),
  ```

  - **Critical edge case:** This cast will throw a `NullPointerException` if `timestamp` is `null` in Firestore. Unlike other models that use null-safe casting (`as Timestamp?`), this model assumes `timestamp` always exists. This is valid because `toMap()` uses `FieldValue.serverTimestamp()`, which is always populated by Firestore on write.
  - **However:** If a review document is manually created in the Firestore console without a `timestamp` field, this will crash. This is a known fragility.

- **`toMap()` uses `FieldValue.serverTimestamp()`:**

  ```dart
  'timestamp': FieldValue.serverTimestamp(),
  ```

  - Server-side timestamps ensure consistency regardless of the client device's clock settings. This is critical for ordering reviews chronologically.

#### 2.5.4 Rating Calculation (in `FirebaseProvider.submitReview()`)

- The cumulative moving average formula:

```text
  newAvg = ((oldAvg * oldCount) + newRating) / (oldCount + 1)
  ```

- This runs inside a **Firestore transaction** to prevent race conditions when two owners review the same developer simultaneously.
- **Edge case:** If a developer's document doesn't exist in the `developers` collection (e.g., they're in the `users` legacy collection), the transaction's `devDoc.exists` check prevents the update. The review is still saved, but the developer's rating is not updated. This is a data integrity gap.

---

## 3. Provider Layer

**Directory:** `lib/data/providers/`

### 3.1 Architectural Role

- Providers are the **data access gateways** — they translate between Dart objects and external data sources (Firestore, GitHub API).
- No business logic resides here. Providers perform raw CRUD operations and data mapping.
- Each provider encapsulates a single data source, following the **Single Responsibility Principle**.

---

### 3.2 `FirebaseProvider` — The Core Data Gateway

**File:** `lib/data/providers/firebase_provider.dart` (375 lines — the largest file in the data layer)

#### 3.2.1 Why This Class Exists

- Centralizes ALL Firestore interactions into a single class. This creates a consistent API surface and makes Firestore operations auditable.
- Every controller in the app depends on `FirebaseProvider` (via GetX injection) for data access.

#### 3.2.2 Collection Architecture

```text
Firestore Database
├── developers/        ← UserModel documents (role='developer')
│   └── {uid}/
├── owners/            ← UserModel documents (role='owner')
│   └── {uid}/
├── users/             ← Legacy collection (migration target)
│   └── {uid}/
├── projects/          ← ProjectModel documents
│   └── {projectId}/
├── invitations/       ← InvitationModel documents
│   └── {invitationId}/
├── reviews/           ← ReviewModel documents
│   └── {reviewId}/
└── notifications/     ← Legacy/unused (write-locked in rules)
    └── {notifId}/
```

- **Why separate `developers` and `owners` collections instead of a single `users` collection?**
  - **Query efficiency:** The app frequently needs "all developers" for matching. With a single `users` collection, every query would need a `.where('role', isEqualTo: 'developer')` filter. With separate collections, `getDevelopers()` simply reads the entire `developers` collection — no filter index required.
  - **Security granularity:** Firestore rules can enforce different access patterns per collection (e.g., owners can't modify developer documents and vice versa).
  - **Migration support:** The legacy `users` collection still exists and is checked as a fallback in `getUser()`, ensuring backward compatibility.

#### 3.2.3 Method-by-Method Deep Dive

##### `saveUser(UserModel user)`

```dart
Future<void> saveUser(UserModel user) async {
  final String collection = user.role == 'owner' ? 'owners' : 'developers';
  await _firestore.collection(collection).doc(user.uid).set(user.toMap());
  try {
    await _firestore.collection('users').doc(user.uid).delete();
    final String otherCollection = user.role == 'owner' ? 'developers' : 'owners';
    await _firestore.collection(otherCollection).doc(user.uid).delete();
  } catch (e) { /* ignore */ }
}
```

- **Core logic:**

  1. Determines the target collection based on the user's role.
  2. Writes the user document using `.set()` (upsert — creates or overwrites).
  3. **Cleanup:** Deletes any legacy document in the `users` collection AND any document in the opposite-role collection (handles role changes).

- **Why `.set()` instead of `.update()`?** `.set()` creates the document if it doesn't exist. `.update()` would throw a `NOT_FOUND` error on first signup. Using `.set()` makes `saveUser()` idempotent.

- **Why delete from the other collection?** If a user changes their role from `developer` to `owner`, their old developer document must be removed to prevent ghost data. The try-catch silences errors when there's nothing to delete.

- **Edge case: Concurrent saves.** If two devices save the same user simultaneously, the last write wins (Firestore's default behavior). This could cause data loss if both devices modified different fields. A more robust solution would use `.update()` with `FieldValue.arrayUnion()` for array fields.

##### `getUser(String uid)`

```dart
Future<UserModel?> getUser(String uid) async {
  var devDoc = await _firestore.collection('developers').doc(uid).get();
  if (devDoc.exists) return UserModel.fromMap(devDoc.data()!);
  var ownerDoc = await _firestore.collection('owners').doc(uid).get();
  if (ownerDoc.exists) return UserModel.fromMap(ownerDoc.data()!);
  var legacyDoc = await _firestore.collection('users').doc(uid).get();
  if (legacyDoc.exists) return UserModel.fromMap(legacyDoc.data()!);
  return null;
}
```

- **Waterfall lookup:** Checks three collections in order: `developers` → `owners` → `users` (legacy). Returns the first match.
- **Performance concern:** In the worst case (user doesn't exist), this makes 3 sequential Firestore reads. For a single user lookup, this is acceptable (total latency ~100-300ms). For bulk operations, this would be prohibitive.
- **Why not use a composite index or a lookup table?** Adding a `uid_to_collection` lookup table would add write complexity (must be kept in sync). For a project of this scale, the 3-read waterfall is pragmatic.

##### `getProject(String projectId)` — Complex Auto-Status Logic

```dart
Future<ProjectModel?> getProject(String projectId) async {
  var doc = await _firestore.collection('projects').doc(projectId).get();
  if (doc.exists) {
    var data = doc.data()!;
    data['id'] = doc.id;
    if (!data.containsKey('status')) {
      await _firestore.collection('projects').doc(doc.id).update({'status': 'active'});
      data['status'] = 'active';
    }
    if (data['status'] == 'active') {
      final invites = await _firestore
          .collection('invitations')
          .where('projectId', isEqualTo: projectId)
          .where('status', isEqualTo: 'accepted')
          .get();
      if (invites.docs.isNotEmpty &&
          invites.docs.every((d) => d.data()['devWorkStatus'] == 'finished')) {
        await _firestore.collection('projects').doc(projectId).update({'status': 'ready_for_review'});
        data['status'] = 'ready_for_review';
      }
    }
    return ProjectModel.fromMap(data);
  }
  return null;
}
```

- **Auto-migration:** If a project document has no `status` field (legacy), it's auto-filled with `'active'` and written back to Firestore.
- **Auto-status transition:** When reading a project, the method checks if ALL accepted invitations have `devWorkStatus == 'finished'`. If so, it auto-promotes the project to `ready_for_review`.
- **Architectural concern: Read-triggered writes.** This is a **side-effect-laden read** — calling `getProject()` can modify the database. While pragmatic, this violates the Command-Query Separation (CQS) principle. A production system would use Cloud Functions or scheduled triggers for status transitions.
- **Edge case: Race condition.** If two users read the project simultaneously while the last developer marks their work as finished, both reads will attempt the same status update. Firestore handles this gracefully (the second write is a no-op since the status is already `ready_for_review`), but it generates unnecessary write operations.

##### `streamInvitations(String userId)` — Real-Time Filtered Stream

```dart
Stream<List<InvitationModel>> streamInvitations(String userId) {
  return _firestore
      .collection('invitations')
      .where('receiverId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) {
        final List<InvitationModel> all = snapshot.docs
            .map((doc) => InvitationModel.fromMap(doc.data(), doc.id))
            .toList();
        final filtered = all
            .where((i) => ['pending', 'cancellation_proposed', 'accepted']
                .contains(i.status.toFirestoreString()))
            .toList();
        filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return filtered;
      });
  }
```

- **Client-side filtering:** The Firestore query fetches ALL invitations for the user, then filters client-side to show only `pending`, `cancellation_proposed`, and `accepted` statuses.
- **Why not filter in the Firestore query?** Firestore's `where('status', whereIn: [...])` would work but has a limit of 30 `whereIn` values. More importantly, the stream needs to react to status changes — if an invitation transitions from `pending` to `accepted`, the client-side filter ensures it stays in the list without requerying.
- **Sorting:** Descending timestamp order (newest first). Done client-side because Firestore doesn't support `orderBy` combined with `where` on different fields without a composite index.

##### `updateDevWorkStatus()` — Transactional Status Cascade

```dart
Future<void> updateDevWorkStatus(String inviteId, String projectId, String newStatus) async {
  return _firestore.runTransaction((transaction) async {
    final inviteRef = _firestore.collection('invitations').doc(inviteId);
    transaction.update(inviteRef, {'devWorkStatus': newStatus});
    if (newStatus == 'finished') {
      final snapshot = await query.get();
      bool allFinished = true;
      for (var doc in snapshot.docs) {
        if (doc.id == inviteId) continue;
        if (doc.data()['devWorkStatus'] != 'finished') {
          allFinished = false;
          break;
        }
      }
      if (allFinished && snapshot.docs.isNotEmpty) {
        transaction.update(projectRef, {'status': 'ready_for_review'});
      }
    }
  });
}
```

- **Transaction guarantee:** All reads and writes within `runTransaction()` are atomic. If any read's data changes between the read and the commit, the transaction retries (up to 5 times by default).
- **Logic flow:**

  1. Updates the invitation's `devWorkStatus` to the new value.
  2. If the new status is `'finished'`, queries ALL accepted invitations for the same project.
  3. Checks if every other invitation's `devWorkStatus` is also `'finished'`.
  4. If all finished, promotes the project status to `'ready_for_review'`.

- **Edge case: The developer is the only member.** `snapshot.docs.isNotEmpty` ensures the project transitions even with a single developer.
- **Edge case: Concurrent finish submissions.** Two developers finishing simultaneously will trigger two overlapping transactions. Firestore's transaction retry mechanism ensures exactly one succeeds in updating the project status.

##### `submitReview()` — Triple-Write Transaction

```dart
Future<void> submitReview(Map<String, dynamic> reviewData, String developerId) async {
  return _firestore.runTransaction((transaction) async {
    // 1. Create review document
    transaction.set(reviewRef, {...reviewData, 'timestamp': FieldValue.serverTimestamp()});
    // 2. Update project status to 'completed'
    transaction.update(projectRef, {'status': 'completed'});
    // 3. Update developer's cumulative rating
    final devDoc = await transaction.get(devRef);
    if (devDoc.exists) {
      final newAvg = ((oldAvg * oldCount) + newRating) / newCount;
      transaction.update(devRef, {'ratingCount': newCount, 'avgRating': newAvg});
    }
  });
}
```

- **Atomic triple-write:** All three operations succeed or fail together:

  1. Creates the review document.
  2. Marks the project as `completed`.
  3. Updates the developer's running average rating.

- **Cumulative moving average:** `newAvg = ((oldAvg * oldCount) + newRating) / newCount`. This is O(1) in space (no need to store all past ratings) and O(1) in computation.
- **Edge case: Developer document in wrong collection.** The method reads from `developers` collection specifically. If the developer's document is in the legacy `users` collection, `devDoc.exists` will be `false` and the rating update is silently skipped.

##### `hardDeleteProject(String projectId)` — Cascading Delete

```dart
Future<void> hardDeleteProject(String projectId) async {
  var invites = await _firestore
      .collection('invitations')
      .where('projectId', isEqualTo: projectId)
      .get();
  for (var doc in invites.docs) {
    await doc.reference.delete();
  }
  await _firestore.collection('projects').doc(projectId).delete();
}
```

- **Cascading delete:** First deletes all invitations linked to the project, then deletes the project itself.
- **Why not use `batch()` or `runTransaction()`?** For small invitation counts (typically 1-10), sequential deletes are acceptable. A batch would be more efficient for larger datasets.
- **Missing:** Does NOT delete associated reviews. Orphaned review documents will persist in Firestore.
- **Missing:** Not wrapped in a transaction. If the process crashes midway, some invitations may be deleted while the project remains — an inconsistent state.

##### `proposeCancellation()` and `respondToCancellation()` — Graceful Cancellation Protocol

```dart
Future<void> proposeCancellation(String invitationId, String apology) async {
  await _firestore.collection('invitations').doc(invitationId).update({
    'status': 'cancellation_proposed',
    'apologyNote': apology,
  });
}

Future<void> respondToCancellation(String invitationId, bool approve) async {
  if (approve) {
    await _firestore.collection('invitations').doc(invitationId).update({'status': 'cancelled'});
  } else {
    await _firestore.collection('invitations').doc(invitationId).update({
      'status': 'accepted',
      'apologyNote': FieldValue.delete(),
    });
  }
}
```

- **Two-phase cancellation:** The owner proposes → the developer approves or rejects.
- **If rejected:** Status reverts to `'accepted'` and the `apologyNote` is deleted using `FieldValue.delete()` (completely removes the field from the Firestore document, not just sets it to null).

---

### 3.3 `GitHubApiProvider` — The GitHub REST Client

**File:** `lib/data/providers/github_api_provider.dart` (131 lines)

#### 3.3.1 Why This Class Exists

- Wraps the GitHub REST API v3 for repository, language, README, and contribution data.
- Uses the centralized `ApiClient.github` Dio instance (with retry and logging interceptors).

#### 3.3.2 Key Design Decisions

- **Uses `Dio` instead of `http` package:** Dio provides interceptors (retry, logging), request cancellation, automatic JSON parsing, and query parameter serialization. The `http` package requires all of this to be implemented manually.
- **Typed failure exceptions:** Every method catches `DioException` and re-throws a `GitHubFailure` (from `core/errors/failures.dart`). This ensures GitHub API errors are handled consistently throughout the app.

#### 3.3.3 Method-by-Method Breakdown

##### `fetchUserProfile()` — Authenticated User Profile

```dart
Future<Map<String, dynamic>> fetchUserProfile() async {
  final response = await _dio.get('/user');
  return response.data as Map<String, dynamic>;
}
```

- **Uses `/user` (not `/users/{username}`):** This endpoint returns the profile of the authenticated user (based on the Bearer token in the Authorization header). This ensures the fetched profile matches the logged-in user.

##### `fetchUserRepos(String username)` — Public Repositories

```dart
Future<List<Map<String, dynamic>>> fetchUserRepos(String username) async {
  final response = await _dio.get('/users/$username/repos',
    queryParameters: {'sort': 'updated', 'per_page': 50, 'type': 'owner'});
  return List<Map<String, dynamic>>.from(response.data as List);
}
```

- **`type: 'owner'`:** Excludes forked repositories. Only repos the user created are included.
- **`per_page: 50`:** Caps at 50 repos. The GitHub API allows up to 100, but 50 balances data richness with response time.
- **`sort: 'updated'`:** Most recently updated repos first. This biases toward active projects.

##### `fetchTopLanguages(String username)` — Skill Extraction

```dart
Future<List<String>> fetchTopLanguages(String username) async {
  final repos = await fetchUserRepos(username);
  final Map<String, int> langCount = {};
  for (final repo in repos) {
    final lang = repo['language'] as String?;
    if (lang != null && lang.isNotEmpty) langCount[lang] = (langCount[lang] ?? 0) + 1;
  }
  final sorted = langCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return sorted.take(5).map((e) => e.key).toList();
}
```

- **Frequency-based ranking:** Languages are ranked by how many repos use them, not by lines of code. This is a pragmatic approximation.
- **Top 5:** Returns the 5 most-used languages. This aligns with UI constraints (skill badges typically show 5-8 items).

##### `fetchReadme(String username, String repoName)` — README Extraction for AI Context

```dart
Future<String?> fetchReadme(String username, String repoName) async {
  final response = await _dio.get('/repos/$username/$repoName/readme',
    options: Options(headers: {'Accept': 'application/vnd.github.raw+json'}));
  final content = response.data as String?;
  return content != null && content.length > 2000 ? '${content.substring(0, 2000)}...' : content;
}
```

- **Raw content:** The `Accept: application/vnd.github.raw+json` header returns the README content as raw text instead of base64-encoded JSON.
- **Truncation to 2000 chars:** Prevents excessively large README content from overwhelming the AI context window.
- **Returns `null` on error:** README is optional. A missing README (404) is silently handled, not treated as an error.

##### `exchangeCodeForToken()` — OAuth Token Exchange

```dart
Future<String> exchangeCodeForToken({required String code, required String clientId, required String clientSecret}) async {
  final response = await ApiClient.base.post('https://github.com/login/oauth/access_token', ...);
  final token = data['access_token'] as String?;
  if (token == null || token.isEmpty) throw const GitHubFailure('Failed to obtain access token');
  return token;
}
```

- **Uses `ApiClient.base` instead of `ApiClient.github`:** The token exchange URL (`github.com/login/oauth/access_token`) is NOT part of the GitHub API (`api.github.com`). Using the base Dio client avoids the GitHub API headers.
- **NOTE:** This is a client-side implementation of the token exchange. The preferred (and more secure) approach is the Cloud Function `exchangeGitHubToken` (see Section 7). This method exists as a fallback or for development.

---

## 4. Service Layer

**Directory:** `lib/data/services/`

### 4.1 Architectural Role

- Services sit between providers and controllers, adding **business logic**, **error handling**, and **cross-cutting concerns** (analytics, caching, AI).
- Each service is a **singleton** registered in GetX's dependency container via `Get.put(service, permanent: true)` in `main.dart`.

---

### 4.2 `GroqService` — The AI Intelligence Engine

**File:** `lib/data/services/groq_service.dart` (182 lines — the most complex service)

#### 4.2.1 Why This Service Exists

- Provides AI-powered features: conversational project creation, project idea expansion, developer-project match percentage calculation, and code review suggestions.
- Originally `gemini_service.dart`, migrated to Groq's Llama 3.3 model for faster inference and higher free-tier limits.

#### 4.2.2 Lazy Dio Client Initialization

```dart
Dio? _dio;
Dio get _client {
  if (_dio != null) return _dio!;
  final apiKey = Get.find<RemoteConfigService>().getString(ApiConstants.rcGroqApiKey);
  _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.groqBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
  ));
  return _dio!;
}
```

- **Lazy initialization:** The Dio client is not created until the first API call. This prevents errors during app startup if Remote Config hasn't finished fetching the API key yet.
- **API key from Remote Config:** The Groq API key is NEVER hardcoded in the app binary. It's stored in Firebase Remote Config and fetched at runtime. This means:
  - API keys can be rotated without an app store update.
  - If the key is compromised, it can be changed server-side immediately.
  - The app binary can be safely distributed without exposing secrets.
- **Timeout configuration:** 15s connect timeout, 20s receive timeout. These are generous enough for Groq's typical response time (1-3s) while preventing indefinite hangs on network issues.

#### 4.2.3 `calculateMatch()` — AI-Powered Match Scoring

```dart
Future<double> calculateMatch(String skills, String projectDescription, {Map<String, dynamic>? githubActivity}) async {
  String githubContext = '';
  if (githubActivity != null && githubActivity['error'] == null) {
    githubContext = 'GitHub Activity:\n- Top Languages: ...\n- Recent Repos: ...';
  }
  final prompt = '$githubContext\nRate the match...Return only a number between 0 and 100.';
  final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(result);
  if (match != null) return double.tryParse(match.group(0)!) ?? 0.0;
  return 0.0;
}
```

- **Prompt engineering:** The prompt instructs the LLM to return ONLY a number (0-100). This minimizes token usage and simplifies parsing.
- **GitHub context injection:** If GitHub activity data is available, it's prepended to the prompt for richer context.
- **Regex number extraction:** `RegExp(r'(\d+(\.\d+)?)')` extracts the first number from the LLM response. This is robust against responses like "The match score is 85." or "85/100".
- **Temperature 0.1:** Very low temperature ensures deterministic, consistent scoring.
- **Fallback:** Returns `0.0` on any error (API failure, parsing failure, timeout).

#### 4.2.4 `extractProjectProposal()` — Structured JSON Extraction from Chat

```dart
Future<Map<String, dynamic>?> extractProjectProposal(dynamic history) async {
  final messages = _formatHistory(history);
  messages.add({"role": "system", "content": 'Return ONLY a valid JSON object...'});
  // Uses Groq's "response_format": {"type": "json_object"}
  final content = response.data['choices'][0]['message']['content'];
  return _extractJson(content);
}
```

- **Structured output:** Uses Groq's `response_format: {"type": "json_object"}` to force the LLM to output valid JSON. This significantly reduces JSON parsing failures.
- **Temperature 0.3:** Low but not deterministic — allows slight creativity in descriptions while maintaining structural consistency.
- **`_extractJson()` helper:** Extracts JSON by finding the first `{` and last `}` in the response string. This handles cases where the LLM wraps JSON in markdown code blocks or adds explanatory text.

#### 4.2.5 `expandProjectIdea()` — One-Shot Idea Expansion

- **Temperature 0.7:** Higher temperature for creative expansion — the LLM should suggest imaginative but realistic tech stacks and descriptions.
- **Use case:** When an owner types a brief concept (e.g., "food delivery app"), this method expands it into a full project specification with title, description, and recommended tech stack.

#### 4.2.6 `sendMessage()` — AI Architect Chat

- **Conversational context:** Uses the full chat history (formatted via `_formatHistory()`) to maintain context across multiple messages.
- **Error handling:** Returns a fallback string `'Error connecting to AI Architect.'` instead of null or throwing an exception. This ensures the chat UI always has something to display.

#### 4.2.7 `_formatHistory()` — System Prompt + History Conversion

- **Legacy compatibility:** Converts Gemini-format chat history (where AI responses have `role: 'model'`) to OpenAI-format (where AI responses have `role: 'assistant'`). This is a vestige of the Gemini → Groq migration.
- **System prompt:** Defines the AI's persona as a "DevSync Project Architect" who conducts structured interviews to create project specifications. The system prompt includes a hidden token `[READY_TO_FINALIZE]` that signals when the AI believes it has enough information to generate the final project spec.

#### 4.2.8 Edge Cases

- **Empty API key from Remote Config:** If Remote Config fails to fetch or the key is not set, the Dio client will be created with an empty Authorization header. Every API call will return 401 Unauthorized. The service's catch blocks return default values (`0.0`, `null`, error string) preventing app crashes.
- **Rate limiting (HTTP 429):** Not explicitly handled in `GroqService`. If Groq returns 429, Dio will throw a `DioException` with status code 429. The catch block returns the fallback value. The user sees "Error connecting to AI Architect" without a rate-limit-specific message.
- **Malformed JSON from LLM:** `_extractJson()` attempts to find and parse JSON from the response. If the LLM returns completely invalid JSON (e.g., truncated response), it returns `null`. The calling code handles `null` gracefully.
- **Network timeout:** The 15s/20s timeout is generous but not infinite. On slow networks (e.g., 2G/3G), responses may timeout consistently. There's no retry mechanism in this service (unlike the GitHub API client which has `_RetryInterceptor`).

---

### 4.3 `AnalyticsService` — Behavioral Telemetry

**File:** `lib/data/services/analytics_service.dart` (37 lines)

#### 4.3.1 Why This Service Exists

- Wraps Firebase Analytics to track user behavior: logins, role selections, AI match requests, project creation, and profile refreshes.
- Event data feeds into Firebase Console dashboards for understanding user engagement during the defense demo.

#### 4.3.2 Event Taxonomy

| Category | Event Name | Parameters | Trigger |
| --- | --- | --- | --- |
| Auth | `login` | `loginMethod: 'github'` | GitHub OAuth login |
| Auth | `login` | `loginMethod: 'google'` | Google Sign-In |
| Auth | `sign_out` | — | User signs out |
| Role | `role_selected` | `role: 'developer'/'owner'` | First-time role selection |
| Developer | `ai_match_requested` | — | Developer requests AI matching |
| Developer | `match_viewed` | `project_id` | Developer views a match |
| Developer | `profile_refreshed` | — | Developer refreshes GitHub data |
| Owner | `project_created` | `title` | Owner creates a project |
| Owner | `developer_suggested` | — | AI suggests developers |
| Owner | `project_ai_refined` | — | AI refines project description |
| Owner | `project_template_applied` | `type` | Template selected |

#### 4.3.3 Design Decisions

- **`setUserId(String uid)`:** Ties all subsequent events to a specific user. Called after successful authentication.
- **`setUserRole(String role)`:** Sets a user property (not an event parameter). User properties are persistent across sessions and can be used for audience segmentation in Firebase Console.
- **Private `_event()` helper:** Reduces boilerplate by wrapping `_analytics.logEvent()` with a consistent signature.

---

### 4.4 `FcmService` — Push Notification Management

**File:** `lib/data/services/fcm_service.dart` (55 lines)

#### 4.4.1 Why This Service Exists

- Manages Firebase Cloud Messaging lifecycle: initialization, permission requests, background/foreground message handling, and notification-tap navigation.

#### 4.4.2 Platform Gate

```dart
bool get _fcmSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
```

- **Critical safety check:** FCM is NOT supported on Windows, Linux, or macOS desktop. Without this gate, calling FCM APIs on desktop would crash the app.
- **`kIsWeb`:** Also excludes web because FCM for web requires different initialization (service workers, VAPID keys).

#### 4.4.3 Message Handling Architecture

| State | Handler | Behavior |
| --- | --- | --- |
| **Foreground** | `FirebaseMessaging.onMessage` | Prints debug message. Could show GetX snackbar (commented out). |
| **Background** | `_firebaseMessagingBackgroundHandler` (top-level) | Prints debug message. Must be a top-level function (not an instance method) per FCM requirements. |
| **Terminated** | `_messaging.getInitialMessage()` | Checks if the app was launched from a notification tap. Navigates accordingly. |
| **Notification tap** | `FirebaseMessaging.onMessageOpenedApp` | Navigates based on `data['type']`: `'new_match'` → dev dashboard, `'project_update'` → owner dashboard. |

- **`@pragma('vm:entry-point')`:** Required annotation for the background handler to prevent tree-shaking (the Dart compiler removing "unused" code in release builds).

---

### 4.5 `GithubService` — Lightweight GitHub Data Fetcher

**File:** `lib/data/services/github_service.dart` (35 lines)

#### 4.5.1 Why This Service Exists

- A lightweight alternative to `GitHubApiProvider` for fetching a user's recent repositories and top languages.
- Uses its own Dio instance with the GitHub API base URL.

#### 4.5.2 Differences from `GitHubApiProvider`

| Feature | `GithubService` | `GitHubApiProvider` |
| --- | --- | --- |
| **HTTP Client** | Standalone `Dio()` | Centralized `ApiClient.github` |
| **Authentication** | No auth headers | Bearer token via `ApiClient.setGitHubToken()` |
| **Repos fetched** | Top 10 | Top 50 |
| **Error handling** | Returns error map | Throws `GitHubFailure` |
| **Interceptors** | None | Logging + Retry |

- **Why two GitHub services?** This appears to be a code evolution artifact. `GithubService` was likely the initial, simpler implementation. `GitHubApiProvider` was added later with proper authentication and error handling for the full GitHub analysis flow. Both are kept for backward compatibility.

---

### 4.6 `RemoteConfigService` — Feature Flags & Secret Management

**File:** `lib/data/services/remote_config_service.dart` (56 lines)

#### 4.6.1 Why This Service Exists

- Manages Firebase Remote Config for feature flags and API keys.
- **Critical security function:** API keys for Groq, Gemini, and GitHub OAuth are stored in Firebase Remote Config, NOT in the app binary. This prevents key exposure through APK decompilation.

#### 4.6.2 Configuration Keys

| Key | Type | Purpose | Default |
| --- | --- | --- | --- |
| `gemini_api_key` | `String` | Gemini 1.5 Flash API key (legacy) | `''` |
| `github_client_secret` | `String` | GitHub OAuth client secret | `''` |
| `groq_api_key` | `String` | Groq API key for Llama 3.3 | `''` |
| `pro_features_enabled` | `bool` | Pro tier feature flag | `false` |

#### 4.6.3 Initialization with Triple Try-Catch

```dart
Future<void> init() async {
  try { await _rc.setConfigSettings(...); } catch (_) {}
  try { await _rc.setDefaults({...}); } catch (_) {}
  try { await _rc.fetchAndActivate(); } catch (_) {}
}
```

- **Why three separate try-catches?** Each step can fail independently:
  - `setConfigSettings()` may fail on desktop platforms.
  - `setDefaults()` may fail if the Remote Config instance is in an unexpected state.
  - `fetchAndActivate()` may fail if the device is offline.
- By catching each independently, the service degrades gracefully: if fetching fails, defaults are used. If defaults fail, the last cached values are used.

#### 4.6.4 Empty String Defaults for API Keys

- Default values for API keys are intentionally empty strings (`''`). This allows the app to detect a misconfiguration (e.g., `if (apiKey.isEmpty) showConfigError()`) rather than silently using a placeholder key that would generate cryptic API errors.

---

## 5. Core Infrastructure

**Directory:** `lib/core/`

### 5.1 `ApiClient` — Centralized HTTP Client Factory

**File:** `lib/core/network/api_client.dart` (117 lines)

#### 5.1.1 Why This Class Exists

- Provides singleton Dio HTTP clients with pre-configured timeouts, headers, and interceptors.
- Ensures ALL HTTP requests in the app go through the same logging and retry infrastructure.

#### 5.1.2 Client Types

| Client | Getter | Base URL | Purpose |
| --- | --- | --- | --- |
| GitHub | `ApiClient.github` | `https://api.github.com` | GitHub REST API v3 calls |
| Base | `ApiClient.base` | `''` (none) | Arbitrary URLs (e.g., GitHub OAuth token exchange) |

#### 5.1.3 Singleton Pattern

```dart
class ApiClient {
  ApiClient._(); // Private constructor
  static Dio? _githubClient;
  static Dio? _baseClient;
}
```

- **Private constructor:** Prevents instantiation. All access is through static getters.
- **Lazy singletons:** Clients are created on first access (`??=` null-coalescing assignment).

#### 5.1.4 `_LoggingInterceptor` — Debug-Only Request Logging

```dart
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      print('[API] ${options.method} ${options.path}');
      return true;
    }());
    handler.next(options);
  }
}
```

- **`assert()` trick:** The logging code inside `assert()` runs ONLY in debug mode. In release builds, `assert()` is completely stripped by the Dart compiler, ensuring zero performance overhead.
- **Logs method and path:** e.g., `[API] GET /users/username/repos`.

#### 5.1.5 `_RetryInterceptor` — Automatic Timeout Retry

```dart
class _RetryInterceptor extends Interceptor {
  static const int _maxRetries = 2;
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final retryCount = extra['retryCount'] as int? ?? 0;
    final shouldRetry = retryCount < _maxRetries &&
        (err.type == DioExceptionType.connectionTimeout ||
         err.type == DioExceptionType.receiveTimeout ||
         err.type == DioExceptionType.sendTimeout);
    if (shouldRetry) {
      err.requestOptions.extra['retryCount'] = retryCount + 1;
      await Future.delayed(Duration(seconds: retryCount + 1));
      final response = await dio.fetch(err.requestOptions);
      handler.resolve(response);
    }
  }
}
```

- **Retry conditions:** Only retries on TIMEOUT errors (connect, receive, send). Does NOT retry on 4xx/5xx HTTP errors (those are genuine failures, not transient).
- **Exponential backoff (simplified):** Delays by `retryCount + 1` seconds (1s, 2s). True exponential backoff would use `2^retryCount` (1s, 2s, 4s), but linear backoff is simpler and sufficient.
- **Max 2 retries:** Total of 3 attempts per request (1 original + 2 retries). Prevents infinite retry loops.
- **Retry count tracking:** Uses `requestOptions.extra` (a map for arbitrary metadata) to track how many retries have occurred.

#### 5.1.6 Token Management

```dart
static void setGitHubToken(String token) {
  github.options.headers['Authorization'] = 'Bearer $token';
}
static void clearTokens() {
  github.options.headers.remove('Authorization');
}
```

- **`setGitHubToken()`:** Called after successful GitHub OAuth. Sets the Bearer token on the GitHub Dio client's default headers.
- **`clearTokens()`:** Called on sign-out. Removes the Authorization header to prevent authenticated requests from stale sessions.

---

### 5.2 `ApiConstants` — Centralized Configuration

**File:** `lib/core/constants/api_constants.dart` (51 lines)

#### 5.2.1 Key Constants

| Constant | Value | Purpose |
| --- | --- | --- |
| `githubClientId` | `'Ov23liGJL09c0Oqc2Tbk'` | GitHub OAuth App client ID (public, safe to store client-side) |
| `githubCallbackUrl` | `'https://dev--sync.firebaseapp.com/__/auth/handler'` | OAuth redirect URI |
| `githubCallbackScheme` | `'devsync'` | Custom URL scheme for deep linking |
| `githubApiBase` | `'https://api.github.com'` | GitHub API base URL |
| `groqBaseUrl` | `'https://api.groq.com/openai/v1'` | Groq API base URL |
| `groqModel` | `'llama-3.3-70b-versatile'` | AI model identifier |
| `pythonBackendUrl` | Platform-dependent | Python backend URL (see below) |
| `aiCacheTtl` | 24 hours | Cache duration for AI results |
| `pageSize` | 10 | Default pagination size |

#### 5.2.2 Platform-Dependent Backend URL

```dart
static String get pythonBackendUrl {
  if (kIsWeb) return 'http://localhost:8000';
  if (GetPlatform.isAndroid) return 'http://192.168.1.15:8000';
  return 'http://localhost:8000';
}
```

- **Android-specific IP:** Android emulators cannot use `localhost` (it refers to the emulator itself, not the host machine). The IP `192.168.1.15` is the developer's local machine IP on the LAN.
- **Web and other platforms:** Use `localhost` directly.

---

### 5.3 `Failure` Hierarchy — Typed Error Model

**File:** `lib/core/errors/failures.dart` (36 lines)

#### 5.3.1 Class Hierarchy

```text
Failure (abstract)
├── NetworkFailure    — "Network error occurred"
├── AuthFailure       — "Authentication failed"
├── AIFailure         — "AI matching failed"
├── CacheFailure      — "Cache operation failed"
├── GitHubFailure     — "GitHub API error"
├── FirestoreFailure  — "Firestore operation failed"
└── UnknownFailure    — "Unknown error"
```

- **Why typed failures instead of generic exceptions?**
  - The presentation layer can show **contextual error messages** based on failure type (e.g., "GitHub API is rate-limited" vs. "Your internet connection is unstable").
  - Follows the **Result pattern** (common in Dart/Flutter clean architecture) where functions return `Either<Failure, Success>` instead of throwing exceptions.

- **`const` constructors:** All failures use `const` constructors with default messages. This means error instances can be compile-time constants, reducing garbage collection pressure.

---

## 6. Python Backend

**Directory:** `python_backend/`

### 6.1 Architecture Overview

```text
python_backend/
├── main.py               ← FastAPI application entry point, route definitions, Pydantic models
├── ai_service.py          ← AI analysis engine (seniority classification, skill extraction, bio generation)
├── github_service.py      ← GitHub API data fetcher (repos, languages, stars, contributions)
├── matching_service.py    ← Algorithmic project-developer matching engine
└── requirements.txt       ← Python dependencies
```

### 6.2 Why FastAPI?

- **Automatic validation:** Pydantic `BaseModel` classes validate request bodies automatically. A malformed request returns a 422 Unprocessable Entity with detailed error messages — zero manual validation code.
- **Automatic documentation:** FastAPI generates OpenAPI/Swagger docs at `/docs` and ReDoc at `/redoc`. During the defense demo, the examiner can explore all endpoints interactively.
- **Async support:** `async def` route handlers with `httpx.AsyncClient` enable non-blocking I/O for GitHub API calls.
- **Performance:** FastAPI on Uvicorn handles 2000+ requests/second (compared to Flask's ~200 req/s), making it suitable for batch matching operations.

### 6.3 CORS Configuration

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)
```

- **`allow_origins=["*"]`:** Allows requests from any origin. Necessary because the Flutter web app runs on `localhost:port` during development, and the backend runs on a different port.
- **Security concern:** In production, this should be restricted to the specific frontend domain.

---

### 6.4 `main.py` — Route Definitions

**File:** `python_backend/main.py` (109 lines)

#### 6.4.1 Pydantic Request/Response Models

| Model | Fields | Purpose |
| --- | --- | --- |
| `AnalyzeRequest` | `username: str`, `token: str` | Input for GitHub profile analysis |
| `AnalyzeResponse` | 9 fields (githubUrl, githubSeniority, aiBio, topAiSkills, publicRepos, followers, accountAgeYears, location, topRepositories) | AI analysis results |
| `MatchProjectRequest` | `id`, `techStack`, `description` | Single project for matching |
| `MatchRequest` | `devSkills`, `devSeniority`, `projects` | Batch matching request |
| `MatchResult` | `projectId`, `score` | Single match score |
| `MatchResponse` | `matches: List[MatchResult]` | Batch matching results |

#### 6.4.2 API Endpoints

| Method | Path | Handler | Description |
| --- | --- | --- | --- |
| `GET` | `/` | `read_root()` | Health check with endpoint listing |
| `GET` | `/health` | `health_check()` | Simple health check |
| `POST` | `/analyze` | `analyze_github_profile()` | Full GitHub profile analysis |
| `POST` | `/matches/calculate` | `calculate_matches()` | Batch project-developer matching |

#### 6.4.3 `/analyze` Endpoint — Deep Dive

- **Pipeline:**

  1. **Validation:** Checks for non-empty token (Pydantic validates type, this validates value).
  2. **Data fetch:** `fetch_github_data()` calls GitHub API to gather repos, languages, stars, etc.
  3. **AI analysis:** `analyze_developer_metrics()` computes seniority, generates bio, extracts skills.
  4. **Response:** Maps AI results to the `AnalyzeResponse` schema.

- **Error handling:** Generic `try/except` catches all exceptions and returns HTTP 500. `HTTPException` is re-raised (preserving 400-level errors).

#### 6.4.4 `/matches/calculate` Endpoint — Deep Dive

- **Batch processing:** Calculates match scores for ALL projects in a single request. This avoids N separate HTTP calls from the Flutter app.
- **`p.dict()`:** Converts Pydantic models to plain dicts for the matching service. Note: In Pydantic v2, this method is `p.model_dump()`.

---

### 6.5 `github_service.py` — GitHub Data Extraction

**File:** `python_backend/github_service.py` (110 lines)

#### 6.5.1 Core Function: `fetch_github_data(username, token)`

- **Authentication:** Uses the user's GitHub OAuth access token (`Bearer {token}`) for authenticated API calls. This avoids GitHub's unauthenticated rate limit (60 req/hr) and uses the authenticated limit (5000 req/hr).

- **Data Flow:**

```text
  GitHub API → repos, user profile → Language distribution, star count, topics, top repos → Metrics dict
  ```

- **Step-by-step:**

  1. **Fetch repos:** `GET /users/{username}/repos?sort=updated&per_page=100&type=owner`
  2. **Fetch user profile:** `GET /users/{username}` — extracts followers, public_repos, bio, location, created_at.
  3. **Process repos:** Skips forks, builds language distribution, sums stars, collects topics.
  4. **Build top repos list:** Sorts valid repos by stars (primary) and last update (secondary), takes top 5.

- **Metrics output:**

  ```python
  {
    "username": "...",
    "public_repos": 42,
    "total_stars_earned": 150,
    "language_distribution": {"Python": 5, "JavaScript": 3, ...},
    "repo_topics": ["machine-learning", "flutter", ...],
    "followers": 200,
    "account_age_years": 4,
    "github_bio": "...",
    "location": "Cairo, Egypt",
    "top_repos": [{name, description, language, stargazers_count, forks_count, html_url}, ...]
  }
  ```

#### 6.5.2 Edge Cases

- **API rate limit (403):** Not explicitly handled. The `requests.get()` will succeed but return a 403 response. The status code check will raise a generic exception.
- **User profile fetch fails (non-200):** Falls back to computed values from repos. Ensures the analysis can still proceed with partial data.
- **Invalid `created_at` format:** Wrapped in try-except. If parsing fails, `account_age_years` defaults to 0.
- **Forked repos:** Explicitly excluded from language distribution and star counts.

#### 6.5.3 Uses `requests` Library (Not `httpx`)

- **Synchronous HTTP:** `fetch_github_data()` is a synchronous function. FastAPI can execute sync functions in a thread pool, but it blocks the thread during execution.

---

### 6.6 `ai_service.py` — AI Analysis Engine

**File:** `python_backend/ai_service.py` (91 lines)

#### 6.6.1 Core Function: `analyze_developer_metrics(metrics)`

- **NOT an LLM call.** Despite the "AI" name, this function uses **rule-based heuristics**, not machine learning. It's a deterministic algorithm that classifies developers based on GitHub metrics.

#### 6.6.2 Seniority Classification Algorithm

```python
seniority_score = 0

# Repos factor (0-3 points)
if public_repos >= 40:   seniority_score += 3
elif public_repos >= 20: seniority_score += 2
elif public_repos >= 5:  seniority_score += 1

# Stars factor (0-3 points)
if total_stars >= 50:    seniority_score += 3
elif total_stars >= 15:  seniority_score += 2
elif total_stars >= 5:   seniority_score += 1

# Account age factor (0-3 points)
if account_age_years >= 6:   seniority_score += 3
elif account_age_years >= 3: seniority_score += 2
elif account_age_years >= 1: seniority_score += 1

# Classification (0-9 total)
if seniority_score >= 7:  seniority = "Lead"
elif seniority_score >= 4: seniority = "Senior"
elif seniority_score >= 2: seniority = "Mid-Level"
else:                      seniority = "Junior"
```

- **Composite scoring:** Three equally-weighted factors (repos, stars, account age), each contributing 0-3 points for a maximum of 9.
- **Classification boundaries:** 0-1: Junior, 2-3: Mid-Level, 4-6: Senior, 7-9: Lead.

#### 6.6.3 Skill Extraction

- **Top 8 languages** from repo language distribution (sorted by frequency).
- **Top 3 repo topics** that aren't already in the language list (to avoid duplicates).
- **Maximum 11 skills total** (8 languages + 3 topics).

#### 6.6.4 Bio Generation

- **Priority:** Uses the user's existing GitHub bio if available. Only generates a bio if the user hasn't written one.
- **Generated bio structure:** `"{Seniority} developer with {N} public repositories, specializing in {skills}. Earned {N} stars. Followed by {N} developers."`

---

### 6.7 `matching_service.py` — The Matching Engine

**File:** `python_backend/matching_service.py` (79 lines)

#### 6.7.1 Core Algorithm: `calculate_match_score()`

- **Deterministic scoring:** Unlike the Groq-based match calculation (client-side), this is a purely algorithmic scorer with four weighted components.

#### 6.7.2 Scoring Components

| Component | Weight | Logic |
| --- | --- | --- |
| **Stack Coverage** | 60% | `(matched_skills / total_required_skills) * 60` |
| **Primary Tech Bonus** | 20% | Full 20 points if the developer knows the FIRST item in the tech stack |
| **Description Keywords** | 10% | Only if stack coverage < 30% (fallback). Regex word-boundary matching. |
| **Seniority Bonus** | Up to 20% | Lead: 20, Senior: 12, Mid-Level: 6, Junior: 0 |

- **Score range:** Clamped to `[5.0, 100.0]`. Minimum of 5.0 ensures every developer has a non-zero match.

#### 6.7.3 Tech Alias Normalization

```python
TECH_ALIASES = {
    "react.js": "react", "reactjs": "react",
    "react native": "react-native", "rn": "react-native",
    "node.js": "node", "nodejs": "node",
    "typescript": "ts", "javascript": "js",
    "postgresql": "postgres", "mongodb": "mongo",
    "kubernetes": "k8s", "dart": "flutter",
}
```

- **Why normalization?** A developer with skill "React.js" and a project requiring "ReactJS" should match. Without normalization, string comparison would fail.
- **`dart ↔ flutter` mapping:** Particularly important for DevSync — a Flutter developer inherently knows Dart.
- **Case-insensitive:** All comparisons use `.lower()`.

#### 6.7.4 Description Keyword Matching

```python
if description_lower and stack_score < 30:
    keyword_hits = sum(
        1 for skill in dev_skills_norm
        if re.search(rf'\b{re.escape(skill)}\b', description_lower)
    )
    desc_bonus = min(10.0, keyword_hits * 3.0)
```

- **Conditional activation:** Only activated when stack coverage is below 30%. Prevents double-counting.
- **Word-boundary regex:** `\b` ensures "react" matches "react" but not "reactive".
- **`re.escape()`:** Prevents regex injection if a skill contains special characters (e.g., "C++").

#### 6.7.5 Edge Cases

- **Empty `techStack` AND empty `description`:** Returns 10.0 (base score).
- **Developer with no skills:** Stack coverage 0%, primary tech 0%, seniority is the only factor.
- **Duplicate skills in project tech stack:** Handled by `dict.fromkeys()` deduplication.

---

## 7. Firebase Cloud Functions

**File:** `functions/index.js` (85 lines)

### 7.1 `exchangeGitHubToken` — Secure OAuth Token Broker

#### 7.1.1 Why This Exists

- GitHub OAuth requires a **client secret** to exchange an authorization code for an access token.
- The client secret MUST NOT be stored in the mobile app binary (it would be extractable via APK decompilation).
- This Cloud Function acts as a secure intermediary.

#### 7.1.2 Security Architecture

```text
Flutter App → sends {code} → Cloud Function → sends {code + client_secret} → GitHub → returns {access_token}
                                 ↑
                          Secret stored in
                        Google Secret Manager
```

- **`defineSecret('GITHUB_CLIENT_SECRET')`:** The client secret is stored in Google Cloud Secret Manager, not in the function code.
- **Firebase Functions v2:** Uses the `onCall` trigger which provides built-in authentication context and CORS handling.

#### 7.1.3 Input Validation

```javascript
if (!code || typeof code !== 'string' || code.trim() === '') {
  throw new HttpsError('invalid-argument', 'Missing or invalid "code" parameter.');
}
```

- **Triple validation:** Checks for null/undefined, wrong type, and empty/whitespace-only strings.

#### 7.1.4 Edge Cases

- **Expired authorization code:** GitHub codes expire after 10 minutes. Returns `HttpsError('unauthenticated', ...)`.
- **Secret Manager unavailable:** `githubClientSecret.value()` throws. Caught and returned as `HttpsError('internal', ...)`.
- **Replay attack:** The same authorization code can only be used once. GitHub-enforced security measure.

---

## 8. Firestore Security Rules

**File:** `firestore.rules` (71 lines)

### 8.1 Rule Structure

| Collection | Read | Create | Update | Delete |
| --- | --- | --- | --- | --- |
| `developers/{uid}` | Authenticated | Own UID only | Own UID only | Own UID only |
| `owners/{uid}` | Authenticated | Own UID only | Own UID only | Own UID only |
| `users/{uid}` (legacy) | Own UID only | Own UID only | Own UID only | Own UID only |
| `projects/{id}` | Authenticated | Own UID = `ownerId` | Owner only | Owner only |
| `invitations/{id}` | Authenticated | Authenticated | Sender or Receiver | Sender or Receiver |
| `reviews/{id}` | Authenticated | Own UID = `ownerId` | — | — |
| `notifications/{id}` | Authenticated | ❌ (false) | ❌ (false) | ❌ (false) |

### 8.2 Security Analysis

- **Reviews are write-once:** Once created, a review can never be updated or deleted. This ensures review integrity.
- **Notifications are read-only:** Write-locked to server-side code only. Prevents client-side notification spoofing.
- **Projects require ownership for creation:** `request.resource.data.ownerId == request.auth.uid` ensures a user can't create a project with someone else's UID as the owner.

### 8.3 Security Gaps

- **No field-level validation:** Rules don't validate field types or required fields.
- **No rate limiting:** Firestore rules don't support rate limiting.
- **Invitation access is broad:** Any authenticated user can READ any invitation.

---

## 9. Application Bootstrap (`main.dart`)

**File:** `lib/main.dart` (111 lines)

### 9.1 Initialization Sequence

```text
1. WidgetsFlutterBinding.ensureInitialized()
2. Hive.initFlutter() → Open 'settings' box
3. ThemeController (via Get.put, permanent: true)
4. SystemChrome UI configuration
5. Orientation lock (portrait only)
6. FlavorConfig.setFlavor(FlavorType.pro)
7. Firebase.initializeApp()
8. RemoteConfigService.init()
9. FcmService.init()
10. AnalyticsService (via Get.put)
11. runApp(DevSyncApp())
```

### 9.2 Desktop Firebase Fallback

```dart
try {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
} catch (e) {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    debugPrint('[Firebase] Desktop init failed: $e');
    runApp(const DevSyncApp());
    return;
  }
  rethrow;
}
```

- **Graceful degradation:** On desktop platforms, Firebase may fail to initialize. The app launches anyway with degraded functionality.
- **Mobile rethrow:** On Android/iOS, Firebase initialization failure is fatal.

### 9.3 Flavor Configuration

```dart
FlavorConfig.setFlavor(FlavorType.pro);
```

- **Two flavors:** `free` (limited: 3 projects, 5 matches, no AI matching) and `pro` (unlimited: 999 projects, 999 matches, full AI).
- **Currently hardcoded to `pro`** during development. Production would read from user subscription status.

---

## 10. Cross-Cutting Concerns & Edge Cases

### 10.1 Network Failure Scenarios

| Scenario | Affected Component | Behavior |
| --- | --- | --- |
| **No internet** | All services | Firestore uses cached data. HTTP calls fail with timeout. Groq returns fallback values. |
| **Slow network (>15s)** | ApiClient | Retry interceptor activates (up to 2 retries with linear backoff). |
| **GitHub rate limit (403)** | GitHubApiProvider | Throws `GitHubFailure`. UI shows error toast. |
| **Groq rate limit (429)** | GroqService | Catch block returns `0.0` or `null`. UI shows generic error. |
| **Firestore permission denied** | FirebaseProvider | Throws `FirebaseException`. Propagates to controller's error handler. |
| **Python backend unreachable** | Flutter HTTP calls | Connection timeout → retry → eventual failure. |

### 10.2 Data Consistency Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| **Denormalized name/photo stale** | UI shows old owner name on projects | Acceptable trade-off. Full fix: Cloud Function trigger on user update. |
| **Developer rating in wrong collection** | Rating update silently skipped | Migration to single `users` collection or explicit collection check. |
| **Orphaned review after project delete** | Reviews reference deleted project | Add cascading delete for reviews in `hardDeleteProject()`. |
| **Concurrent transaction conflicts** | Firestore auto-retries (up to 5x) | Acceptable. Exponential backoff built into Firestore SDK. |

### 10.3 Security Considerations

| Concern | Status | Detail |
| --- | --- | --- |
| **API keys in APK** | ✅ Mitigated | Keys stored in Remote Config, not in binary. |
| **GitHub client secret** | ✅ Secure | Stored in Google Secret Manager, used only in Cloud Function. |
| **Firestore rules** | ⚠️ Partial | No field-level validation. No rate limiting. |
| **Python backend CORS** | ⚠️ Wide open | `allow_origins=["*"]` in development. Restrict for production. |
| **Firebase project ID in binary** | ℹ️ By design | Public value. Firebase security relies on auth + rules, not project ID secrecy. |

---

## 11. Defense Q&A — 25 Aggressive Examiner Questions

### Models & Data Layer

**Q1:** "Why don't you use `freezed` or `json_serializable` for your data models? Manual serialization is error-prone."

- **Answer:** For 4 models totaling ~430 lines, the productivity gain of code generation (`freezed`, `json_serializable`) does not justify the overhead of integrating `build_runner` into the CI/CD pipeline. Manual serialization provides:
  - Full visibility during defense — every line of serialization logic is auditable.
  - Zero build complexity — no `flutter pub run build_runner build` step that can fail or produce stale generated code.
  - Easier onboarding — new team members don't need to learn code generation concepts.
  - For a larger project (20+ models), `freezed` would be strongly recommended for its `copyWith`, `==` equality, and union type support.

**Q2:** "Your `UserModel.fromMap()` doesn't take a document ID parameter, but `InvitationModel.fromMap()` does. Why the inconsistency?"

- **Answer:** This reflects a fundamental difference in how the two models relate to their Firestore documents:
  - `UserModel`: The document ID IS the user's `uid`, which is also stored as a field inside the document (via `toMap()` which includes `'uid': uid`). The `fromMap()` method reads `uid` from the map data itself, making the document ID redundant as a separate parameter.
  - `InvitationModel`: The document ID is auto-generated by Firestore (`.add()`), so it's NOT stored as a field inside the document. The `fromMap()` method must receive it as a separate parameter to include it in the model.

**Q3:** "Your `InvitationModel` has 6 status states. How do you prevent invalid state transitions (e.g., `cancelled → accepted`)?"

- **Answer:** Currently, state transition validation is NOT enforced at the model or provider level. In the current implementation:
  - **UI-level enforcement:** The presentation layer only shows valid action buttons based on the current status.
  - **Firestore rules enforcement:** The rules validate that only the sender or receiver can update, but don't validate the status transition itself.
  - **Production improvement:** Implement a state machine validator in `FirebaseProvider` that checks `(currentStatus, newStatus)` against a transition table.

**Q4:** "You have a `UserRole` enum but never use it in `UserModel`. The `role` field is a `String`. Why not use the enum directly?"

- **Answer:** Firestore cannot store Dart enums natively — it can only store primitive types. Using `String` ensures seamless serialization/deserialization. The `UserRole` enum exists as a presentation-layer convenience. The helper getters (`isDeveloper`, `isOwner`) provide the same type-safety without requiring enum serialization.

**Q5:** "The `ReviewModel.fromMap()` will crash with a `NullPointerException` if the Firestore document has no `timestamp` field. Why isn't this null-safe?"

- **Answer:** This is an intentional design decision based on the invariant that `timestamp` is ALWAYS present:
  - `ReviewModel.toMap()` uses `FieldValue.serverTimestamp()`, which is populated by Firestore on every write.
  - Reviews are ONLY created through `submitReview()`. There's no code path that creates a review without a timestamp.
  - Making it null-safe would mask a legitimate data integrity issue.

### Provider & Service Layer

**Q6:** "Your `FirebaseProvider.getProject()` has a side effect — it writes to the database during a read. Doesn't this violate Command-Query Separation (CQS)?"

- **Answer:** Correct — this violates CQS. Justification: For a graduation project, this pragmatic approach reduces the number of Cloud Functions needed. The alternative — a Firestore `onUpdate` trigger Cloud Function — would add deployment complexity and cold-start latency. Production fix: Extract the status transition logic into a Cloud Function triggered by invitation updates.

**Q7:** "You have `getUser()` doing a 3-collection waterfall lookup. What if you have 10,000 users? Isn't this a performance problem?"

- **Answer:** Firestore document reads by ID are O(1) regardless of collection size. Three sequential O(1) reads total ~100-300ms, acceptable for a single user profile load. For bulk operations, `getDevelopers()` reads from a single collection. The waterfall exists solely for backward compatibility with the legacy `users` collection.

**Q8:** "Your `GroqService` fetches the API key from Remote Config on first access. What if Remote Config hasn't fetched yet?"

- **Answer:** The initialization sequence in `main.dart` ensures `RemoteConfigService.init()` completes BEFORE `runApp()`. If `fetchAndActivate()` fails (offline launch), `setDefaults()` has already set the key to `''`. The catch blocks in `GroqService` methods handle the resulting 401 gracefully.

**Q9:** "The `_RetryInterceptor` only retries on timeouts. What about HTTP 500 (server error) or 503 (service unavailable)?"

- **Answer:** Intentional restriction:
  - 500/503 are often non-transient (bug in request). Retrying produces the same error.
  - Timeouts ARE transient (temporary network congestion). Retrying after delay often succeeds.
  - Production enhancement: Add retry for 503 and 429 with `Retry-After` header respect.

**Q10:** "Why do you have TWO GitHub services — `GithubService` and `GitHubApiProvider`?"

- **Answer:** Evolutionary artifact. `GithubService` (35 lines) was the initial lightweight implementation. `GitHubApiProvider` (131 lines) is the mature implementation with auth, retry, and typed errors. Both exist for backward compatibility. Recommended fix: Migrate all usages to `GitHubApiProvider` and delete `GithubService`.

### Python Backend

**Q11:** "Your Python backend `ai_service.py` doesn't use any AI/ML at all. It's just if-else logic. Why call it 'AI'?"

- **Answer:** The module uses **rule-based expert system** techniques, a valid subset of artificial intelligence. Why not use an LLM? Seniority classification requires deterministic, consistent results — an LLM would produce different labels on repeated runs. Why not ML? Training requires labeled data of GitHub profiles with ground-truth seniority. The rule-based approach works with zero training data.

**Q12:** "Your matching algorithm weights sum to more than 100% (60+20+10+20=110%). Isn't that a bug?"

- **Answer:** The description bonus is ONLY applied when stack coverage is below 30% — it's a fallback, not a parallel factor. In practice: high stack coverage (≥30%) maxes at 100 (60+20+20). Low stack coverage (<30%) maxes at 68 (18+20+10+20). The `min(100.0, ...)` clamp ensures the output is always ≤100.

**Q13:** "Your tech aliases map `dart` to `flutter`. But knowing Dart doesn't mean you know Flutter."

- **Answer:** Pragmatic trade-off for DevSync's context. In the Flutter ecosystem, virtually all Dart developers are Flutter developers. False positives are preferable to false negatives. Improvement: bidirectional mapping with weighted multipliers.

**Q14:** "Your `github_service.py` uses synchronous `requests` inside an async FastAPI handler. Won't this block the event loop?"

- **Answer:** FastAPI handles sync functions via thread pool. However, the sync `requests` calls DO block the thread. Under high concurrency, the thread pool could be exhausted. Fix: Replace `requests` with `httpx.AsyncClient` and make `fetch_github_data()` async.

**Q15:** "Your Python backend has no authentication. Anyone can call `/analyze`."

- **Answer:** Currently relies on network-level security (localhost/private network). Production fix: Add Firebase Auth token verification middleware, API key authentication, and deploy behind an API gateway with rate limiting.

### Security & Infrastructure

**Q16:** "Your Firestore security rules don't validate field types. A malicious client could write garbage data."

- **Answer:** Correct. Current mitigation: Flutter app validates data at UI/controller layers. Production fix: Add `request.resource.data.keys().hasAll([...])` and type checks for critical fields in Firestore rules.

**Q17:** "Remote Config stores API keys that are cached on the client. Can't a user extract them?"

- **Answer:** A rooted/jailbroken user could extract cached values. Mitigation: API keys are for services with built-in rate limiting (damage limited to quota exhaustion). The GitHub client secret is in Secret Manager, never reaches the client. Production: Use Firebase App Check.

**Q18:** "You're hardcoded to `FlavorType.pro`. How would you handle real Free vs Pro enforcement?"

- **Answer:** Production enforcement: Server-side via Firestore rules checking subscription status. Client-side via purchase verification (RevenueCat, Google Play Billing). Remote Config's `pro_features_enabled` serves as a global kill switch.

### Architecture & Design Decisions

**Q19:** "Why not use Bloc or Riverpod instead of GetX?"

- **Answer:** GetX was chosen for development speed and minimal learning curve. Trade-offs acknowledged: implicit dependencies harder to test. For production enterprise, Riverpod preferred. Counter-argument: GetX has 12,000+ GitHub stars and production usage.

**Q20:** "Your application has no offline support. What happens without connectivity?"

- **Answer:** Firestore provides built-in offline support: cached reads, queued writes, and local snapshot events. Features requiring real-time data (new invitations, AI) won't work offline. The app could detect connectivity and show an offline banner.

**Q21:** "How does the app handle concurrent writes (e.g., two owners reviewing the same developer)?"

- **Answer:** `submitReview()` uses a Firestore transaction with optimistic concurrency control. If data changes between read and write, the transaction retries (up to 5 times). The cumulative moving average formula is commutative — final result is the same regardless of commit order.

**Q22:** "Your `_formatHistory()` accepts `dynamic`. This is not type-safe."

- **Answer:** Pragmatic concession to the Gemini → Groq migration. The chat history format changed but some screens still pass the old format. `dynamic` allows handling both formats. Improvement: Define a `ChatMessage` model class and convert both formats before passing.

**Q23:** "Your scoring algorithm treats all tech stack items equally. 'React' as primary framework is more important than 'ESLint'."

- **Answer:** Addressed via the Primary Tech Bonus (20% weight) for the FIRST item in `techStack`. This assumes the owner lists the most important technology first (enforced by the UI). Improvement: diminishing weights for subsequent items.

**Q24:** "What happens if the Groq API key is compromised?"

- **Answer:** Multiple defense layers:

  1. Groq's free tier has 14,400 req/day and 30 req/min limits — damage capped.
  2. Key can be rotated via Firebase Remote Config within 1 hour.
  3. No billing on free tier — no charges to rack up.
  4. Firebase App Check (recommended) would verify genuine app instances.

**Q25:** "Your entire system depends on Firebase. What if Firebase has an outage?"

- **Answer:** Firebase has 99.95% uptime SLA. During an outage:
  - Reads: Firestore offline persistence serves cached data.
  - Writes: Queued locally, synced when recovered.
  - Auth: Cached session keeps authenticated users active.
  - AI features: Groq API operates independently.
  - Python backend: Operates independently.
  - For production: Multi-cloud redundancy would be considered.

---

> **End of Phase 1 Documentation**
>
> **Next Phase:** Phase 2 — Presentation Layer (Screens, Widgets, Controllers, Navigation) will document `lib/presentation/` and `lib/app/` directories with the same exhaustive depth.

---

*Generated by the Lead Enterprise Software Architect for the DevSync Graduation Project Defense Wiki.*
