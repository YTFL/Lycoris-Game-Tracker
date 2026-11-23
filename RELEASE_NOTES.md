# Lycoris Version 1.1.0 Release Notes

**Release Date:** November 23, 2026  
**Milestone:** v1.1.0 Maintenance & UI Polish Release  
**License:** GNU Affero General Public License v3.0 (AGPL-3.0)  

---

## Overview

Lycoris **v1.1.0** is a visual refinement and UI polish update that harmonizes accent colors across the app to adhere strictly to the Spider Lily Crimson and dark obsidian/slate design system, eliminates jarring green UI artifacts, and removes unnecessary visual clutter from Settings.

---

## What's Changed in v1.1.0

### 1. UI Color Harmonization & Crimson Consistency
- **Minimized Proxy Connection Status**:
  - Replaced the verbose `"Connection successful. Cloudflare proxy is operational."` text with a concise `"Proxy operational"` (or `"Connection failed"`) indicator.
  - Eliminated the bright green alert box (`LycorisColors.success` / `#10B981`) in favor of a sleek, compact container styled with `colorScheme.surfaceContainerHigh`, a subtle Spider Lily Crimson border (`colorScheme.primary.withAlpha(80)`), crimson icon, and on-surface typography.
- **Floating Themed Notifications**:
  - Added global `snackBarTheme` to `ThemeData` enforcing floating, rounded dark slate capsules (`surfaceContainerHighest`) with outline borders across the entire app.
  - Standardized all toast feedback in Settings through a unified notification helper, replacing solid full-bleed green, blue, amber, and red blocks.
- **Rogue Green Removals**:
  - Replaced the green lock icon (`Icons.lock_rounded`) on saved Developer API credentials with `colorScheme.primary`.
  - Replaced the hardcoded green highlight (`0xFF10B981`) on the "Check for Updates" button when an update is available with `colorScheme.primary`.
  - Preserved Top 5 rankings tier metal colors in `RankingTier` (Diamond `#00E5FF`, Platinum `#E2E8F0`, Gold `#F59E0B`, Silver `#94A3B8`, Bronze `#D97706`).

---

### 2. Settings Clutter Reduction
- **Conversion Benchmark Removal**:
  - Removed the multi-currency chip matrix (`"CONVERSION BENCHMARK (BASE: 1 USD)"`) from the **Display Currency & FX Rates** card to streamline the view, keeping only the Primary Currency selector and the live sync tile.
- **Footer Subtitle Removal**:
  - Removed the `"Offline-first gaming library & investment ROI tracker"` subtitle from the bottom of the Settings page for a cleaner, minimal branding footer.

---

### 3. Game Rankings Overhaul, Calibration Fixes & Anti-Bias Polish
- **Playtime & Rating Visibility**:
  - Added formatted playtime (`TimeNormalizer.format`) and user personal star ratings to the Top 5 showcase (Podium slots #1–#3 and sub-tier cards #4–#5).
  - Added personal star ratings to list tiles across all remaining ranks (#6+).
- **Elo Calibration & Matchmaking Fixes**:
  - Fixed premature session termination where "Rank New Games" stopped after 3 comparisons; sessions now run through their full scheduled comparison count.
  - Replaced arbitrary flat 1200.0 baseline ratings with informed Elo seeding from personal ratings ($\text{initialElo} = 800.0 + \text{personalRating} \times 80.0$).
  - Introduced `PreRankRatingSheet` to ensure unrated completed games are rated prior to starting ranking comparisons.
  - Implemented accelerated progressive K-factors ($K=64 \rightarrow 48 \rightarrow 32 \rightarrow 20$) and library benchmarking to quickly slot newly added games into their true position without degrading established leaderboards.
- **Anti-Bias & Anti-Manipulation Updates**:
  - "Help Me Choose": Removed `<game> takes the lead` and `Evenly matched` score tickers to prevent user preference bias; changed confirmation button to `"Continue"`.
  - "Help Me Rate": Hid the live numerical average score from the top card and Apply button to prevent artificial score manipulation.
