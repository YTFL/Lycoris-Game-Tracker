# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] - 2026-11-23

### Added
- **Game Rankings Enhancements**:
  - Displayed playtime (`TimeNormalizer.format`) and user personal star rating in the Top 5 podium slots (#1–#3) and sub-tier cards (#4–#5).
  - Displayed personal star ratings on list tiles across all remaining ranks (#6+).
  - Introduced `PreRankRatingSheet`: a mandatory pre-ranking rating flow that prompts users to rate any unrated completed games before comparison sessions begin, establishing an accurate baseline.
  - Implemented dynamic initial Elo seeding based on user personal rating: $\text{initialElo} = 800.0 + (\text{personalRating} \times 80.0)$.
  - Accelerated K-factor calibration ($K=64 \rightarrow 48 \rightarrow 32 \rightarrow 20$) for rapid ladder placement of newly added games.
- Global `snackBarTheme` in `main.dart` enforcing floating, rounded dark slate notification capsules across the app.

### Changed
- **Rankings Calibration & Matchmaking**:
  - Fixed premature session termination where "Rank New Games" abruptly cut off after 3 comparisons regardless of the planned total.
  - Removed artificial 400-point Elo distance restriction for uncalibrated games, allowing newcomers to challenge higher or lower tiers.
  - Anchored new game matchmaking against established, calibrated library games instead of clustering uncalibrated titles against each other.
  - Added dampening to rating losses on calibrated games when facing uncalibrated newcomers to protect established leaderboard integrity.
  - Retained uncalibrated games in `newUnrankedGames` until completing at least 3 comparisons so the ranking prompt is never lost on early exit.
- **Anti-Bias & Anti-Manipulation Updates**:
  - In "Help Me Choose": Removed `<game> takes the lead` and `Evenly matched` ticker text, and updated the action button to simply `"Continue"`.
  - In "Help Me Rate": Removed the live numerical average rating ticker from the top card (replaced with rated dimensions count) and removed the score from the `"Apply Rating"` button to prevent artificial score manipulation.
- Minimized Cloudflare proxy connection status message to `"Proxy operational"` and replaced the green alert container with the Spider Lily Crimson / dark slate theme.
- Standardized all toast notifications (SnackBars) in Settings to floating capsules, eliminating raw green (`LycorisColors.success`), blue (`info`), amber (`warning`), and solid red (`error`) blocks.
- Updated developer API credential lock icon and update button highlight from rogue green (`#10B981`) to `colorScheme.primary`.

### Removed
- Removed the `"CONVERSION BENCHMARK (BASE: 1 USD)"` matrix box from the Settings Display Currency & FX Rates card.
- Removed the `"Offline-first gaming library & investment ROI tracker"` footer subtitle from the Settings screen.

---

## [1.0.0] - 2026-10-24

### Added
- **Dual Display Modes**:
  - The Shelf: visual 3:4 aspect ratio game box art grid with dynamic gradient vignettes and storefront brand badges.
  - The List: high-density tabular view displaying storefront, logged hours, itemized expenditure, rating, and real-time $/hr rate.
- **Financial ROI Engine**:
  - Continuous cost-per-hour calculation (`Total Investment ÷ Total Hours`).
  - Clean `$X.XX/hr` rate headers surfaced next to game titles.
  - Backlog capital valuation calculating total unplayed currency investment.
- **Itemized Expenses & DLC Tracking**:
  - Multi-storefront composite ownership keys (`${igdbId}_${storefront}`) for independent tracking of multi-platform copies.
  - Granular expense logging for expansions, season passes, cosmetics, and microtransactions.
  - Dynamic total investment and $/hr recalculation upon expense modification.
- **Normalizers**:
  - 3-Mode Playtime Normalizer supporting Hours+Minutes (e.g., `14h 30m`), Decimal Hours (e.g., `14.5 hrs`), and Pure Minutes (e.g., `870 mins`) with zero precision loss.
  - Multi-Currency Normalizer supporting purchases in native currencies (USD, EUR, GBP, INR, JPY, CAD, AUD, etc.) with automatic normalization into Primary Display Currency.
- **Rankings & Decision Engine**:
  - Canonical cross-platform game aggregation to eliminate duplicate storefront entries during ranking.
  - Head-to-Head pairwise comparison tournament (*Game A vs. Game B*) generating objective personal tier lists (*God Tier, S, A, B, C, D*).
  - Interactive Top 5 Showcase podium view.
  - "Help Me Choose" assistant evaluating time commitment, gameplay intensity, mood, narrative depth, and visual style to resolve backlog paralysis.
- **10-Star Multidimensional Rating Assistant**:
  - "Help Me Rate" modal evaluating games across 9 dimensions: mechanics, narrative, visuals, audio, pacing, innovation, replayability, stability, and emotional impact.
  - Automatic arithmetic mean calculation with 0.5-star rounding quantization.
- **Game Intake**:
  - Online IGDB v4 catalog search across 300,000+ titles with cover art caching.
  - Offline Manual Entry modal for unlisted titles, retro ROMs, and homebrew.
  - Intake wizard for configuring initial spend, storefront, currency, and play status.
- **Analytics Dashboard**:
  - Storefront capital distribution donut chart.
  - Best ROI mileage leaderboards and highest-cost investment metrics.
  - Playtime time sink rankings and status breakdown.
- **Data Sovereignty & Synchronization**:
  - 100% offline-first local persistence powered by Hive NoSQL.
  - Google Drive cloud synchronization using restricted `drive.file` scope.
  - Last-Write-Wins (LWW) conflict resolution using ISO-8601 timestamps.
  - Local JSON vault export and import via system file pickers.
  - Automated 2-stage rotating offline local backups (`lycoris_backup_current.json` and `lycoris_backup_previous.json`) with Android Storage Access Framework (SAF) folder integration.
  - Zero telemetry, zero analytics trackers, and zero third-party advertising SDKs.
- **Automated GitHub Updates & In-App Installer**:
  - In-app update checker querying `update.json` on raw GitHub with fallback to GitHub Releases API (`/releases/latest`).
  - Silent launch check with 24-hour deferral reminder support.
  - On-demand "Check for Updates" trigger in Settings.
  - Dio chunked APK streaming to disk with animated progress bar.
  - Native Android package installation via `FileProvider`.
- **In-App Legal Documentation & Developer Showcase**:
  - Native in-app markdown viewer (`MarkdownViewerScreen`) rendering offline Terms of Service (`docs/terms.md`), Privacy Policy (`docs/privacy.md`), and Release Notes (`RELEASE_NOTES.md`).
  - Developer showcase link (`https://ytfl.github.io/`) in Settings About & Legal hub.
- **Edge Infrastructure**:
  - Cloudflare Worker proxy for anonymous IGDB APICalypse v4 queries and edge caching of Twitch OAuth tokens.
  - Configurable proxy URL toggle in Settings.
- **Community & Documentation**:
  - Comprehensive documentation suite: [RELEASE_NOTES.md](RELEASE_NOTES.md), [CONTRIBUTING.md](CONTRIBUTING.md), [README.md](README.md).
  - Standardized GitHub issue templates and PR template.

[1.1.0]: https://github.com/YTFL/Lycoris-Game-Tracker/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/YTFL/Lycoris-Game-Tracker/releases/tag/v1.0.0
