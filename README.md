# Lycoris — Personal Gaming Library & Financial ROI Tracker

<p align="center">
  <img src="assets/icons/icon_transparent.png" alt="Lycoris Logo" width="128" height="128">
</p>

<p align="center">
  <strong>Know what your playtime is actually worth.</strong><br>
  An offline-first personal gaming library, backlog manager, and financial ROI tracker for sovereign gamers.
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter"></a>
  <a href="https://pub.dev/packages/hive"><img src="https://img.shields.io/badge/Storage-Hive%20NoSQL-FFA000?logo=dart&logoColor=white" alt="Hive NoSQL"></a>
  <a href="https://developers.google.com/drive"><img src="https://img.shields.io/badge/Sync-Google%20Drive-4285F4?logo=googledrive&logoColor=white" alt="Google Drive"></a>
  <a href="docs/privacy.html"><img src="https://img.shields.io/badge/Privacy-Zero%20Telemetry-10B981" alt="Zero Telemetry"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-AGPL--3.0-E53935?logo=gnu" alt="AGPL-3.0 License"></a>
</p>

---

## Overview

Modern gaming is fragmented. Players own titles across Steam, PlayStation, Xbox, Nintendo Switch, GOG, Epic Games, itch.io, and physical cartridges. Across seasonal sales, subscription bundles, microtransactions, and DLC passes, two critical questions are almost impossible to answer:

1. *How much have I actually invested in this game across all platforms?*
2. *Was it worth the cost based on how many hours I enjoyed playing it?*

Most game tracking services require online accounts, load sluggish web views, monetize through subscription paywalls, or collect telemetry on gaming habits.

**Lycoris is built on a different philosophy: total data sovereignty.** It is a fast, offline-first mobile application that organizes multi-storefront game ownership, itemizes every expense from base purchases to microtransactions, computes your real cost-per-hour return on investment, and helps you rank your library through objective head-to-head comparisons—all safely backed up to your personal Google Drive or local storage.

---

## Key Features

### The Library: Dual Display Modes
- **The Shelf (Cover Art Grid)**: Visual grid displaying 3:4 game box art with dynamic gradient vignettes, platform icons, status pills, and cost-per-hour rates.
- **The List View (Dense Table)**: High-information density table for rapidly reviewing storefronts, logged playtime, itemized spending, user ratings, and return-on-investment metrics.
- **Filtering & Instant Search**: Filter by play status (*Playing, Backlog, Completed, Mastered, Abandoned, Wishlist*) or platform storefront (*Steam, PlayStation, Xbox, Switch, GOG, Epic Games, itch.io, Physical*), with real-time multi-field search across titles, developers, publishers, and genres.

### Financial ROI & Value Engine
- **Continuous Cost-Per-Hour Calculation**: Every game continuously calculates an effective hourly rate (`Total Investment ÷ Total Hours`).
- **Clean Rate Display**: ROI is surfaced as a clean rate metric directly alongside game titles without cluttered visual descriptors.
- **Backlog Capital Valuation**: Instantly see how much money is tied up in unplayed backlog titles.

### Itemized Expense & DLC Tracking
- Track base game purchase prices alongside itemized additional expenses:
  - Story expansions and DLCs
  - Season and battle passes
  - Cosmetic packs and microtransactions
- Spending modifications dynamically update the game's total cost and real-time cost-per-hour efficiency.

### Head-to-Head Rankings & Dynamic Tier Lists
- **Canonical Game Consolidation**: Automatically aggregates duplicate multi-platform purchases into unified canonical titles so you rank games conceptually rather than by individual store copies.
- **Pairwise Comparison Tournament**: Simple binary choices (*Game A vs. Game B*) eliminate cognitive bias and generate an objective, mathematically sound personal tier list (*God Tier, S, A, B, C, D*).
- **Top 5 Showcase**: Displays your all-time top five titles in a dedicated podium view.
- **"Help Me Choose" Backlog Decider**: When stuck deciding between two titles to play next, an interactive comparison matrix evaluates time commitment, mood, visual aesthetic, narrative depth, and gameplay loop.

### 10-Star Multidimensional Rating Assistant
- **"Help Me Rate" Assistant**: Compute balanced, defensible game scores out of 10.0 using 9 core evaluation criteria:
  - Gameplay Loop & Mechanics
  - Narrative & Worldbuilding
  - Visual Presentation & Art Direction
  - Audio & Soundtrack
  - Pacing & Progression
  - Innovation & Originality
  - Replayability & Longevity
  - Technical Polish & Stability
  - Emotional Impact & Satisfaction
- Scores are averaged across rated criteria and cleanly rounded to the nearest 0.5.

### Multi-Storefront Composite Ownership
- Own *Elden Ring* on Steam and *Hollow Knight* on Switch, but also double-dipped on PC? Lycoris utilizes composite keys (`${igdbId}_${storefront}`) to store platform-specific purchase prices, logged hours, DLC items, and notes independently without key collision.

### 3-Mode Playtime Normalizer
Log playtime in whichever format feels natural:
- **Hours + Minutes** (e.g. `14h 30m`)
- **Decimal Hours** (e.g. `14.5 hrs`)
- **Pure Minutes** (e.g. `870 mins`)
All input representations synchronize bi-directionally with zero precision loss.

### Multi-Currency Engine
- Record purchases in their native transactional currency (USD, EUR, GBP, INR, JPY, CAD, AUD, and more).
- Automatically fetch live exchange rates or use reliable fallback rates to normalize all library analytics into your chosen Primary Display Currency.

