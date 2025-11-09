# Authentication Guide

## Overview
This app uses biometric authentication (Face ID, Touch ID) with device passcode as a fallback option for secure access to stored passwords.

---

## Authentication Methods

### iOS & Android
1. **Primary:** Biometric authentication (adapts to device capabilities)
2. **Fallback:** Device passcode (PIN/Pattern/Password)
3. **User Choice:** "Use Passcode" option always available

---

## How It Works

### 1. App Launch Authentication Flow

```
App Opens
    ↓
Check if device supports biometrics
    ↓
    ├─→ YES → Show biometric prompt (Face ID/Touch ID)
    │         ↓
    │         User can choose:
    │         • Use biometric authentication
    │         • Tap "Use Passcode" for fallback
    │         • Cancel authentication
    │
    └─→ NO → Proceed directly to app
              (or prompt user to set up biometrics)
```

### 2. Biometric Setup Prompt (Strongly Encouraged)

If biometrics are supported but not enrolled, the app will guide you through setup on **BOTH iOS and Android**.

#### The App Flow:

```
Device supports biometrics but not enrolled
    ↓
Show Setup Dialog (non-dismissible by tapping outside)
    ↓
User sees benefits:
• Quick and secure access
• No need to remember anything
• Passcode fallback available
• Industry recommendation badge
    ↓
User chooses:
├─→ "Set Up Now" (Recommended)
│   ↓
│   Platform-specific guidance
│   ↓
│   Verification after setup
│   ↓
│   Success feedback
│
└─→ "Use Passcode Only" (Secondary option)
    ↓
    Proceed with passcode authentication
    (Biometrics can be enabled later)
```

#### Platform-Specific Implementation:

**Android (Fully Automated):**
1. ✅ Shows "Setting up biometric authentication..." snackbar
2. ✅ Automatically opens biometric enrollment settings:
   - Android 11+ (API 30+): Direct biometric enrollment
   - Android 10 and below: Security settings page
3. ✅ Shows "Please complete the setup..." reminder
4. ✅ Waits for user to return to app
5. ✅ Verifies biometric enrollment automatically
6. ✅ Shows success message: "Biometric authentication is now active!"
7. ✅ If not enrolled: "Biometrics not detected. You can set them up later..."

**iOS (Guided with Manual Steps):**
1. ✅ Shows detailed snackbar: "Go to Settings > Face ID & Passcode..."
2. ✅ 6-second duration for user to read instructions
3. ✅ Prompts authentication to verify setup
4. ✅ Tests Face ID/Touch ID or passcode availability
5. ✅ Verifies biometric enrollment automatically
6. ✅ Shows success message: "Biometric authentication is now active!"
7. ✅ If not enrolled: "Biometrics not detected. You can set them up later..."

#### Key Features (Both Platforms):

✅ **Non-dismissible dialog** - Must choose an option (no accidental close)
✅ **Clear benefits explained** - Security, convenience, and fallback
✅ **Generic, user-friendly messaging** - Works across all biometric types
✅ **Platform-agnostic** - Same experience on iOS and Android
✅ **Automatic verification** - Checks if biometrics are actually enrolled
✅ **Visual feedback** - Success (green) or reminder (orange) messages
✅ **Error handling** - Graceful fallback if settings can't be opened
✅ **Accessibility option** - "Use Passcode Only" always available

#### Why We Strongly Encourage This (Both Platforms):

- 🔒 **Security:** Password managers require strong authentication
- ⚡ **Convenience:** Instant unlock with biometrics
- 📱 **User Experience:** Industry standard for financial/security apps
- ♿ **Accessibility:** Passcode fallback ensures everyone can use the app
- 🔄 **Flexibility:** Can be changed later in device settings

---

## Visual Comparison

### Setup Dialog (Same for Both Platforms)

```
┌────────────────────────────────────────┐
│  🔒 Secure Your Passwords              │
├────────────────────────────────────────┤
│                                        │
│  Secure your passwords with biometric  │
│  authentication for quick and safe     │
│  access.                               │
│                                        │
│  • Unlock instantly                    │
│  • Enhanced security                   │
│  • Passcode backup available           │
│                                        │
│  ℹ️ Recommended for password managers  │
│                                        │
│  ┌──────────────┐  ┌─────────────────┐│
│  │Use Passcode  │  │  Set Up Now  ✓  ││
│  │     Only     │  │                 ││
│  └──────────────┘  └─────────────────┘│
└────────────────────────────────────────┘
```

### Android Setup Flow

```
Tap "Set Up Now"
    ↓
"Setting up biometric authentication..." (blue snackbar)
    ↓
[Android Settings Opens Automatically]
    ↓
User enrolls fingerprint/face
    ↓
Returns to app
    ↓
"Please complete the biometric setup..." (snackbar)
    ↓
App verifies enrollment
    ↓
"✓ Biometric authentication is now active!" (green snackbar)
```

