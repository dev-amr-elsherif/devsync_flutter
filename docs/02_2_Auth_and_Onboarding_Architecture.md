# 📁 docs/02_2_Auth_and_Onboarding_Architecture.md

# Phase 2.2: Authentication & Onboarding Architecture (GetX)

## 1. The "Why": Architectural Justifications

*   **Role-First Onboarding Strategy:** Rather than a generic "Sign Up" button, the `OnboardingView` explicitly forks the user journey immediately (`Developer` vs. `Project Manager`). This isolates the OAuth providers (GitHub for Devs, Google for Owners), ensuring that developers are forced to provide an assessable codebase, while owners use a trusted enterprise provider.
*   **Native Providers (Google/GitHub) over Firebase UI:** We opted for manual SDK integration (`GoogleSignIn` and `GithubAuthProvider`) rather than the drop-in `Firebase UI` library. This provides granular control over the OAuth tokens (specifically extracting the GitHub `accessToken`), custom UI design (Glassmorphism), and the ability to inject the Python AI analysis pipeline mid-flight before the user is considered fully "logged in".
*   **Biometric Authentication Integration:** Biometric Auth (FaceID/TouchID) acts as a secondary local authentication layer. Architecturally, it sits between the `_auth.authStateChanges()` emission and the `_navigateBasedOnRole()` execution. The `AuthController` state machine holds the Firebase session as valid but suspends routing to `/main-shell` until the `LocalAuthentication` promise resolves, preventing unauthorized physical access to active developer sessions.

---

## 2. Micro-Level Breakdown

### Core UI Logic & UX (Glassmorphism)
*   **`OnboardingView` & `_RoleCard`:** Implements a heavily customized UI using `GlassCard` widgets. The background utilizes a custom `_OrbPainter` with an `AnimationController` running a continuous 12-second loop. This creates an ambient, premium, "glassmorphism" aesthetic that masks the loading latency of OAuth redirects.
*   **`AnalysisLoadingView`:** A dedicated interstitial screen deployed strictly for Developers. While the UI visually cycles through predefined text steps via `_simulateSteps()`, the background logic asynchronously fires a request to the Python backend (`/analyze`) with the user's GitHub token to generate the AI portfolio profile.

### `AuthController` State Management
*   **Reactive State:** `currentUser` (`Rx<UserModel?>`) acts as the absolute source of truth for the entire application. It is bound to the shell and dictates global permissions.
*   **`_syncUserProfile`:** Upon receiving a valid `User` from Firebase, the controller silently fetches the corresponding `UserModel` from Firestore, synchronizes local state, registers the `uid` with the `AnalyticsService`, and only then triggers navigation.
*   **Profile Hydration (`_createOrUpdateProfile`):** A robust method utilizing the `.copyWith()` pattern to merge existing database data with new Firebase Auth data and the dynamic `aiAnalysis` map, ensuring no data loss occurs during repeated logins.

### Navigation Race Condition Handling (Centralized Auth Listener)
*   Instead of writing `Get.toNamed('/main-shell')` inside every single login function (which risks race conditions if Firebase updates the token asynchronously), navigation is strictly delegated to `_setupAuthListener()`.
*   This listener binds directly to `_auth.authStateChanges()`. Whether the user signs in via GitHub, Google, or is restored from a cold boot, the listener guarantees a centralized, single-entry funnel for all routing, making state desyncs virtually impossible.

---

## 3. Exhaustive Edge Cases & Mitigations

*   **Edge Case: Network Drops During OAuth Interception (`AnalysisLoadingView`)**
    *   *Scenario:* The user successfully authenticates via GitHub, routing them to `AnalysisLoadingView`. Mid-analysis, the 5G connection drops. The Python server fails to respond.
    *   *Mitigation:* The `dio.post` call is wrapped in a `try/catch`. If it fails, `_hasError` is flagged to `true`, halting the `_simulateSteps()` visual loop immediately. A fallback UI (`_buildErrorState`) renders, allowing the user to "Go Back" rather than being soft-locked in an infinite loading spinner.
*   **Edge Case: Biometric Cancellation or Timeout**
    *   *Scenario:* Firebase auto-logs the user in on boot, triggering the biometric prompt. The user cancels the prompt or the sensor fails.
    *   *Mitigation:* The Firebase JWT token remains valid in secure storage, but the `AuthController` explicitly intercepts the `_navigateBasedOnRole` function. The user is bounced back to a localized "Unlock App" screen rather than destroying the remote Firebase session, saving network requests and SMS quotas.
