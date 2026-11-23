# Privacy Policy — Lycoris

**Verified Zero-Telemetry**  
**Last Updated & Effective Date:** October 1, 2026

> **Our Fundamental Privacy Commitment:** Lycoris is built on an offline-first foundation. We do not require accounts, do not run analytical telemetry, and do not maintain any central servers or databases that collect your personal identity, gaming library, financial receipts, or gameplay hours. You maintain 100% data sovereignty.

---

## 1. Overview & Data Architecture

This Privacy Policy explains how **Lycoris** ("the Application", "we", "us", or "our"), an open-source personal gaming library and ROI tracking application, handles information. Unlike typical SaaS applications, Lycoris executes and stores its primary database exclusively on your physical client device.

---

## 2. Information We Do NOT Collect

We believe the best privacy guarantee is not having your data in the first place. Lycoris does NOT collect:

- **Personal Identifiers:** We do not ask for or collect names, email addresses, phone numbers, or physical addresses.
- **Account Credentials:** We do not operate a user registration database or store passwords.
- **Behavioral Telemetry:** We do not track what screens you tap, how frequently you open the app, or what games you browse.
- **Advertising Identifiers:** The application contains zero commercial SDKs, zero ad networks, and does not read Google Advertising IDs (AAID/IDFA).

---

## 3. Data Processed Locally on Your Device

When you use Lycoris to track your gaming library and calculate cost-per-hour return on investment (ROI), the following records are generated and stored exclusively within your device's sandboxed local storage using Hive NoSQL boxes (`games_vault` and `settings_box`):

- Game titles, IGDB IDs, and cover artwork URLs
- Storefront ownership tags (Steam, PlayStation, Switch, Xbox, GOG, itch.io, Physical, etc.)
- Purchase prices and selected display currencies
- Itemized additional expenditures (DLCs, expansions, microtransactions, season passes)
- Logged playtime durations (Hours, Minutes, Decimal Hours)
- Completion statuses, ratings, personal audit notes, and custom manual entries

This data remains strictly on your device unless you explicitly initiate a cloud backup or export a JSON file.

---

## 4. Google Drive™ Integration & Limited Use Disclosure

Lycoris offers an optional, user-initiated cloud backup feature powered by the official Google Drive API.

### A. Exact OAuth 2.0 Scope Requested
Lycoris requests only a single, restricted Google Drive scope:  
`https://www.googleapis.com/auth/drive.file` (`DriveApi.driveFileScope`)

### B. Strictly Limited Access Boundaries
The `drive.file` scope grants Lycoris access **ONLY** to files and folders that have been created directly by the Lycoris application. Under this scope:
- Lycoris creates and accesses a dedicated folder named `Lycoris/` at the root of your Google Drive.
- Inside this folder, it writes a single JSON backup document named `lycoris_vault_backup.json` containing your exported game library data and delta timestamps.
- **Zero Access to Personal Files:** Lycoris has **NO PERMISSION** and **NO TECHNICAL ABILITY** to view, browse, search, read, download, modify, or delete any other files, documents, photos, spreadsheets, or folders in your Google Drive.

### C. Google API Services User Data Policy Compliance
**Lycoris's use and transfer to any other app of information received from Google APIs will adhere to the [Google API Services User Data Policy](https://developers.google.com/terms/api-services-user-data-policy), including the Limited Use requirements.**

Specifically:
1. **No Human Access:** No humans (including developers of Lycoris) have access to your Google Drive files or backup data.
2. **No Third-Party Transfers:** Google user data and backup payloads are never transferred, sold, or shared with third parties or external servers.
3. **No Advertising:** Information accessed via Google APIs is never used to serve advertisements or personalize marketing.
4. **No AI/ML Training:** Information accessed via Google APIs is never used to train generalized artificial intelligence (AI) or machine learning (ML) models.

---

## 5. Cloudflare Worker Proxy & IGDB Game Metadata

To provide box art, release dates, and game summaries, Lycoris connects to the Internet Database of Video Games (IGDB v4) via a stateless Cloudflare Worker proxy:

| Endpoint | Data Transmitted | Data Retained by Proxy |
| :--- | :--- | :--- |
| `/games` Proxy | Search keywords (e.g. "Hollow Knight") and IGDB numeric IDs. | **None.** The worker is completely stateless. It caches Twitch OAuth tokens server-side to prevent API rate limits, but does not log search queries, client IPs, or library contents. |

---

## 6. Data Portability, Erasure & User Control

You have absolute control over your information at all times:

- **Export Data:** You can generate a human-readable JSON export of your complete library under *Settings > Offline JSON Backup > Import / Export*.
- **Local Deletion:** You can erase all local data by tapping *Reset Library > Clear All Game Records* in the application or by clearing app storage in your Android/iOS operating system settings.
- **Cloud Backup Deletion:** You can delete your cloud backup at any time simply by opening Google Drive in any web browser or mobile app, locating the `Lycoris/` folder, and moving it to the Trash.
- **Revoke Access:** You can disconnect Lycoris and revoke all Google Drive permissions at any time via your [Google Account Security Permissions](https://myaccount.google.com/permissions) page.

---

## 7. Children's Privacy

Lycoris does not knowingly collect or solicit personal information from children under the age of 13. Since the application does not collect personal data from any user, it is fully compliant with the Children's Online Privacy Protection Act (COPPA) and equivalent international regulations.

---

## 8. Changes to This Privacy Policy

We may update this Privacy Policy from time to time. Any modifications will be posted to this page with an updated "Last Updated" date. Continued use of the application following any changes constitutes acceptance of the revised terms.

---

## 9. Contact & Inquiries

If you have any questions, concerns, or requests regarding this Privacy Policy or the security practices of Lycoris, please contact us or open an issue on GitHub:

- **Project Repository:** [github.com/YTFL/Lycoris](https://github.com/YTFL/Lycoris)
- **Issue Tracker:** [github.com/YTFL/Lycoris/issues](https://github.com/YTFL/Lycoris/issues)
