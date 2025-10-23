## Guest Login Implementation and Guards

### Overview
This document summarizes the guest login feature added to allow users to access the Home screen and play episodes without authentication, while redirecting any restricted navigation or actions (Earn, Library, Wallet, Profile, Subscribe/Unsubscribe) to the login screen. It also documents the UI change to center the "Continue as Guest" link with an icon.

### Goals
- Allow unauthenticated users to enter a limited "guest" session.
- Grant access to Home and podcast playback.
- Redirect guests to login when they tap restricted tabs or attempt subscription actions.
- Prevent background/auth-required providers and API calls from firing in guest mode.
- Make the guest entry point clearly visible on the login screen.

---

## Implementation Details

### 1) Guest Session State
- `UnifiedAuthService` exposes guest helpers (proxied to `StorageService`):
  - `setGuestMode(bool)` and `isGuestMode()`
- `StorageService` persists the guest flag under key `guest_session`.

Files:
- `lib/core/services/unified_auth_service.dart`
- `lib/core/services/storage_service.dart`

Behavior:
- Real login/registration explicitly disables guest mode to avoid mixed state.

### 2) Login Screen: Enter Guest Mode
- Added handler to start guest session and navigate to `home-screen`.
- Ensured guest mode is cleared after successful login/registration.

Files and key methods:
- `lib/presentation/authentication_screen/authentication_screen.dart`
  - `_continueAsGuest()` → sets guest mode true and `Navigator.pushReplacementNamed(..., AppRoutes.homeScreen)`
  - After login/register → `await _unifiedAuthService.setGuestMode(false)`

### 3) Bottom Navigation: Guard Tab Taps for Guests
- Guests tapping `Earn`, `Library`, `Wallet`, or `Profile` are redirected to the authentication screen.

Files:
- `lib/widgets/common_bottom_navigation_widget.dart`
  - On tap, checks `isGuestMode()`; if guest and tab index != 0 → push replacement to `AppRoutes.authenticationScreen`.

### 4) Main Navigation: Guard Initial Route and Provider Initialization
- If a guest deep-links to a non-home tab route, redirect to login.
- Limit provider initialization in guest mode to prevent unauthenticated calls and errors.

Files:
- `lib/widgets/enhanced_main_navigation.dart`
  - `_setInitialTab()` → if guest and route != home → redirect to login.
  - `_initializeProviders()` → guests initialize only `HomeProvider`; authenticated users init `HomeProvider`, `LibraryProvider`, and `ProfileProvider` in parallel.

### 5) Subscriptions: Prevent Guest Errors on Podcast Detail
- Guests should not fetch or mutate subscriptions.
- Skipped backend fetch for subscriptions in guest mode.
- Subscribe/Unsubscribe actions redirect to login when in guest mode.

Files:
- `lib/providers/subscription_provider.dart`
  - `fetchAndSetSubscriptionsFromBackend()` → if guest, no-op and clear local set without error.
- `lib/services/subscription_helper.dart`
  - `handleSubscribeAction(...)` → if guest, redirect to `AppRoutes.authenticationScreen` and return.

### 6) Session and Splash Flow
- Guests are allowed to land directly on `home-screen` from the splash based on session evaluation.

Files:
- `lib/core/services/session_service.dart`
  - `getInitialRoute()` → if no valid session but guest mode is true, return `AppRoutes.homeScreen`.

---

## UI Update: Centered "Continue as Guest" Link with Icon

To improve discoverability, the guest entry was moved closer to the Forgot Password area and centered with an icon.

Files:
- `lib/presentation/authentication_screen/authentication_screen.dart`

Changes:
- Replaced the right-aligned text link with a centered `TextButton.icon` beneath Forgot Password.
- Uses `Icons.person_outline` and underlined styling to match the app theme.

Result:
- The guest entry is visible without scrolling and clearly conveys its purpose.

---

## Testing Checklist

- Fresh app launch (not logged in):
  - Splash navigates to `home-screen` when guest mode is active.
  - Bottom nav: tapping `Earn`, `Library`, `Wallet`, `Profile` redirects to login.
  - Home episodes can be played.

- Login screen:
  - "Continue as Guest" is centered beneath Forgot Password with a user icon.
  - Tapping it navigates to `home-screen`.

- Podcast detail:
  - No subscription fetch error displayed for guests.
  - Tapping Subscribe/Unsubscribe redirects to login.

- Authentication:
  - After successful login/register, guest mode is disabled and subscriptions sync.
  - Navigating tabs works without redirects.

---

## Notes

- If any additional screen performs auth-required API calls at load time, guard them with `isGuestMode()` and skip or redirect accordingly.
- Navigation redirect patterns use `Navigator.pushReplacementNamed` to avoid back-stacking protected screens behind the login screen.