*   **Edge Case: Token Expiration During Role Selection**
    *   *Scenario:* A user leaves the GitHub OAuth browser window open for hours, returns, and completes the login, but the token is instantly stale.
    *   *Mitigation:* The `FirebaseAuth` SDK automatically handles token refresh under the hood. However, if the custom GitHub `accessToken` extracted via `(credential.credential as dynamic).accessToken` is expired when sent to the Python backend, the backend must return a 401. The Flutter client catches this 401 in `_startAnalysis()`, displays the error, and forces a re-auth via `refreshDeveloperPortfolio()`.

---

## 4. Defense Q&A (For Aggressive Examiners)

*   **Q1: Why rely on `_auth.authStateChanges()` as a global listener instead of handling navigation immediately after awaiting the `signInWithProvider` method? Doesn't a global stream listener create unpredictable race conditions?**
    *   *Answer:* Actually, *not* using the global listener creates the race condition. If we manually pushed the route inside `loginAsOwner()`, a cold boot of the app would have no way to auto-route the user because `loginAsOwner()` wasn't explicitly clicked. By binding strictly to `_auth.authStateChanges()`, we create a deterministic, unidirectional data flow. The Firebase SDK acts as the sole source of truth; when the token exists and is valid, the stream fires, and the app routes. This unifies cold boots and manual logins into the exact same code path.
*   **Q2: You are fetching the GitHub Access Token via `(credential.credential as dynamic).accessToken`. Isn't dynamic typing an egregious security and stability risk in production Dart code?**
    *   *Answer:* It is a known workaround for a specific limitation in the `firebase_auth` Flutter SDK. The `OAuthCredential` class does not natively expose the `accessToken` getter across all providers equally in its public interface, despite the token existing in the underlying platform channel map. By casting to `dynamic`, we bypass the strict type checker to extract the token required for our Python AI backend. We mitigate the stability risk by wrapping this specific extraction in an isolated `try/catch` inside `_getGithubAccessToken()`, ensuring that if the internal SDK structure changes in the future, the app degrades gracefully rather than crashing.
*   **Q3: How does the `AnalysisLoadingView` securely interact with your Python backend? What prevents a malicious user from spoofing the `/analyze` endpoint with a fake username and token?**
    *   *Answer:* The architecture is designed so that the Python backend performs its own server-to-server validation. When the Flutter app sends the `username` and `token` to `/analyze`, the Python backend does not blindly trust it. It uses that specific `token` to make an authenticated request to the GitHub API. If the token is fake, expired, or doesn't belong to that username, GitHub rejects the backend's request, and our Python server subsequently returns an error to the Flutter client.
*   **Q4: You inject `FirebaseProvider` and `GroqService` as `fenix: true` in `AuthBinding`, but `AuthController` is `permanent: true`. Why the discrepancy? Doesn't this lead to zombie connections?**
    *   *Answer:* `permanent: true` guarantees that the `AuthController` is never destroyed, which is mandatory because it maintains the global `authStateChanges()` listener for the entire lifecycle of the app. `fenix: true` for the providers means they can be purged from memory if the OS runs low on RAM, but GetX will automatically recreate them the next time `AuthController` calls `Get.find()`. This is an aggressive memory optimization strategy; we keep the tiny state listener alive permanently, but allow the heavy networking providers to be garbage collected when dormant.
*   **Q5: If a database permissions error occurs during `_createOrUpdateProfile` (e.g., Firestore rules block the write), what happens to the user's session? Are they logged into Firebase but locked out of the app?**
    *   *Answer:* Yes, they are technically authenticated with Firebase Auth but lack a synchronized Firestore document. Our architecture handles this via the `try/catch` block inside `_createOrUpdateProfile`. We catch the `'permission-denied'` exception and trigger a specific `Get.snackbar` alerting the user. Crucially, because `currentUser.value` is only updated *after* a successful Firestore save, `isLoggedIn` remains false for the UI layer. The user is held at the Onboarding screen and denied access to `/main-shell`, preventing a desynchronized phantom session from wreaking havoc in the app.
