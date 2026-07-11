# 📁 docs/04_Core_Infrastructure_and_Providers.md

# Phase 4: Core Infrastructure & System Orchestration

## 1. The "Why": Architectural Justifications

*   **Centralized Core Layer (`lib/core/`):** In a team environment, scattering API keys, hardcoded HTTP clients, and error strings across UI views leads to immediate fragmentation. The `core` directory acts as the single source of truth for the entire Flutter app. It guarantees that if the Python backend IP changes, or if GitHub deprecates an API version, a junior developer only needs to modify one file (`api_constants.dart` or `api_client.dart`), instantly propagating the fix across all 40+ UI views without risk of regression.
*   **Provider Pattern Abstraction (`lib/data/providers/`):** Why not inject `FirebaseFirestore.instance` directly into GetX Controllers? **Testability and Swap-ability.** By wrapping all database transactions in the `FirebaseProvider`, the controllers are completely decoupled from Firebase's proprietary SDK. If the enterprise decides to migrate from Firebase to Supabase or AWS Amplify, only the `FirebaseProvider` class requires rewriting. The presentation layer remains completely untouched.
*   **Typed Error Boundaries (`failures.dart`):** Using raw Dart `Exception` objects provides zero context on *where* the system failed. By enforcing an `abstract class Failure` with explicit implementations (`NetworkFailure`, `GitHubFailure`, `FirestoreFailure`), the UI can deterministically render distinct error states (e.g., "Check your WiFi" vs. "GitHub token expired") rather than a generic "Something went wrong" dialog.

---

## 2. Micro-Level Breakdown

### `ApiClient` & Dio Interceptors (`lib/core/network/api_client.dart`)
*   **Singleton Pattern via Static Getters:** It maintains distinct instances for `_githubClient` and `_baseClient`. This is critical because hitting `api.github.com` requires very specific headers (`Accept: application/vnd.github+json`) that would cause HTTP 400 Bad Request errors if accidentally piped to the Python backend.
*   **`_RetryInterceptor`:** Network instability on mobile is inevitable. This custom interceptor intercepts `DioException`. If the error type is `connectionTimeout`, `receiveTimeout`, or `sendTimeout`, it reads an injected `retryCount` flag. It then triggers an exponential backoff (`Future.delayed(Duration(seconds: retryCount + 1))`) and recursively re-executes the raw request up to `_maxRetries` (2) before finally yielding to the UI.

### `FirebaseProvider` (`lib/data/providers/firebase_provider.dart`)
*   **Cross-Collection Migrations:** `saveUser()` handles role changes. If a "developer" signs up as an "owner", it creates the new doc in the `owners` collection and aggressively deletes the duplicate UID from the `developers` and legacy `users` collections to prevent data corruption.
*   **Atomic Transactions (`runTransaction`):** In `updateDevWorkStatus()`, when a developer's invite hits `finished`, the system must check if *all* accepted developers on the project are finished, and if so, flip the global project status to `ready_for_review`. Using `runTransaction` ensures that if multiple developers click "Finish" simultaneously, the database state remains perfectly atomic and avoids race conditions.
*   **Review Mathematics:** `submitReview()` uses a transaction to atomically calculate the new floating-point average rating: `newAvg = ((oldAvg * oldCount) + newRating) / newCount`, preventing desyncs under heavy concurrent review loads.

### `GitHubApiProvider` (`lib/data/providers/github_api_provider.dart`)
*   **LLM Context Optimization:** When fetching `fetchReadme()`, the raw markdown can sometimes exceed 20,000 characters. If this was sent blindly to the Groq API, it would trigger a massive token overflow error. The provider actively intercepts the `String?`, truncating it explicitly: `content.substring(0, 2000) + '...'` to guarantee token safety before the data ever leaves the core layer.

---

## 3. Exhaustive Edge Cases & Mitigations

*   **Edge Case: Token Expiration During a Firestore Transaction**
    *   *Scenario:* The user's Firebase Auth token expires the exact millisecond `FirebaseProvider.submitReview()` fires its `.runTransaction()`.
    *   *Mitigation:* The Firebase SDK inherently queues offline writes and manages token refreshing under the hood. However, if a hard permission rejection occurs, the `runTransaction` block throws a `FirebaseException`. The Controller layer catches this, wrapping it in a `FirestoreFailure`, halting the UI loading spinner, and preventing a local optimistic UI update that would otherwise leave the client visually out-of-sync with the server.