### iOS Setup Flow

```
Tap "Set Up Now"
    ↓
"Go to Settings to enroll biometric authentication" (blue snackbar, 5s)
    ↓
[User manually opens Settings app]
    ↓
User enrolls biometrics
    ↓
Returns to app
    ↓
Authentication prompt: "Verify biometric or passcode authentication"
    ↓
User tests authentication
    ↓
App verifies enrollment
    ↓
"✓ Biometric authentication is now active!" (green snackbar)
```

### If User Skips Setup

```
Tap "Use Passcode Only"
    ↓
Proceed to app immediately
    ↓
Uses device passcode for authentication
    ↓
(User can enable biometrics later in device Settings)
```

---

## Code Implementation

### Main Authentication (lib/feature/auth/auth.dart)

```dart
authenticated = await auth.authenticate(
  localizedReason: 'Authenticate to access your passwords',
  authMessages: <AuthMessages>[
    const AndroidAuthMessages(
      signInTitle: 'Authentication required!',
      cancelButton: 'No thanks',
    ),
    const IOSAuthMessages(
      localizedFallbackTitle: 'Use Passcode',  // Fallback option
      cancelButton: 'Cancel',
    ),
  ],
);
```

### Key Points:

1. **No `biometricOnly` flag:** 
   - Allows passcode fallback
   - Previous version had `biometricOnly: true` which blocked passcode usage

2. **`localizedFallbackTitle: 'Use Passcode'`:**
   - Shows a button in the iOS biometric dialog
   - Lets users choose passcode instead of biometrics
   - Appears below the Face ID/Touch ID prompt

3. **Platform-specific messages:**
   - Android: "No thanks" button
   - iOS: "Use Passcode" button

---

## User Experience

### Authentication Prompt (All Devices)

```
┌─────────────────────────────────┐
│                                 │
│  [Biometric Indicator]          │
│  (Face/Fingerprint/etc.)        │
│                                 │
│  Unlock to access your          │
│        passwords                │
│                                 │
│     [Use Passcode] button       │ ← Fallback option
│                                 │
│          [Cancel]               │
│                                 │
└─────────────────────────────────┘
```

### Passcode Fallback

When user taps "Use Passcode":
```
┌─────────────────────────────────┐
│                                 │
│      Enter Passcode             │
│                                 │
│      [●] [●] [●] [●] [●] [●]   │
│                                 │
│      Number pad appears         │
│                                 │
└─────────────────────────────────┘
```

---

## Device Support

### All Modern Devices
- **iOS:** Automatically detects and uses Face ID, Touch ID, or passcode
- **Android:** Automatically detects and uses fingerprint, face unlock, iris scan, or PIN/pattern
- **Behavior:** Adapts to whatever biometric hardware is available on the device

### Devices without Biometrics
- Older devices without biometric sensors
- **Behavior:** Uses device passcode (PIN/Pattern/Password) directly

---

## Security Considerations

### Why Allow Passcode Fallback?

1. **Accessibility:** Not all users can use biometric authentication
2. **Convenience:** Biometrics might fail (wet fingers, poor lighting, masks)
3. **User Choice:** Some users prefer passcode for privacy reasons
4. **Device Security:** The device passcode is still secure (set by user in Settings)

### Security Guarantees:

✅ **User must be authenticated** - Either by biometrics OR passcode
✅ **Device-level security** - Uses system authentication, not custom implementation
✅ **No bypass** - Cannot access app without passing authentication
✅ **Session management** - Authentication required on each app launch

### What We DON'T Do:

❌ Store passwords in the app itself
❌ Implement custom authentication (less secure)
❌ Allow authentication bypass
❌ Send credentials over network

---

## Testing Authentication

### Test Scenarios:

1. **Happy Path - Biometrics:**
   - Launch app
   - Use Face ID/Touch ID
   - ✅ App unlocks

2. **Fallback - Passcode:**
   - Launch app
   - Tap "Use Passcode" on iOS or "No thanks" on Android
   - Enter device passcode
   - ✅ App unlocks

3. **Cancel Authentication:**
   - Launch app
   - Tap "Cancel"
   - ✅ App closes or returns to previous screen

4. **No Biometrics Enrolled:**
   - Device without biometrics set up
   - ✅ Prompt to set up biometrics or proceed

5. **Biometric Failure:**
   - Failed Face ID/Touch ID attempts
   - After multiple failures, system automatically offers passcode
   - ✅ User can enter passcode

---

## Troubleshooting

### Issue: "Use Passcode" button not showing

**Cause:** Using `biometricOnly: true` in authentication options

**Solution:** Remove `biometricOnly` flag (already done in current implementation)

### Issue: Authentication not working on simulator

**iOS Simulator:**
- Face ID: Hardware → Face ID → Enrolled
- To authenticate: Hardware → Face ID → Matching Face
- To fail: Hardware → Face ID → Non-matching Face

