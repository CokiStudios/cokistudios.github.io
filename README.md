# Coki Studios LLC — Engineering & Platform Monorepo

Welcome to the official platform, games, and applications monorepo for **Coki Studios LLC**.

---

## 🏛️ Ecosystem Overview

This repository contains the full stack of Coki Studios technologies, ranging from custom game engines to native Apple and Android applications, web infrastructure, and identity services.

```
cokistudios.github.io/
├── LoopingEngine/            # Custom C++ / Native Game & Scripting Engine (.loop)
├── sample_loop_projects/     # Sample games and IDE projects built in .loop
├── loop_modules/             # Native modules (physics.loop, math.loop, etc.)
│
├── CSMS.macOS/               # Coki Studios Messaging System (macOS SwiftUI)
├── CSMS.iOS/                 # CSMS mobile client (iOS)
├── CSMS.watchOS/             # CSMS wearable companion (watchOS)
├── CSMS.Android/             # CSMS Android client (Kotlin / Jetpack Compose)
│
├── CSMail.macOS/             # Native mail client for @cokistudios.com accounts
├── Forkar.iOS/               # Forkar official mobile client (iOS)
├── Forkar.Android/           # Forkar official mobile client (Android)
├── CokiAccountManager.iOS/   # Central identity & license manager (iOS)
├── hiOP.macOS/ & hiOP-VSCode/# Developer IDE tooling & extension suite
├── ShineFind/ & aosp-shine-os# Shine hardware integration & custom Android OS
│
├── coki-auth.js              # CS ID Universal Identity & Passkey (WebAuthn) Engine
├── csid-notification-service # Automated transactional email engine (Zoho SMTP)
├── oauth-server.js           # Supabase Native OAuth 2.1 Authorization Server
└── index.html, dashboard.html# Web platform & developer portal
```

---

## 🔑 Identity & Access (CS ID)

Coki Studios utilizes a unified identity architecture:
* **Supabase Native OAuth 2.1**: RFC 6749 / OAuth 2.1 authorization server (`/oauth/consent.html`).
* **WebAuthn / Passkeys**: Biometric authentication (Touch ID, Face ID, Windows Hello) with fallback to Coki Master Keys.
* **Microsoft Entra ID (Azure AD)**: Corporate identity, role-based access control (RBAC), and enterprise federation.
* **Zoho Workplace**: Dedicated corporate mail infrastructure (`@cokistudios.com`).

---

## 👥 Studio Teams & Microsoft Entra Groups

Team permissions and access control are centrally managed in Microsoft Entra ID:
* **`CS-Developers`**: Core engine, Supabase infrastructure, and shared APIs.
* **`Holo Development`**: Augmented reality, mixed reality, and Holo game projects.
* **`Shine Hardware Development`**: Shine wearable and hardware device integration.
* **`Shine Software`**: Companion operating system and device apps for Shine.

---

## 🚀 Getting Started for New Team Members

1. **Read the Onboarding Guide**: Please review [`CONTRIBUTING.md`](./CONTRIBUTING.md) for coding standards, git workflows, and security protocols.
2. **Environment Setup**:
   - **macOS / iOS**: Xcode 15+ with Swift 5.9+.
   - **Android**: Android Studio Hedgehog+ with JDK 17+.
   - **Web / Backend**: Node.js 18+ and modern browser with WebAuthn support.
   - **LoopingEngine**: Clang / C++20 compiler.
3. **Identity Onboarding**: Make sure you have received your Microsoft Entra invitation or `@cokistudios.com` account and configured your MFA/Passkey in [Microsoft Authenticator](https://myaccount.microsoft.com).

---

## 🔒 Security & Code Integrity Policies

* **Zero Leaked Secrets**: Never commit `.env`, API service keys, private certificates, or user passwords.
* **Engine Strictness**: Emojis are **strictly prohibited** in `LoopingEngine/`, compiler tokens, and binary outputs.
* **Responsible Disclosure**: Security vulnerabilities must be reported immediately to `contact@cokistudios.com`.

---

© 2026 Coki Studios LLC. All rights reserved.
