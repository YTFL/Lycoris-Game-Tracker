# Lycoris Version 1.0.0 Release Notes

**Release Date:** October 2026  
**Milestone:** v1.0.0 Initial Production Release  
**License:** GNU Affero General Public License v3.0 (AGPL-3.0)  

---

## Executive Summary

Lycoris v1.0.0 marks the initial production release of the offline-first personal gaming library, backlog manager, and financial Return on Investment (ROI) tracker. Engineered specifically for sovereign gamers who maintain gaming libraries across fragmented platforms, Lycoris answers two fundamental questions:

1. *How much capital have I invested in this game across all storefronts and microtransactions?*
2. *What is my actual cost-per-hour entertainment value based on verified playtime?*

Unlike cloud services that require account registration, collect user telemetry, or sell gaming patterns, Lycoris guarantees total data sovereignty. All data remains stored locally on your device in high-performance NoSQL storage, with optional end-to-end synchronization to your private Google Drive vault using restricted app-specific scopes.

---

## Feature-by-Feature Catalog

### 1. Library & Catalog Management

#### The Shelf (3:4 Box Art Grid)
- **Visual Grid Presentation**: High-density grid rendering high-resolution 3:4 box art covers with smooth hardware-accelerated transitions.
- **Dynamic Gradient Vignettes**: Subtle, responsive visual gradients that ensure title and metadata legibility over dynamic box art.
- **Real-Time ROI Indicator**: Clean cost-per-hour rate badge displayed directly on each cover card for instant efficiency identification.
- **Storefront Badging**: Native platform brand badges (Steam, PlayStation, Xbox, Nintendo Switch, GOG, Epic Games, itch.io, Physical).

#### The List View (Dense Information Table)
- **Compact Data Rows**: Streamlined list layout optimized for reviewing large libraries with minimal scrolling.
- **Inline Metrics**: Displays storefront, playtime in hours, total expenditure, user rating, and calculated cost-per-hour in a tabular layout.
- **Instant Status Interaction**: Tap to toggle status or view detailed metrics.

#### Filtering, Searching & Sorting
- **Status Lifecycle Filters**: Instant horizontal chips for *All, Playing, Backlog, Completed, Mastered, Abandoned, and Wishlist*.
- **Storefront Filter Sheet**: Filter your view by one or multiple platforms simultaneously.
- **Multi-Field Instant Search**: High-performance local search engine matching across title, developer, publisher, and genre with zero debounce delay.
- **Configurable Sorting**:
  - Title (A–Z / Z–A)
  - Playtime (Most Played / Least Played)
  - Return on Investment (Best $/hr / Most Costly $/hr)
  - Total Spend (Highest Investment / Lowest Investment)
  - Personal Rating (Highest Rated / Lowest Rated)

#### Game Dossier Screen
- **Immersive Header View**: Hero banner showcasing official cover artwork, title, developer, publisher, release year, and genres.
- **Comprehensive Financial Summary**: Displays base purchase price, itemized additional expenses, total capital invested, and calculated cost-per-hour.
- **Playtime Overview**: Detailed log of logged minutes/hours with quick edit triggers.
- **Personal Notes & Logging**: Dedicated markdown-friendly notes section for tracking walkthroughs, hardware configurations, or review notes.

---

### 2. Financial ROI Engine & Spend Itemization

#### Continuous Cost-Per-Hour Calculation
- **Dynamic Value Evaluation**: Computes real-time cost-per-hour entertainment yield:
  $$\text{Cost Per Hour} = \frac{\text{Total Investment}}{\text{Total Playtime (Hours)}}$$
- **Direct Rate Surface**: Surfaces ROI cleanly as `$X.XX/hr` directly alongside titles without verbose text descriptors.
- **Unplayed & Free Title Handling**: Accurately tracks free-to-play, claimed, or gifted titles ($0.00 spend) as well as unplayed backlog entries without mathematical division errors.

#### Multi-Storefront Composite Ownership
- **Collision-Free Composite Keys**: Employs `${igdbId}_${storefront}` unique keying to allow tracking multiple purchases of the same title (e.g. PC Steam version vs. Nintendo Switch portable version).
- **Independent Tracking**: Purchase price, playtime hours, itemized DLCs, completion status, and notes remain isolated per platform.

