# Launch checklist

Living list for taking Bonuses from this checkout to a store-ready build. **Keep this file in sync with the code.** When you change Stripe, auth, env, login/demo accounts, or store identifiers, update the matching row and the “Verified against” line.

**Verified against:** `origin/main` `fe7f88d` (2026-11-04).  
**Version in `pubspec.yaml`:** `1.0.0+1`.  
**Payments:** stay mock until launch. Do **not** set `DEMO_MODE=false` as a product cutover. Do **not** delete user or company data.

Status in this file:

| Label | Meaning |
| --- | --- |
| Done | True of the current tree |
| In flight | Designed / tasked, not in this tree |
| Upcoming | Explicitly deferred (crash reporting, TestFlight / Play App Distribution) |
| Not started | Needed for launch; no work in tree |
| Owner | Dashboard / store / secrets action, not a code change |
| Do not flip | Must stay as-is until this checklist says otherwise |

---

## Hard rules

- **Do not enable live Stripe.** `AppConfig.demoMode` defaults to `true`. `AppConfig.useMockStripe` is true when demo is on **or** Supabase is not configured. Leave that default until every Stripe and auth row below is Done.
- **Do not enable live Kling.** `kling-secret` is test-mode only (`sk_test_`). It is not wired in Flutter (BON-42) and has no webhook handler (BON-41). Do not set `sk_live_` or treat a successful function deploy as a product cutover.
- **Do not delete data.** Do not mass-wipe SharedPreferences or drop Supabase tables as part of launch prep. Logged-out login no longer has “Reset Demo Data”.
- **Do not commit secrets.** `.env`, `*.env`, `STRIPE_SECRET_KEY`, and `KLING_SECRET_KEY` stay out of git and out of Flutter `--dart-define`.
- **Owner-only** (even after review/CI): live payments, secret rotation, and any data deletion.

---

## 1. Live Stripe (mock until launch)

**Do not flip.** Default path is mock. The Edge Function exists so launch is a config change, not a rewrite.

| Item | Status | Current code |
| --- | --- | --- |
| Mock is the default | Done | `lib/config/app_config.dart`: `DEMO_MODE` default `true`; `useMockStripe` is true when demo is on or Supabase is not configured |
| Secret key not in the Flutter app | Done | `STRIPE_SECRET_KEY` is not a dart-define. `env.example` tells you not to put it there. Function secret template: `supabase/functions/.env.example` |
| Secret-key HTTP goes through Edge Function | Done | `lib/services/stripe_service.dart` `_invokeSecretAction` → `functions.invoke('stripe-secret')`. Source: `supabase/functions/stripe-secret/index.ts` |
| Card confirm / Apple Pay still mock | Done (must stay until launch) | `processPayment`, `createApplePayPaymentIntent`, `processApplePayPayment` always simulate. `PaymentService` is local/mock |
| `DEMO_MODE=false` product cutover | **Do not flip** | Live `createPaymentIntent` / customer / subscription / payment methods / cancel only when demo is off **and** Supabase is configured |
| JWT gate on `stripe-secret` | In flight | `supabase/config.toml` has `verify_jwt = false` because app auth is still local. Callers with the public anon `apikey` can invoke the function. See §2 |
| Real PaymentIntent confirmation | Not started | Even on the live create-intent path, the payment form does not confirm with the publishable key + `client_secret` |
| Function deploy + `STRIPE_SECRET_KEY` secret | Owner | Source is in repo; deploy is not done in this pass. Project id in `supabase/config.toml` |

Launch flip (only when this whole file is ready; **not now**):

1. Auth hardening (§2) merged and demo Auth users created.
2. Redeploy `stripe-secret` with `verify_jwt = true`.
3. Confirm a live `pk_live_` / `sk_live_` (or keep test keys for an internal beta).
4. Then — and only then — build with `DEMO_MODE=false` and real `SUPABASE_*` / `STRIPE_PUBLISHABLE_KEY`.

Until that flip, a successful checkout in the app is **mock money**.

---

## 1b. Kling (second provider; mock until launch)

**Do not flip.** Server-only Edge Function so Icelandic card subscriptions can launch later without a rewrite. Stripe stays as-is. Payments in the app stay mock.

