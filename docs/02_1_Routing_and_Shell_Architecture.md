# 📁 docs/02_1_Routing_and_Shell_Architecture.md

# Phase 2.1: App Routes & Core Shell Architecture (GetX)

## 1. App Routes (`lib/app/routes/`)

### The "Why": Architectural Justifications
*   **GetX Named Routing Strategy:** We utilized GetX named routes (`Get.toNamed`) rather than inline widget pushing (`Get.to(() => View())`). This decouples the presentation layer from navigation logic, allowing deep linking, easier middleware injection, and cleaner parameter passing.
*   **Centralized Route Dictionary (`AppRoutes`):** Hardcoding strings across the app invites silent, typo-driven crashes. Defining routes as `static const String` in an abstract class enforces compile-time safety and serves as a single source of truth for the application's topology.

### Micro-Level Breakdown: `AppRoutes` & `AppPages`
*   **`AppRoutes` (Constants Contract):** A purely abstract class declaring path constants (e.g., `'/login'`, `'/main-shell'`, `'/match-results'`).
*   **`AppPages` (Route Registry & Bindings):**
    *   **Registry Array:** Maps string paths to their respective Flutter Views.
    *   **Coupled Dependency Injection:** Every `GetPage` strictly pairs a `View` with its `Binding` (e.g., `DeveloperDashboardView` with `DeveloperBinding`). This guarantees that whenever a route is resolved, its prerequisite controllers are securely injected into memory before the view renders, and subsequently garbage-collected when the route is popped.
    *   **Initial Entrypoint:** Defines `AppPages.initial = '/onboarding'`, funneling all fresh app launches through the authentication pipeline before any shell components are rendered.

### Exhaustive Edge Cases & Mitigations
*   **Edge Case: Unauthorized Deep Linking & Route Bypassing.**
    *   *Scenario:* A user attempts to push a route like `/owner-dashboard` via an intent or deep link without valid authentication.
    *   *Mitigation:* While `AppPages` handles registry, the architectural defense relies on the `AuthController` evaluating the auth state post-onboarding. Future iterations should implement GetX `GetMiddleware` to guard routes automatically.
*   **Edge Case: Controller Memory Leaks on Rapid Navigation.**
    *   *Scenario:* A user rapidly taps back and forth between `/project-details` and `/match-results`, potentially abandoning orphaned controllers in RAM.
    *   *Mitigation:* By enforcing route-level bindings via `AppPages`, GetX's `SmartManagement.full` (default) aggressively disposes of controllers the moment their associated route is removed from the stack.

---

## 2. Core Shell (`lib/presentation/modules/main_shell/`)

### The "Why": Architectural Justifications
*   **Single Unified Shell Pattern:** Rather than duplicating the `Scaffold` and `BottomNavigationBar` across 8 different views (4 for Developers, 4 for Owners), we implemented a single `MainShellView`. This adheres to the DRY principle and prevents UI tearing during tab transitions.
*   **`IndexedStack` Navigation:** `IndexedStack` keeps all child views in the widget tree but only paints the active one. This preserves local state (like scroll positions, text field inputs, and pagination) when users switch between tabs, providing a seamless, app-like experience rather than a janky web-like reload.

### Micro-Level Breakdown
*   **`MainShellBinding` (Dependency Injection):**
    *   **Lazy Instantiation:** Uses `Get.lazyPut` to register controllers (`DeveloperController`, `MatchesController`, `OwnerController`, `DevInvitationsController`). These are not instantiated immediately upon shell load; they are held in a factory pattern and only consume RAM when their specific tab is tapped.
    *   **Global Components:** Injects the `AIChatController` here because the AI Chat button exists globally above the tabs.
*   **`MainShellController` (Reactive State & Stream Management):**
    *   **Role-Forked Initialization:** Inside `_setupListeners()`, the controller reads `user.role` from `AuthController`. It dynamically opens completely different Firestore streams based on whether the user is a `developer` (listening to incoming invites) or `owner` (listening to project join requests).
    *   **Idempotency Caches:** Utilizes `Set<String> _notifiedInviteIds` and `Set<String> _notifiedJoinStatusIds`. This is a critical micro-optimization that prevents Firebase stream updates (which fire on *any* document change) from triggering repetitive, duplicate snackbars for the same event.
    *   **Dynamic Navigation Arrays:** The `pages` (List of Widgets) and `navItems` (List of BottomNavigationBarItem) getters dynamically rebuild the entire bottom navigation schema based on the role, completely sandboxing developers from owner views.
    *   **Stream Cleanup (`onClose`):** Strictly cancels `_invitationSub`, `_joinRequestStatusSub`, and `_ownerBadgeSub` to prevent severe memory leaks and "called on null" crashes when the shell unmounts during logout.