#### Itemized Additional Expenses (DLC & Microtransactions)
- **Granular Expense Categories**: Record add-ons independently from the base game purchase price:
  - Expansion Packs & Story DLCs
  - Season Passes & Battle Passes
  - Cosmetic Items & Skins
  - Microtransactions & Virtual Currency Bundles
  - Physical Merchandise or Soundtrack Add-ons
- **Live Re-calculation**: Adding or editing any expense immediately recalculates the game's total capital investment and real-time $/hr rate.

#### 3-Mode Playtime Normalizer
- **Flexible Playtime Input**: Enter time in your preferred format:
  1. *Hours and Minutes* (e.g., `24h 45m`)
  2. *Decimal Hours* (e.g., `24.75 hrs`)
  3. *Pure Minutes* (e.g., `1485 mins`)
- **Lossless Synchronization**: Changes in any input mode instantly synchronize across all other formats with zero conversion drift.

#### Multi-Currency Normalizer
- **Native Transaction Recording**: Log purchases in the native currency used at the point of sale (USD, EUR, GBP, INR, JPY, CAD, AUD, etc.).
- **Normalized Portfolio Analytics**: Automatically converts and standardizes all expenditures into your chosen Primary Display Currency.
- **Dynamic & Fallback Exchange Rates**: Pulls live forex rates with embedded offline fallback mappings when network connectivity is unavailable.

---

### 3. Rankings & Backlog Decision Engine

#### Canonical Cross-Platform Aggregation
- **Unified Game Entities**: Consolidates multi-platform duplicate purchases into single canonical titles for ranking purposes, ensuring you rank *The Witcher 3* once rather than comparing your PC copy against your console copy.

#### Head-to-Head Pairwise Comparison Tournament
- **Binary Choice Tournament**: Resolves tier ranking through rapid, bias-free pairwise comparisons (*Game A vs. Game B*).
- **Eliminates Rating Inflation**: By forcing direct comparisons, Lycoris overcomes the common human pitfall where all favorite games are indiscriminately rated 9/10 or 10/10.
- **Dynamic Tier Generation**: Mathematically partitions your library into distinct tiers:
  - **God Tier**: Generational masterpieces.
  - **Tier S**: Exceptional must-play experiences.
  - **Tier A**: Great titles with high replayability.
  - **Tier B**: Solid, enjoyable games with minor drawbacks.
  - **Tier C**: Mediocre or flawed experiences.
  - **Tier D**: Early abandoned or disappointing titles.
- **Top 5 Showcase**: Celebrates your definitive top five gaming experiences in an interactive podium component.

#### "Help Me Choose" Backlog Decider Matrix
- **Decision Paralysis Solver**: When torn between two games in your backlog or ranking queue, the Help Me Choose assistant guides you through an objective multi-attribute evaluation:
  - Available Time Budget vs. Game Length
  - Desired Gameplay Intensity & Mechanics
  - Current Mood & Narrative Depth
  - Visual & Aesthetic Preference
  - Genre Repertoire
- Generates an immediate, reasoned recommendation to get you playing instead of scrolling.

---

### 4. 10-Star Multidimensional Rating Assistant

#### 9 Core Evaluation Dimensions
Compute defensible, holistic review scores out of 10.0 using the structured "Help Me Rate" evaluation modal:
1. **Gameplay Loop & Mechanics**: Core mechanics, control responsiveness, combat/interaction feel.
2. **Narrative & Worldbuilding**: Story depth, character writing, environmental storytelling.
3. **Visual Presentation & Art Direction**: Aesthetic coherence, lighting, art style execution.
4. **Audio & Soundtrack**: Musical score, sound design, voice acting quality.
5. **Pacing & Progression**: Flow of content, leveling curve, absence of artificial padding.
6. **Innovation & Originality**: Novel design concepts, departure from generic tropes.
7. **Replayability & Longevity**: End-game value, branching paths, emergent mechanics.
8. **Technical Polish & Stability**: Performance consistency, absence of game-breaking bugs.
9. **Emotional Impact & Satisfaction**: Overall lingering impression and player fulfillment.

#### Granular Rating Output
- Rates each active dimension with integer stars (1 to 10).
- Automatically computes the unweighted arithmetic mean across all rated dimensions.
- Cleanly quantizes to the nearest half-star (0.5 increments, e.g., 8.2 $\rightarrow$ 8.5; 7.7 $\rightarrow$ 7.5).

---

### 5. Game Intake & Metadata Discovery