| Item | Status | Current code |
| --- | --- | --- |
| Edge Function source | Done | `supabase/functions/kling-secret/index.ts`. Path A: checkout session (embedded overlay), billing portal, subscriptions API. `payment_method_type` / `collection_method` forced to `card`. ISK integers as-is (no x100) |
| Secret key not in the Flutter app | Done | `KLING_SECRET_KEY` is `Deno.env` only. `env.example` tells you not to dart-define it. Placeholder: `supabase/functions/.env.example` |
| Test-mode only | Done | POST refuses a missing key or any key that is not `sk_test_`. Live keys (`sk_live_`) return 500 and do not call Kling |
| Flutter client | Not started | BON-42. No `kling-secret` invoke in `lib/` |
| Webhook handler | Not started | BON-41. No `X-Kling-Signature` / `KLING_WEBHOOK_SECRET` in this function |
| Function deploy + `KLING_SECRET_KEY` secret | Owner | Source is in repo; deploy is not done in this pass. Test-mode key only, project `hkpkznslzkgnijoahggn` |

---

## 2. Auth hardening (Supabase Auth + `stripe-secret` JWT)

**In flight.** Planned as BON-12. **Not implemented on this branch.**

| Item | Status | Current code |
| --- | --- | --- |
| Running-app login | Done (local) | `AuthService.login` uses `StorageService` passwords only. It prints `DEBUG: Using local storage authentication`. Logout does not call Supabase Auth |
| Supabase Auth helpers exist, unused by login | Done (dead path) | `SupabaseService.signIn` / `signUp` / `signOut` wrap `client.auth`; `AuthService` does not call them |
| Session restore | Done (local) | `AuthService.isLoggedIn` reads `StorageService.getCurrentUser()` only |
| Email + bcrypt (local) | Done | `PasswordService` bcrypt with SHA-256 / plaintext migrate-on-login. Client-side `RateLimitService` |
| Login → `signInWithPassword`, profile by email | In flight | BON-12: when Supabase is initialized, Auth is source of truth; local password fallback only if Supabase is missing/failed (tests, unconfigured demo) |
| Logout signs out of Auth | In flight | Not wired |
| Session restore requires live Auth session when Supabase is up | In flight | Not wired |
| `stripe-secret` `verify_jwt = true` + `auth.getUser()` | In flight | Today `verify_jwt = false`; handler does not call `auth.getUser()`. No amount cap / currency allowlist / per-user rate limit in the function yet (those are part of the same plan) |
| Create matching Auth users for demo emails | Owner | Required after BON-12 merge so seeded demo passwords still work. Turn **Confirm email** off (or auto-confirm). Keep **Anonymous sign-ins** off |
| New employees get an Auth user | Not started | Admin create-employee still sets local default `password123` (`admin_dashboard.dart`). That will not sign in under Auth until a matching `auth.users` row exists |

Do not treat `SupabaseService.signIn` as “Auth is done.” The product login path is still local.

---

## 3. Env and secrets

| Item | Status | Current code |
| --- | --- | --- |
| Template | Done | `env.example`: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, optional `STRIPE_PUBLISHABLE_KEY`, `DEMO_MODE`, `DEBUG_MODE`. Stripe and Kling secret keys called out as function-only |
| Local run helper | Done | `./scripts/run_with_env.sh` passes URL, anon key, optional demo/debug/publishable key. Never `--dart-define=STRIPE_SECRET_KEY` |
| Compile-time config | Done | `lib/config/app_config.dart` (`String.fromEnvironment` / `bool.fromEnvironment`). Tracked; empty defaults; no live secrets |
| `.env` ignored | Done | `.gitignore` has `.env`, `.env.local`, `.env.production`, `.env.staging`, `*.env` |
| Stripe / Kling secrets ignored | Done | `supabase/functions/.env` matches `*.env`. Do not add it to git |
| CI does not inject product secrets | Done | `.github/workflows/flutter-tests.yml` analyze + test only; no `SUPABASE_*` / Stripe secrets |
| Production build dart-defines | Not started | `SETUP_ENVIRONMENT_VARIABLES.md` shows the flags; there is no release workflow that applies them. `DEBUG_MODE` / `DEMO_MODE` dart-defines are unused except `useMockStripe` (login debug chrome is **not** gated) |
| `SETUP_ENVIRONMENT_VARIABLES.md` lists publishable key | Not started | That guide still omits `STRIPE_PUBLISHABLE_KEY` (present in `env.example`) |

Required dart-defines for a real (still-mock-payments) device build:

```bash
flutter build apk \  # or ipa / appbundle
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_... \
  --dart-define=DEMO_MODE=true \
  --dart-define=DEBUG_MODE=false
```

Leave `DEMO_MODE=true` until §1’s launch flip.

---

## 4. Demo accounts

Canonical set (README + `StorageService.initializeSampleData()`). Not shown on the logged-out login screen. Do not invent a fourth list.

### Canonical seeded accounts

| Role | Email | Password |
| --- | --- | --- |
| Admin Store | `admin@store.com` | `password123` |
| Admin Utilif | `admin@utilif.com` | `utilif123` |
| Employee | `john.doe@example.com` | `password123` |
| Super Admin | `superadmin@platform.com` | `password123` |