*   **`MainShellView` (Presentation Layer):**
    *   **Reactive Stack:** `Obx(() => IndexedStack(...))` wraps the body, reacting instantly to `currentIndex.value` changes.
    *   **Role-Specific Floating UI:** Contains an `Obx` that checks `user?.isOwner == true` to render the floating AI Assistant button. *(Note: Code documentation highlights a critical bug fix where the auth flag was previously checked as 'manager' instead of 'owner')*.

### Exhaustive Edge Cases & Mitigations
*   **Edge Case: Zombie Streams Post-Logout (Fatal Crash).**
    *   *Scenario:* User logs out. The shell unmounts, but the active Firestore streams in `MainShellController` receive a late snapshot update, attempting to access a null `user.uid`.
    *   *Mitigation:* The `onClose()` lifecycle hook strictly calls `.cancel()` on all `StreamSubscription` instances, severing the Firebase connection precisely as GetX removes the controller from memory.
*   **Edge Case: `IndexedStack` Initial Memory Bloat (OOM).**
    *   *Scenario:* Loading 4 heavy dashboards into the `IndexedStack` simultaneously causes an Out-Of-Memory (OOM) crash on low-end Android devices.
    *   *Mitigation:* Because `MainShellBinding` uses `Get.lazyPut`, the underlying controllers (and their heavy Firebase data fetches) are deferred. `IndexedStack` renders the dormant widgets, but their business logic remains inactive until accessed.
*   **Edge Case: Notification Spam via Firebase Batch Writes.**
    *   *Scenario:* An owner accepts 10 developers at once. Firebase sends a batch snapshot. The app fires 10 snackbars overlapping simultaneously, freezing the UI.
    *   *Mitigation:* The controller utilizes local `Set<String>` caches. It checks if the `invite.id` combined with its status exists in the set before dispatching `Get.snackbar`.

---

## 3. Defense Q&A (For Aggressive Examiners)

*   **Q1: Why did you use `IndexedStack` instead of standard `Get.to()` or `Navigator.push()` for your bottom tabs? Doesn't `IndexedStack` keep everything in memory and risk crashing the app?**
    *   *Answer:* `IndexedStack` does keep child widgets in the element tree, but we mitigated the memory risk by strictly enforcing `Get.lazyPut` in the `MainShellBinding`. The heavy lifting—Firebase streams, data processing, and state allocations—does not occur until the user actually taps the tab. We chose this over `Navigator.push` because `push` destroys and recreates the UI, losing the user's scroll position and causing unnecessary Firestore read operations (incurring financial cost) every time they switch tabs.
*   **Q2: Your `MainShellBinding` initializes major controllers like `MatchesController` and `OwnerController` simultaneously via `lazyPut`. What if a Developer somehow triggers the `OwnerController`? Is there a security breach?**
    *   *Answer:* No. `Get.lazyPut` simply registers a builder function in GetX's dependency injection map; it does not execute code or fetch data. The security barrier is enforced at the View layer via `MainShellController.pages`, which strictly builds `[DeveloperDashboardView...]` for developers. The `OwnerController` is never summoned from the DI container by the UI, meaning it remains an unexecuted lambda function in memory. Furthermore, backend Firestore rules prevent a developer from reading owner collections anyway.
*   **Q3: In `MainShellController`, you use `Set<String> _notifiedInviteIds` to track notifications. What happens if this Set grows indefinitely over a multi-day session? Will it cause a memory leak?**
    *   *Answer:* In a real-world edge case, a massive set of strings could theoretically consume noticeable RAM. However, UUIDs are highly memory-efficient. A user would need to receive tens of thousands of invitations in a single session for it to measure even a megabyte. Additionally, this Controller is destroyed on logout, flushing the Set entirely. If scale demands it, we can implement an LRU (Least Recently Used) cache or time-to-live (TTL) on the Set entries.
*   **Q4: Your `AppPages` array hardcodes `OnboardingView` as the initial route. How do you handle deep linking or silent background authentication where the user shouldn't see onboarding?**
    *   *Answer:* Currently, our `AuthController` resolves the session state immediately upon boot. If a persistent token exists, the `AuthController` programmatically overrides the initial route and instantly pushes `/main-shell`. In an enterprise scaling scenario, we would transition to using `GetMiddleware` in `AppPages` to intercept the `/onboarding` route request and automatically redirect to the shell before a single frame is painted.
*   **Q5: You conditionally render the Floating AI Button in `MainShellView` by checking `user?.isOwner == true`. What prevents a malicious user from modifying their local app binary to bypass this `if` statement and access the AI features?**
    *   *Answer:* UI-level hiding is purely for User Experience, not security. If a malicious developer patches the binary to display the AI button, they will face the second layer of defense: the `AIChatController` and the Python Backend. Any request made to the Gemini AI API endpoints requires the user's JWT token. The backend verifies the token's claims, sees the role is `developer`, and rejects the API call with a `403 Forbidden` status. The UI button would be an empty, non-functional shell.
