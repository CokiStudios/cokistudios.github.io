# Coki Studios LLC — Contributor & Engineering Guidelines

Welcome to the team! This document outlines our engineering standards, repository workflow, and security guidelines for all engineers, designers, and contributors at **Coki Studios LLC**.

---

## 1. 👥 Team Structure & Roles

Your access to repositories, internal tools, and APIs is governed by your Microsoft Entra ID group membership:

| Group | Focus Areas | Primary Stack |
| :--- | :--- | :--- |
| **`CS-Developers`** | Core engine, Supabase backend, APIs, web platform | C++, TypeScript, Swift, SQL |
| **`Holo Development`** | Holo gaming, mixed reality experiences, interactive 3D | C++, Swift, Metal, Looping |
| **`Shine Hardware Development`** | Firmware, BLE communication, device drivers | C, Embedded, AOSP |
| **`Shine Software`** | Companion apps, sync services, Shine OS UI | Kotlin, Jetpack Compose, Swift |

If you need elevated permissions for a specific project, contact your group owner or administrator.

---

## 2. 🛡️ Security & Confidentiality Protocols

As an engineer at Coki Studios LLC, you are responsible for maintaining the security of our infrastructure and intellectual property:

1. **Secrets & Credentials**:
   - Never hardcode or commit `.env` files, Supabase `service_role` keys, Zoho app passwords, or private signing keys (`.p8`, `.p12`, `.keystore`).
   - Use environment variables or secure keychain storage for local development.
2. **Zero Emojis in Engine Code**:
   - In accordance with our engine compiler specification, **emojis are strictly forbidden** in `LoopingEngine/`, syntax lexers, and compiler binary outputs. Emojis may only be used in client UI markup where explicitly intended.
3. **MFA & Passkey Enforcement**:
   - All team members must enable Microsoft Authenticator MFA or WebAuthn Passkeys on their account.

---

## 3. 🌿 Git Workflow & Pull Requests

We follow a structured trunk-based branching workflow:

### Branch Naming Conventions
* Feature: `feature/<team>/<short-description>` (e.g. `feature/dev/oauth-consent-pkce`)
* Bugfix: `fix/<component>/<short-description>` (e.g. `fix/csms/ios-sync-crash`)
* Hotfix: `hotfix/<short-description>`

### Pull Request Process
1. Branch off `main`.
2. Keep PRs small, focused, and well-tested.
3. Ensure automated tests and linter checks pass before requesting review.
4. Request review from at least one peer in your corresponding Entra group.
5. Merge strategy: **Squash and Merge** to maintain a clean git history.

---

## 4. 💻 Technology-Specific Standards

### Apple Platforms (macOS, iOS, watchOS)
* Language: Swift 5.9+ with SwiftUI.
* Concurrency: Use modern `async/await` and Actors. Avoid legacy GCD/dispatch queues where possible.
* Architecture: MVVM with Observable pattern.

### Android Platforms
* Language: Kotlin 1.9+ with Jetpack Compose.
* Networking: Retrofit / OkHttp or Supabase-kt.
* Target SDK / Baseline: **Android 17 (A17)** for modern clients and AOSP Shine OS integrations.

### Web & Identity (CS ID)
* Core: Modern ES6+ JavaScript, Vanilla CSS for speed and control.
* Identity: Supabase Auth / OAuth 2.1 RFC 6749, WebAuthn Level 3.
* Performance: Keep bundle sizes minimal, leverage native browser APIs.

### LoopingEngine (.loop)
* Language: C++20 standard.
* Cross-platform: Maintain compatibility with macOS (Apple Silicon/Intel), Linux, and Windows.

---

## 5. 📬 Communication & Support

* **Engineering Support**: Check internal channels or reach out to `contact@cokistudios.com`.
* **Lead Admin**: Super Administrator (`contact@cokistudios.com`).

Thank you for building the future of gaming and software at **Coki Studios LLC**!