### Additional seeded employees

| Name | Email | Password |
| --- | --- | --- |
| Jane Smith | `jane.smith@example.com` | `password123` |
| Mike Johnson | `mike.johnson@example.com` | `password123` |
| Karl Kristjánsson | `Karl@Utilif.is` | `password123` |
| Kalli Krist | `kallikrist@test.is` | `demo123` |

| Item | Status | Current code |
| --- | --- | --- |
| README matches seed | Done | `README.md` Demo Accounts; locked by `test/demo_accounts_alignment_test.dart` |
| App always seeds missing demo users | Done (launch risk) | `AppProvider.initialize()` calls `initializeSampleData()` when any of the four canonical demo emails is missing |
| Passwords shown on the login screen | Done | Removed from logged-out `lib/screens/login_screen.dart`; locked by `test/login_screen_hardening_test.dart` |
| Debug / wipe controls on login | Done | Removed from logged-out login (Reset Demo Data, Test Supabase, Debug Users, unauthenticated reset) |
| Hide demo chrome in store builds | Done | Logged-out login has no demo box or debug buttons |
| Some tests still use stale emails | Not started | e.g. `john@store.com` / `jane@store.com` in `test/widget_test.dart`, `test/john_login_test.dart`, `test/integration_test.dart` |
| Auth users for these emails | Owner | After BON-12; same emails/passwords |

Logged-out login no longer has **Reset Demo Data**. Do not restore that wipe control.

---

## 5. Privacy policy

| Item | Status | Current code |
| --- | --- | --- |
| Privacy policy document / URL | Not started | No `PRIVACY.md`, no in-app link, no hosted policy |
| iOS privacy manifest | Not started | No `PrivacyInfo.xcprivacy`. `ios/Runner/Info.plist` has no usage-description keys (camera, photos, tracking) |
| Android Data safety / Play policy | Not started | No store listing metadata in repo |
| App Store privacy nutrition labels | Not started | Same |
| LICENSE file | Not started | `README.md` claims MIT; there is no `LICENSE` file |
| What the app actually stores today | Done (describe, do not change) | Local source of truth: SharedPreferences JSON via `StorageService`. Passwords: `PasswordService` + `SecureStorageService`. Best-effort Supabase dual-write (`SupabaseService`). Payments: mock cards/transactions locally; live Stripe not enabled. Auth: local, not `auth.users` |

Before store submission you need a public HTTPS privacy URL covering: accounts, sales/points, messages, payment-card metadata, and Supabase hosting. Point App Store Connect and Play Console at that URL. Do not invent legal copy in this checklist.

---

## 6. Store listings

Identifiers in this tree (Flutter default-style; confirm they are the IDs you want to ship):

| Store | Field | Value in code |
| --- | --- | --- |
| Android | `applicationId` / `namespace` | `com.bonuses.app.bonuses` (`android/app/build.gradle`) |
| Android | `android:label` | `bonuses` (`android/app/src/main/AndroidManifest.xml`) |
| iOS | Display name | `Bonuses` (`ios/Runner/Info.plist` `CFBundleDisplayName`) |
| iOS | Bundle ID | `com.bonuses.app.bonuses` (`ios/Runner.xcodeproj` `PRODUCT_BUNDLE_IDENTIFIER`) |
| macOS | Bundle ID | `com.bonuses.app.bonuses` (`macos/Runner/Configs/AppInfo.xcconfig`) |
| Version | name+build | `1.0.0+1` (`pubspec.yaml`) |
| Android min / compile SDK | | `minSdk = 23`, `compileSdk = 35` |

| Item | Status | Current code |
| --- | --- | --- |
| Unique application / bundle IDs | Done (defaults) | See table. Gradle still has `TODO: Specify your own unique Application ID` |
| Release signing (Android) | Not started | `signingConfig = signingConfigs.debug` with a TODO to add a real config |
| Release signing (iOS) | Not started | Automatic / `iPhone Developer`; no `DEVELOPMENT_TEAM` in the pbxproj |
| Store icons / screenshots / listing copy | Not started | Default Flutter launcher mipmaps / AppIcon. No Fastlane, no Play/App Store metadata in repo |
| INTERNET in **release** Android | Not started | `uses-permission INTERNET` is only in `android/app/src/debug` and `src/profile`, not main. Release builds that talk to Supabase/Stripe need it on the main manifest — verify before a Play upload |
| Apple Pay merchant ID | Not started | Apple Pay helpers are mock; no merchant identifier / entitlements |
| Export compliance / encryption answers | Not started | No `ITSAppUsesNonExemptEncryption` |
| Display-name consistency | Not started | Android label `bonuses` vs iOS `Bonuses`; MaterialApp title `Bonuses App` |
| Firebase leftover in Gradle comment | Not started | `minSdk = 23  // Firebase requires minSdkVersion 23` — Firebase is gone |