*   **Edge Case: Malformed Python Backend IP Resolution**
    *   *Scenario:* A developer tests the app on a physical Android device while the Python server is running on `localhost`. The phone attempts to route to its own internal loopback address instead of the development machine.
    *   *Mitigation:* `ApiConstants.pythonBackendUrl` uses a dynamic getter. It checks `kIsWeb` (returning `localhost`), then checks `GetPlatform.isAndroid` (returning a hardcoded LAN IP like `192.168.1.15`), guaranteeing the physical device routes correctly across the local subnet.
*   **Edge Case: Corrupted Stream State (Enum Mismatches)**
    *   *Scenario:* The database contains old `status` strings from an MVP phase (e.g., `Status.Pending` vs `pending`).
    *   *Mitigation:* `streamMyJoinRequests` explicitly filters incoming documents through a hardcoded whitelist (`['join_request', 'accepted', 'declined']`). If an orphaned document with a corrupted state enters the stream, it is silently dropped at the `FirebaseProvider` level, ensuring the presentation layer never attempts to parse an unknown enum, which would trigger a fatal red-screen crash.

---

## 4. Defense Q&A (For Aggressive Examiners)

*   **Q1: In `FirebaseProvider.dart`, your `streamInvitations` method fetches all snapshot documents and then filters them in Dart memory (`all.where((i) => ...)`). Isn't doing client-side filtering a massive anti-pattern that wastes bandwidth and ruins Firestore pricing?**
    *   *Answer:* Yes, executing `.where` filters on the client side after fetching the entire collection is a severe anti-pattern in NoSQL, as Firebase bills per document read. We accepted this technical debt for the MVP because Firebase compound queries (`.where('status', whereIn: [...])`) require building complex composite indexes in the Firebase Console. For an enterprise launch, this would be immediately migrated to a server-side `whereIn` query to guarantee $O(1)$ bandwidth scaling.
*   **Q2: The `ApiClient` maintains a Singleton `Dio` instance via a static getter. If a user logs out and a new user logs in, how do you prevent the new user from accidentally hijacking the old user's GitHub Bearer token?**
    *   *Answer:* This is explicitly mitigated by the `clearTokens()` method inside `api_client.dart`. During the `AuthController.signOut()` sequence, we invoke `ApiClient.clearTokens()`, which aggressively invokes `github.options.headers.remove('Authorization')`. This guarantees the singleton is purged of all state, preventing cross-session token bleed.
*   **Q3: The `_RetryInterceptor` in your network layer waits `retryCount + 1` seconds before retrying. What happens if the user closes the app or navigates away during that delay? Does it cause an unhandled memory exception?**
    *   *Answer:* The `Dio` package natively supports `CancelToken`. If the user navigates away, the `GetX` controller's `onClose()` method can trigger `cancelToken.cancel()`. If the `_RetryInterceptor` wakes up from its `Future.delayed` and attempts to execute `dio.fetch()`, `Dio` instantly intercepts the cancelled state and throws a `DioExceptionType.cancel`, bypassing the retry loop and safely dying without mutating the disposed UI.
*   **Q4: Your error handling (`failures.dart`) defines typed failures, but looking at your `GitHubApiProvider`, you throw `GitHubFailure('message')`. Why throw custom strings instead of utilizing Internationalization (i18n) keys?**
    *   *Answer:* Hardcoding English strings deep in the core provider layer is indeed a violation of robust localization principles. The core layer should only throw the pure `GitHubFailure` object. It is the responsibility of the Presentation layer (or a dedicated ErrorMapper service) to intercept `GitHubFailure` and map it to an i18n key (e.g., `tr('errors.github_failed')`) based on the user's current locale. This separation of concerns will be enforced in the V2 refactoring.
*   **Q5: Why did you hardcode the `ApiConstants.vapidKey` for Firebase Cloud Messaging directly in the Dart file? Isn't committing secrets to version control a critical security vulnerability?**
    *   *Answer:* VAPID keys (Voluntary Application Server Identification) for web push notifications are explicitly considered *public* keys. They act as the public half of an asymmetric cryptographic pair, allowing the browser to verify that the push message originated from our server (which holds the private key). Therefore, exposing the VAPID key in client-side source code is entirely safe and architecturally required by the Web Push protocol. Private secrets, like `gemini_api_key`, are securely fetched via Firebase Remote Config (`rcGeminiApiKey`).