### Interactive Analytics Dashboard
- **Storefront Spending Distribution**: Interactive donut chart breaking down capital allocation across platforms.
- **Value Leaderboards**: Best ROI mileage titles vs. highest-cost investments.
- **Playtime Time Sinks**: Deepest hour investments and status distribution breakdown.

---

## Privacy & Data Sovereignty

Lycoris operates under a strict data sovereignty model: **your data belongs exclusively to you.**

| Layer | Implementation | Privacy & Security Guarantees |
| :--- | :--- | :--- |
| **Local Database** | Hive NoSQL (on device) | 100% offline. Instant loading. No account creation or registration required. |
| **Cloud Synchronization** | Google Drive (`drive.file`) | Opt-in backup using restricted scope. Lycoris cannot see or touch other Drive files. |
| **Local Export / Import** | JSON Vault File | Export or restore your entire library at any time through standard file pickers. |
| **Game Metadata Proxy** | Cloudflare Worker Edge | Proxies IGDB search queries and game cover assets anonymously. Zero request logging. |
| **Telemetry & Ads** | None | Zero tracking SDKs, zero third-party analytical cookies, zero ad frameworks. |

### How Google Drive Sync Works
- **Restricted Scope (`drive.file`)**: Lycoris only requests permission to read and write files that it created itself. It is technically impossible for Lycoris to access your personal photos, emails, spreadsheets, or other documents in Google Drive.
- **Transparent Vault Format**: Backups are stored as human-readable JSON at `Lycoris/lycoris_vault_backup.json` in your Google Drive root.
- **Deterministic Conflict Resolution**: Multi-device synchronization employs Last-Write-Wins (LWW) conflict resolution using ISO-8601 timestamps.
- **Compliance**: Fully compliant with the [Google API Services User Data Policy](https://developers.google.com/terms/api-services-user-data-policy).

---

## Quick Start for Players

1. **Download the APK**: Download the latest release APK from the [Releases](https://github.com/YTFL/Lycoris/releases) page and install it on your Android device.
2. **Catalog Your Games**: Tap **Add Game** to search over 300,000+ titles via the IGDB database, or tap **Manual Entry** to add retro ROMs, homebrew, or unlisted indie games.
3. **Log Playtime and Spend**: Enter your purchase price, storefront, and hours played to instantly calculate your cost-per-hour return.
4. **(Optional) Enable Google Drive Sync**:
   - Navigate to **Settings > Google Drive Backup**.
   - Tap **Sign in with Google**.
   - Tap **Backup Now** to save your library archive to your personal Drive.

---

## Developer & Self-Hosting Guide

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (`^3.12.2` or later)
- Android Studio / Android SDK (API Level 21+)
- (Optional) [Node.js](https://nodejs.org) and [Cloudflare Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/) for self-hosting the IGDB proxy

### 1. Clone the Repository
```bash
git clone https://github.com/YTFL/Lycoris.git
cd Lycoris
flutter pub get
```

### 2. Configure Environment Variables
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

Configure your Google Cloud OAuth Client ID (for Drive sync) and Cloudflare Worker URL:
```env
GOOGLE_CLIENT_ID=your-android-client-id.apps.googleusercontent.com
GOOGLE_PROJECT_ID=your-google-project-id
DEFAULT_PROXY_URL=https://your-worker.workers.dev
```

### 3. Run Locally in Development
```bash
flutter run --dart-define-from-file=.env
```

### 4. Build Release APK
```bash
flutter build apk --release --dart-define-from-file=.env
```

### 5. Self-Host the Cloudflare Worker Proxy (Optional)
The proxy located in `cloudflare-worker/` intercepts IGDB v4 APICalypse queries and securely caches Twitch OAuth credentials at the edge:
```bash
cd cloudflare-worker
npm install
npx wrangler login
npx wrangler secret put TWITCH_CLIENT_ID
npx wrangler secret put TWITCH_CLIENT_SECRET
npx wrangler deploy
```
After deployment, set your Worker URL under **Settings > Cloudflare Worker Proxy URL** in the application.

### 6. Run Test Suite
```bash
flutter test
```
The test suite covers unit and widget tests for playtime normalization, currency conversions, composite key generation, ranking algorithms, and LWW delta synchronization.

---

## Documentation & Community

- [Comprehensive Release Notes (v1.0.0)](RELEASE_NOTES.md) — Exhaustive documentation of all features and architectural capabilities.
- [Contribution Guidelines](CONTRIBUTING.md) — Development setup, architecture patterns, code style, and PR process.
- [Issue Templates](.github/ISSUE_TEMPLATE/) — Templates for bug reports and feature requests.
- [Product Website](docs/index.html) — Feature showcases, interactive preview, and live ROI calculator.
- [Privacy Policy](docs/privacy.html) — Google Drive Limited Use disclosure and data handling policies.
- [Terms of Service](docs/terms.html) — Open-source license and terms.

---

## License & Acknowledgements

- **License**: Released under the [GNU Affero General Public License v3.0 (AGPL-3.0)](LICENSE).
- **Game Metadata**: Game metadata and artwork are provided by the [IGDB.com](https://www.igdb.com) API, an Amazon / Twitch Interactive service.
- **Built With**: Flutter, Dart, Hive NoSQL, Flutter Riverpod, and fl_chart.