App Store and Play listing copy, screenshots, support URL, and privacy URL are Owner once the binary is signed.

---

## 7. Crash reporting (upcoming)

| Item | Status | Current code |
| --- | --- | --- |
| Sentry / Crashlytics / similar | Upcoming | No crash-reporting package in `pubspec.yaml`. Firebase was removed. Failures go to `print` / `ErrorHandler` |
| dSYM / ProGuard mapping upload | Upcoming | Blocked on choosing a reporter |
| PII in crash logs | Upcoming | Gate on the reporter: do not send emails, card numbers, or passwords |

Do not add a reporter in the same change as a store upload unless that work is tasked.

---

## 8. TestFlight / Play App Distribution (upcoming)

| Item | Status | Current code |
| --- | --- | --- |
| TestFlight | Upcoming | No Fastlane, no `ExportOptions.plist`, no CI `flutter build ipa` |
| Play App Distribution / internal testing | Upcoming | No CI `flutter build appbundle`. Android release uses debug signing |
| Distribution testers + groups | Owner | After a signed build exists |
| Hide demo/debug login chrome | Not started | Required before any external tester build (§4) |
| Pass dart-defines into the signed binary | Not started | §3 |

Internal developer `flutter run` is not TestFlight and is not Play App Distribution.

---

## 9. Pre-store hygiene (code that would ship today)

These are true of `fe7f88d` and will surprise store reviewers if ignored:

- Login screen always shows demo passwords and debug/wipe buttons (§4).
- `AppProvider.initialize()` seeds demo users on every install that lacks them.
- `AuthService` and `main.dart` log emails and auth/Supabase status with `print` (not crash reporting).
- `lib/test_*.dart` is gitignored (`lib/test_supabase_connection.dart` is local-only). `main.dart` has no `/supabase-test` route.
- CI workflow header in `.github/workflows/flutter-tests.yml` still talks about BON-2 / BON-3 as if unmerged; analyze+test do fail the job (no trailing `exit 0`). Named test exclusions remain.
- No crash reporter, no privacy URL, no store listing assets.

---

## How to re-verify this document against code

Run from the repo root after pulling `main`. If any command disagrees with a row above, edit this file in the same change as the code.

```bash
git rev-parse --short HEAD

# Stripe stays mock; secret not in the client
rg -n "useMockStripe|DEMO_MODE|processPayment|_invokeSecretAction" lib/config/app_config.dart lib/services/stripe_service.dart
rg -n "STRIPE_SECRET_KEY=" env.example scripts/run_with_env.sh lib/ || true
rg -n "verify_jwt" supabase/config.toml

# Auth is still local (until BON-12 lands)
rg -n "Using local storage authentication|signInWithPassword" lib/services/auth_service.dart lib/services/supabase_service.dart

# Demo accounts: README, login box, seed
rg -n "admin@store.com|admin@utilif.com|john.doe@example.com|superadmin@platform.com" \
  README.md lib/screens/login_screen.dart lib/services/storage_service.dart
flutter test test/demo_accounts_alignment_test.dart test/stripe_secret_handling_test.dart

# Store IDs / signing
rg -n "applicationId|signingConfigs.debug" android/app/build.gradle
rg -n "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj
rg -n "INTERNET" android/app/src -g '*.xml'

# Crash reporting still absent
rg -n "sentry|crashlytics|firebase_crashlytics" pubspec.yaml lib/ || true

# Privacy policy still absent
ls PRIVACY.md 2>/dev/null || echo "no PRIVACY.md"
```

Expected today (`fe7f88d`): mock Stripe default; `verify_jwt = false`; local auth print present; demo emails aligned; debug signing; INTERNET only under debug/profile; no sentry/crashlytics; no `PRIVACY.md`.

---

## Suggested order (do not reorder into a live-Stripe cutover)

1. Hide login demo/debug chrome behind `kDebugMode` / `DEMO_MODE` (required before TestFlight or Play).
2. Finish auth hardening (BON-12): Supabase Auth login + `stripe-secret` JWT. Owner creates Auth users; redeploy function with `verify_jwt = true`. **Payments stay mock.**
3. Privacy policy URL + iOS privacy manifest + Play Data safety.
4. Release signing, INTERNET on the main Android manifest, icons, listing copy.
5. Crash reporting (upcoming).
6. TestFlight / Play App Distribution (upcoming).
7. Live Stripe flip (§1) last, Owner-only, after the rest is Done.
