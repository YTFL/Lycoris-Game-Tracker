# Contributing to Lycoris

Thank you for your interest in contributing to **Lycoris**! As an offline-first, sovereign gaming library and financial ROI tracker, we welcome contributions that preserve user privacy, improve performance, elevate visual craftsmanship, and expand functionality.

This document outlines the development workflow, coding standards, architectural invariants, and submission guidelines.

---

## Table of Contents

- [Core Principles](#core-principles)
- [Code of Conduct](#code-of-conduct)
- [Prerequisites & Development Setup](#prerequisites--development-setup)
- [Project Architecture](#project-architecture)
- [Coding Standards & Guidelines](#coding-standards--guidelines)
- [State Management & Persistence](#state-management--persistence)
- [Git & Branching Workflow](#git--branching-workflow)
- [Commit Conventions](#commit-conventions)
- [Testing & Quality Verification](#testing--quality-verification)
- [Submitting a Pull Request](#submitting-a-pull-request)

---

## Core Principles

Every contribution must honor Lycoris's foundational architectural pillars:

1. **Total Data Sovereignty**: All user data resides on-device in local storage. Never introduce third-party analytics SDKs, advertising frameworks, tracking pixels, or remote databases.
2. **Offline-First Resilience**: All core capabilities—library management, ROI computation, playtime editing, and rankings—must function flawlessly without an active internet connection.
3. **Zero Telemetry**: We do not collect telemetry, crash reports, or behavioral metrics. Network interactions are strictly limited to opt-in user services (anonymous IGDB queries via proxy, live currency exchange rates, and user-initiated Google Drive sync).
4. **Deliberate Craftsmanship**: Every screen and widget must meet high visual and interaction standards—fluid transitions, responsive layouts, and clean typography.

---

## Code of Conduct

We are committed to providing a welcoming, inclusive, and harassment-free community for all contributors. Please treat everyone with respect, give constructive feedback, and focus on collaborative problem-solving.

---

## Prerequisites & Development Setup

### System Requirements
- **Flutter SDK**: `^3.12.2` (or current stable release compatible with Dart 3.x)
- **Dart SDK**: Included with Flutter
- **Android Studio** with Android SDK (API Level 21+ supported; target API Level 34+)
- **Git**

### 1. Fork & Clone
```bash
git clone https://github.com/<your-username>/Lycoris.git
cd Lycoris
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Environment Configuration
Create a local `.env` configuration file from the template:
```bash
cp .env.example .env
```
Fill in the development keys:
```env
GOOGLE_CLIENT_ID=your-android-client-id.apps.googleusercontent.com
GOOGLE_PROJECT_ID=your-google-project-id
DEFAULT_PROXY_URL=https://your-worker.workers.dev
```

> [!NOTE]
> For general UI, library, ranking, and analytics development, dummy values in `.env` are sufficient. Real credentials are only required if actively debugging Google Drive OAuth or custom Cloudflare Worker endpoints.

### 4. Running the App
Launch the app on a connected Android device or emulator:
```bash
flutter run --dart-define-from-file=.env
```

---

## Project Architecture

Lycoris follows a strict **feature-first, layered architecture**:

```text
lib/
├── core/                         # Shared utilities, services, storage, and constants
│   ├── constants/                # Colors, API endpoints, design tokens
│   ├── services/                 # Exchange rate service, background workers
│   ├── storage/                  # Hive database registrar and type adapters
│   └── utils/                    # Currency helpers, time normalizers, crypto
│
├── features/                     # Feature modules
│   ├── analytics/                # Spending distribution charts & metrics
│   │   └── presentation/         # Analytics dashboard screens and widgets
│   ├── home/                     # Navigation container & scaffold
│   ├── rankings/                 # Head-to-head comparison tournament & tier lists
│   │   ├── data/                 # Rankings repository
│   │   ├── domain/               # Canonical games, comparison metrics, tiers
│   │   └── presentation/         # Rankings notifier, tournament views, sheets
│   ├── search/                   # IGDB search proxy & manual intake
│   │   ├── data/                 # IGDB service and cover cache
│   │   └── presentation/         # Intake screens, dialogs, manual modals
│   ├── sync/                     # Google Drive backup, settings, exchange rates
│   │   ├── data/                 # Drive sync service, settings repo
│   │   └── presentation/         # Settings screen, exchange rate controllers
│   └── tracker/                  # Core game library, dossier, and ROI engine
│       ├── data/                 # Game repository
│       ├── domain/               # GameEntry, Expense, Storefront, Status models
│       └── presentation/         # Library shelf/list, dossier screen, modals
└── main.dart                     # Application bootstrap and Hive initialization
```

### Architectural Layering Rules:
- **`domain/`**: Contains pure Dart models, value objects, and business logic. Must not depend on Flutter UI elements or presentation widgets.
- **`data/`**: Handles persistence (Hive NoSQL) and external networking (Dio, Google APIs).
- **`presentation/`**: Contains Flutter widgets, screens, and Riverpod state controllers.
- Cross-feature dependencies should be minimal and routed through domain models or shared core services.

---

## Coding Standards & Guidelines

- **Adhere to Official Dart Style**: Follow effective Dart practices.
- **Clean Code & Self-Documenting Logic**: Write clear, descriptive identifiers. Avoid abbreviations where clarity suffers.
- **Preserve Documentation**: Maintain existing docstrings and comments. When writing new business algorithms (e.g. ranking mathematics, currency conversions), document edge cases thoroughly.
- **Immutability First**: Domain models and state classes should be immutable (`@immutable` or `final` fields).

---

## State Management & Persistence

### Flutter Riverpod 2.x
- Manage presentation state using `Notifier`, `StateNotifier`, or `StateProvider`.
- Keep widgets lightweight. Defer business logic, mathematical calculations, and filtering to state notifiers or repository classes.
- Use `ref.watch()` for reactive UI updates and `ref.read()` inside callbacks or event handlers.

### Hive NoSQL Storage
- Lycoris persists data using Hive boxes (`games_box`, `settings_box`, etc.).
- **TypeAdapter Safety**: Never modify the `typeId` or existing `@HiveField(index)` of any stored model in `hive_registrar.dart`.
- When adding new fields to existing models:
  - Add new fields with incremented `@HiveField` indices.
  - Provide safe default values for existing stored records.
  - Write unit tests verifying backwards compatibility for existing JSON/Hive schemas.

---

## Git & Branching Workflow

1. **Fork the Repository**: Always work on your personal fork.
2. **Create a Topic Branch**: Branch off `main` with a concise, descriptive name:
   - `feat/feature-name` (e.g., `feat/steam-wishlist-import`)
   - `fix/bug-description` (e.g., `fix/currency-conversion-rounding`)
   - `docs/topic-name` (e.g., `docs/architecture-overview`)
   - `refactor/target-area` (e.g., `refactor/rankings-state-notifier`)
3. **Keep Branches Focused**: One logical feature or bug fix per pull request. Avoid mixing unrelated style fixes with feature code.

---

## Commit Conventions

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```text
<type>(<scope>): <short summary>

[optional body]

[optional footer(s)]
```

### Supported Types:
- `feat`: A new user-facing feature or capability.
- `fix`: A bug fix.
- `refactor`: Code changes that neither fix a bug nor add a feature.
- `perf`: Performance improvements.
- `docs`: Documentation changes only.
- `style`: Formatting, whitespace, or missing semicolon adjustments (no production code change).
- `test`: Adding or updating unit and widget tests.
- `chore`: Maintenance tasks, dependency updates, or build configuration adjustments.

### Example Commit Messages:
```text
feat(rankings): add pairwise head-to-head comparison tournament
fix(tracker): correct decimal hours rounding drift in playtime normalizer
docs(readme): modernize overview and strip legacy emojis
test(sync): add unit tests for LWW timestamp conflict resolution
```

---

## Testing & Quality Verification

Before submitting any contribution, you must ensure all quality gates pass locally.

### 1. Code Formatting
Format all Dart files in the project:
```bash
dart format .
```
Verify formatting without modifying files (CI check):
```bash
dart format --output=none --set-exit-if-changed .
```

### 2. Static Analysis
Run Flutter's analyzer to detect warnings, lints, or potential bugs:
```bash
flutter analyze
```
All code must pass with **0 errors and 0 warnings**.

### 3. Automated Test Suite
Run all unit and widget tests:
```bash
flutter test
```
- When adding new domain logic, currency calculations, normalizers, or ranking algorithms, **you must write corresponding unit tests** under `test/unit/`.
- Ensure new tests are deterministic and do not depend on real network connections.

---

## Submitting a Pull Request

1. **Rebase on Latest Main**: Ensure your branch is rebased cleanly against upstream `main`:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```
2. **Push to Your Fork**:
   ```bash
   git push origin feat/your-feature-name
   ```
3. **Open a Pull Request**: Submit your PR against the `main` branch of `YTFL/Lycoris-Game-Tracker`.
4. **Fill Out the PR Template**: Complete all sections of the pull request template:
   - Provide a clear summary and motivation.
   - Reference related issues (`Closes #123`).
   - Check off all items in the verification checklist.
   - Attach before/after screenshots or screen recordings if UI elements were altered.
5. **Participate in Code Review**: Reviewers may request refinements or ask clarifying questions. Push additional commits to your branch to address feedback.

Thank you for helping keep Lycoris fast, private, and sovereign!
