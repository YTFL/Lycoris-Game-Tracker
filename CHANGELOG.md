# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
  - Zero telemetry, zero analytics trackers, and zero third-party advertising SDKs.
- **Edge Infrastructure**:
  - Cloudflare Worker proxy for anonymous IGDB APICalypse v4 queries and edge caching of Twitch OAuth tokens.
  - Configurable proxy URL toggle in Settings.
- **Community & Documentation**:
  - Comprehensive documentation suite: [RELEASE_NOTES.md](RELEASE_NOTES.md), [CONTRIBUTING.md](CONTRIBUTING.md), [README.md](README.md).
  - Standardized GitHub issue templates for bug reports and feature requests.
  - Structured GitHub pull request template.

[1.0.0]: https://github.com/YTFL/Lycoris-Game-Tracker/releases/tag/v1.0.0