#### Online IGDB Catalog Search
- **Comprehensive Database**: Instant access to over 300,000+ gaming titles via IGDB v4.
- **Automatic Asset Ingestion**: Pulls official high-resolution box art, title, release year, developer studio, publishing company, and genre classifications.
- **Edge Proxy Routing**: Queries route through the Lycoris Cloudflare Worker proxy to protect user privacy and avoid rate limiting.

#### Offline Manual Entry Engine
- **Independent from Cloud Services**: Full-featured manual game intake for unlisted titles, retro ROMs, homebrew projects, and private itch.io releases.
- **Custom Metadata**: Specify custom cover artwork URLs, titles, developer metadata, platform storefronts, and release years manually.

#### Intake Wizard
- Pre-configure initial purchase price, storefront, transactional currency, playtime, and initial status before adding the title to the library.

---

### 6. Interactive Analytics Dashboard

#### Visual Spending Analytics
- **Storefront Capital Distribution**: Interactive donut chart visualizing monetary distribution across platforms (Steam vs. PlayStation vs. Nintendo vs. others).
- **Backlog Capital Valuation**: Live counter detailing the exact monetary value of games currently waiting in your unplayed backlog.

#### Efficiency & Value Insights
- **Best ROI Mileage Leaderboard**: Top games delivering the most play hours per currency unit spent.
- **Highest Cost Investments**: Games with the highest cumulative expenditure (base price + DLC).
- **Time Sink Analysis**: Highlights the titles consuming the largest share of lifetime playtime.
- **Status Distribution**: Breakdown of library proportions across active, completed, backlog, and abandoned states.

---

### 7. Data Sovereignty, Privacy & Cloud Sync

#### 100% Offline-First Architecture
- Built on **Hive NoSQL**, a lightweight, high-performance, key-value database written in pure Dart.
- Zero local latency: all reading, filtering, and writing occurs on-device with zero network dependencies.
- No user accounts, registration, email collection, or passwords required.

#### Google Drive Cloud Sync
- **Restricted Scope (`https://www.googleapis.com/auth/drive.file`)**: Lycoris can only read and write files it created itself. It possesses zero access to your emails, documents, photos, or other personal Drive data.
- **Human-Readable Vault**: Saves library data as an open JSON file at `Lycoris/lycoris_vault_backup.json` in your Google Drive root.
- **Delta Sync with Last-Write-Wins (LWW)**: Resolves conflicts using ISO-8601 millisecond timestamps across multiple Android devices.
- **Compliance**: Fully complies with the Google API Services User Data Policy.

#### Local Backup & Restore
- Full offline JSON export and import capabilities via system file pickers, enabling manual archiving without Google Drive.

#### Zero Telemetry Policy
- No analytics SDKs (no Firebase Analytics, no Mixpanel, no Google Analytics).
- No crash tracking frameworks transmitting telemetry.
- Zero advertising libraries or ad trackers.

---

### 8. Cloudflare Worker Edge Proxy

#### Secure APICalypse v4 Broker
- Handles complex IGDB v4 queries at the Cloudflare network edge.
- Protects Twitch client credentials from exposure in client-side mobile binaries.
- Edge-caches Twitch OAuth bearer tokens with automatic renewal prior to expiration.
- Proxies cover art and search responses with minimal latency.

#### Configurable Proxy Endpoints
- Includes support for self-hosted instances: deploy your own Cloudflare Worker in seconds using Wrangler CLI and point Lycoris to your custom URL in **Settings**.

---

## Technical Specifications

| Parameter | Specification |
| :--- | :--- |
| **Framework** | Flutter 3.x (Dart 3.12+) |
| **Target Platforms** | Android (API Level 21+ / Android 5.0 Lollipop through Android 15+) |
| **State Management** | Flutter Riverpod 2.5 |
| **Persistence Engine** | Hive NoSQL 2.2 |
| **Networking & HTTP** | Dio 5.4 + Cached Network Image 3.3 |
| **Cloud Synchronization** | Google APIs (`googleapis`, `google_sign_in`) |
| **Cryptography** | AES / SHA-256 for secure proxy communication |
| **Data Visualization** | fl_chart 0.68 |
| **License** | GNU Affero General Public License v3.0 (AGPL-3.0) |

---

## Upgrade & Migration Notes

- This is the initial **v1.0.0** release. Fresh installations initialize an empty Hive database container automatically on first launch.
- Existing development installations using earlier pre-release builds will automatically migrate data schema entries upon launch via Hive TypeAdapter versioning.