**Android Emulator:**
- Settings → Security → Add fingerprint
- Use emulator fingerprint button during auth

### Issue: Always defaults to passcode

**Cause:** Biometrics not enrolled on device

**Solution:** 
- iOS: Settings → Face ID & Passcode → Set up Face ID
- Android: Settings → Security → Fingerprint

---

## Configuration Options

### Update Authentication Messages

**File:** `lib/feature/auth/auth.dart`

```dart
// Customize messages
const IOSAuthMessages(
  localizedFallbackTitle: 'Use Passcode',  // Change fallback text
  cancelButton: 'Cancel',                   // Change cancel button
)
```

### Change Authentication Reason

```dart
await auth.authenticate(
  localizedReason: 'Your custom message here',
  // ...
);
```

---

## Migration Notes

### From Previous Version:

**Old Implementation (Riverpod 2.x):**
```dart
authenticated = await auth.authenticate(
  localizedReason: 'Authenticate to access your passwords',
  options: const AuthenticationOptions(
    stickyAuth: true,
    biometricOnly: true,  // ❌ Blocked passcode fallback
  ),
);
```

**New Implementation (Riverpod 3.x):**
```dart
authenticated = await auth.authenticate(
  localizedReason: 'Authenticate to access your passwords',
  authMessages: <AuthMessages>[
    const IOSAuthMessages(
      localizedFallbackTitle: 'Use Passcode',  // ✅ Allows passcode fallback
    ),
  ],
);
```

**Key Changes:**
1. Removed `options` parameter (deprecated in local_auth 3.x)
2. Added `authMessages` for platform-specific customization
3. Default behavior now allows passcode fallback
4. More explicit user choice with "Use Passcode" button

---

## Best Practices

### Do's ✅

1. **Always provide fallback option** - Not all biometrics work 100% of time
2. **Clear messaging** - Tell users what they're authenticating for
3. **Handle errors gracefully** - Don't crash on auth failure
4. **Test on real devices** - Simulators behave differently
5. **Support accessibility** - Passcode is essential for some users

### Don'ts ❌

1. **Don't use `biometricOnly: true`** - Blocks essential fallback
2. **Don't store sensitive data unencrypted** - Even with auth
3. **Don't customize too much** - Users expect standard system UI
4. **Don't require auth for non-sensitive features** - Balance security and UX
5. **Don't skip error handling** - Auth can fail for many reasons

---

## Related Packages

- **local_auth:** ^3.0.0 - Biometric authentication
- **local_auth_android:** ^2.0.0 - Android-specific implementation
- **local_auth_darwin:** ^2.0.0 - iOS/macOS-specific implementation

---

## Additional Resources

- [local_auth Package](https://pub.dev/packages/local_auth)
- [iOS Biometric Authentication](https://developer.apple.com/documentation/localauthentication)
- [Android Biometric Authentication](https://developer.android.com/training/sign-in/biometric-auth)
- [Flutter Security Best Practices](https://docs.flutter.dev/security)

---

## Changelog

### Version 1.0.3+2 (November 8, 2025) - Latest Update

#### Biometric Setup Enhancement (Both Platforms)
- ✅ **iOS:** Comprehensive biometric enrollment guidance
  - Non-dismissible setup dialog with benefits
  - Detailed instructions for Face ID/Touch ID setup
  - Automatic verification after enrollment
  - Success/reminder feedback messages
  
- ✅ **Android:** Fully automated biometric enrollment
  - Non-dismissible setup dialog with benefits  
  - Automatic launch of biometric settings
  - Platform-appropriate messaging (fingerprint/face)
  - Automatic verification after enrollment
  - Success/reminder feedback messages

#### Authentication Improvements
- ✅ Added passcode fallback for iOS authentication
- ✅ Platform-specific authentication messaging
- ✅ "Use Passcode" option prominently displayed
- ✅ Migrated to Riverpod 3.0 authentication API
- ✅ Removed deprecated `biometricOnly` flag
- ✅ Enhanced error handling and user feedback

#### User Experience
- ✅ Non-dismissible setup dialog (prevents accidental skip)
- ✅ Clear benefits explanation with icon
- ✅ Generic, crisp messaging - platform-agnostic and user-friendly
- ✅ "Recommended for password managers" badge
- ✅ Two-option flow: "Set Up Now" (primary) or "Use Passcode Only" (secondary)
- ✅ Visual feedback with color-coded snackbars
- ✅ Automatic enrollment verification
- ✅ Simplified language: "Unlock to access your passwords"

### Previous Versions
- Used `biometricOnly: true` which blocked passcode access
- Limited accessibility for users who couldn't use biometrics
- No guided biometric setup process
- Basic authentication prompts without context

---

**Status:** ✅ Fully Implemented
**Authentication Methods:** Biometrics (primary) + Passcode (fallback)
**Platforms:** iOS 13.0+, Android
**Package Version:** local_auth ^3.0.0

