# Alkoholfrei-Tracker — Plan

MVP for a private, offline iOS app (DE/AT/CH). No account, no server, no analytics, no third-party SDKs. Supportive, neutral wording. The app does not treat addiction and does not give medical advice.

This file is the plan. Implementation starts after your OK.

## Decisions to confirm

1. **Fastenzeit length.** The challenge runs from Aschermittwoch through Karsamstag. That span is Easter − 46 days through Easter − 1 day (46 calendar days). Onboarding calls it „Fastenzeit“ and shows the computed dates for the relevant year. The traditional phrase „40 Tage“ stays in the subtitle as the familiar name, while the counter uses the real calendar span.
2. **Free vs Pro.** Free includes the counter, daily check-in, one active challenge (any of the three types, chosen in onboarding), and basic stats (totals plus the current month). Pro unlocks switching or starting another challenge, full statistics (week and month breakdowns, full heatmap history), and the widget. Multiple habits stay out of this MVP. Say if you want a stricter gate.
3. **Streak.** An explicit „Heute getrunken“ resets the current streak and keeps the total of alcohol-free days. A day with no log does not count as alcohol-free. The streak is the run of logged alcohol-free days that reaches yesterday (if today is still open) or today (if today is logged alcohol-free). A gap of unlogged days ends that run.
4. **Savings.** Estimated: `(sum of weekly count × price) / 7 × alcohol-free days`, same idea for kcal. The UI says „geschätzt“.
5. **Project layout.** The Xcode template in this repo is replaced by an XcodeGen `project.yml` (app, widget extension, unit tests, shared App Group). That stays inside this project.
6. **Help contacts.** The Hilfe screen names known services (Sucht & Drogen Hotline, BZgA / kenn-dein-limit, plus a short note for AT/CH). Phone numbers and URLs are `TODO(Goran)` until you confirm the current ones. Nothing invented goes into the binary as a fact.
7. **Tests.** Swift Testing (`import Testing`), matching the template style. No UI-test target in the generated project.
8. **Bundle IDs (placeholders only).** `TODO(Goran)` before App Store:
   - App: `de.example.alkoholfrei-tracker`
   - Widget: `de.example.alkoholfrei-tracker.widget`
   - Tests: `de.example.alkoholfrei-tracker.tests`
   - App Group: `group.de.example.alkoholfrei-tracker`

## Stack

- Swift 5.9+, SwiftUI, iOS 17+, SwiftData, WidgetKit, UserNotifications, StoreKit 2.
- `@Observable` view models. Small files. No force unwraps.
- String Catalog `Localizable.xcstrings`: German is the development language, English is the translation.
- Dark Mode via system colors, Dynamic Type, VoiceOver labels on every control.
- Display name: **Alkoholfrei-Tracker**.

## Data model (SwiftData, on device)

One store in the app container. The widget does not open the SwiftData store. The app writes a small snapshot into the App Group (UserDefaults) whenever check-ins, drinks, or the challenge change.

### `UserSettings` (one row)

| Field | Purpose |
|---|---|
| `id` | UUID |
| `onboardingCompleted` | Bool |
| `goalKind` | `dryJanuary`, `lent`, `custom`, `openEnded` |
| `trackingStartDate` | First day the user wants to count from |
| `reminderEnabled` | Bool |
| `reminderHour`, `reminderMinute` | Local time, default 20:00 |
| `createdAt` | Date |

### `DrinkTemplate`

Typical weekly drinking, used only as the savings estimate.

| Field | Purpose |
|---|---|
| `id` | UUID |
| `name` | e.g. Bier, Glas Wein |
| `weeklyCount` | Double, ≥ 0 |
| `priceEUR` | Decimal |
| `kcalPerUnit` | Double, default suggestions only (editable) |
| `sortOrder` | Int |

Defaults offered in onboarding, all editable: Bier (0,5 l) 2,50 € / 210 kcal, Glas Wein 3,00 € / 120 kcal, other drink left blank for the user. Defaults are labeled as starting points, not nutrition advice.

### `DayLog` (one per calendar day)

| Field | Purpose |
|---|---|
| `id` | UUID |
| `day` | Start of day in the current calendar |
| `status` | `alcoholFree` or `drank` |
| `updatedAt` | Date |

### `ActiveChallenge` (at most one for free; Pro may replace it)

| Field | Purpose |
|---|---|
| `id` | UUID |
| `kind` | `dryJanuary`, `lent`, `custom`, `openEnded` |
| `title` | Display name |
| `startDate` | Inclusive |
| `endDate` | Inclusive, nil when open-ended |
| `year` | Seasonal year, nil for custom / open-ended |

Seasonal dates are computed, then stored, so a challenge does not shift if the user travels across a year boundary mid-challenge.

### `BadgeUnlock`

| Field | Purpose |
|---|---|
| `id` | UUID |
| `dayCount` | 1, 7, 14, 31, 40, 100 |
| `unlockedAt` | Date the total alcohol-free days first reached this mark |

Badges use **total alcohol-free days**, so a slip does not remove them.

### Widget snapshot (App Group, not SwiftData)

```text
alcoholFreeDays: Int
streakDays: Int
moneySavedEUR: Decimal
challengeTitle: String?
updatedAt: Date
```

Money is an estimate the user already entered. The snapshot has no free-text notes and no health diagnosis.

## Domain logic (pure, unit-tested)

- `EasterCalendar.easterSunday(year:)` — Meeus/Jones/Butcher (Anonymous Gregorian). Gregorian calendar, `Calendar` with time zone `Europe/Berlin` for civil dates shown to DE/AT/CH.
- `EasterCalendar.ashWednesday(year:)` = Easter − 46 days.
- `EasterCalendar.holySaturday(year:)` = Easter − 1 day.
- `ChallengeSchedule.dryJanuary(year:)` = 1 January … 31 January.
- `ChallengeSchedule.lent(year:)` = Ash Wednesday … Holy Saturday. The year argument is the year of Easter (Fastenzeit 2027 starts 10 February 2027).
- `ChallengeSchedule.custom(start:lengthDays:)`.
- `StreakCalculator` — rules in decision 3.
- `SavingsCalculator` — rules in decision 4. Week and month totals group alcohol-free days by calendar week (Monday start, ISO) and calendar month.
- `MilestoneCatalog` — thresholds 1, 7, 14, 31, 40, 100.

### Tests (milestone 1)

- 2027: Aschermittwoch 10.02.2027, Ostern 28.03.2027, Karsamstag 27.03.2027.
- Extra Easter Sundays so the algorithm is not a single-point check: 2024-03-31, 2025-04-20, 2026-04-05, 2028-04-16.
- Dry January 2026 is 31 days, 1 Jan through 31 Jan.
- Lent 2027 is 46 days, 10 Feb through 27 Mar.
- Slip resets streak and keeps the alcohol-free total.
- An open today does not break a streak that reached yesterday.
- A gap day with no log ends the streak.
- Savings: 7 beers/week at 2 € → 2 € per alcohol-free day.
- Badge at 7 stays unlocked after a later slip.

## Screens

German is the source copy. English lives in the string catalog.

| Screen | Role |
|---|---|
| Onboarding 1 | Pick a goal: Dry January (1.–31. Januar), Fastenzeit (Aschermittwoch–Karsamstag, with computed dates), Eigenes Ziel (length in days or open-ended). |
| Onboarding 2 | Start date. Default: today, or the challenge start if that day is still ahead. |
| Onboarding 3 | Weekly drinks: name, times per week, price in €, kcal. Add and remove rows. Skip allowed (savings stay at 0). |
| Heute | Big alcohol-free count, streak, active challenge with countdown and progress ring, money saved, kcal saved, garden, today’s two actions. |
| Check-in | „Heute alkoholfrei“ and „Heute getrunken“. Slip copy: „Alles gut. Deine alkoholfreien Tage bleiben gezählt. Die Serie beginnt beim nächsten alkoholfreien Tag von vorn.“ Same-day change is allowed. |
| Fortschritt | Garden that grows with total alcohol-free days (SwiftUI shapes and SF Symbols: seed, sprout, leaves, plant, bush, tree). Badge row for 1 / 7 / 14 / 31 / 40 / 100. |
| Statistik | Month calendar heatmap (free: current month; Pro: browse other months). Totals. Pro: money and kcal per week and per month. |
| Einstellungen | Drinks and prices, reminder time, Pro / Paywall, Daten zurücksetzen (confirm), Hilfe & Beratung, Datenschutz, Impressum. |
| Paywall | German. Monthly, yearly, optional lifetime. Restore Purchases. Feature list matches the free/Pro split above. |
| Hilfe & Beratung | Short supportive text plus links. Explicit line: the app is a private Tagebuch, not treatment and not medical advice. Contacts marked `TODO(Goran)` until confirmed. |
| Datenschutz | On-device only. Matches `PRIVACY.md`. |
| Impressum | Placeholder sections (name, address, contact) filled with `TODO(Goran)`. |

Tabs: **Heute**, **Fortschritt**, **Statistik**, **Einstellungen**.

Garden stages (by total alcohol-free days): 0 seed, 1–6 sprout, 7–13 young plant, 14–30 plant, 31–99 bush, 100+ tree. Decorative only.

## Notifications

One daily local notification at the chosen time. Repeating calendar trigger. Body rotates by day-of-year through a fixed German list, for example:

- „Kurzer Check-in: Wie war dein Tag?“
- „Dein Zähler wartet auf den heutigen Eintrag.“
- „Ein alkoholfreier Tag ist ein alkoholfreier Tag.“

No medical claims, no guilt. Tapping opens the app on Heute. Changing the time reschedules. Turning it off removes pending requests. Permission is requested at the end of onboarding and again from Einstellungen.

## Widget (Pro)

Small and medium, WidgetKit.

- Small: alcohol-free days and streak.
- Medium: alcohol-free days, streak, estimated money saved.

Timeline reloads when the app writes a new snapshot. If the user is not Pro, the widget shows a short locked state („Pro zeigt Tage, Serie und Ersparnis“) and still contains no third-party code. Free users can add the widget; it stays in the locked state. `TODO(Goran)`: confirm you want the locked widget rather than hiding the extension.

## StoreKit 2

Product IDs, prices set later in App Store Connect:

| ID | Type |
|---|---|
| `pro.monthly` | Auto-renewable |
| `pro.yearly` | Auto-renewable |
| `pro.lifetime` | Non-consumable |

Local `Products.storekit` with placeholder prices for Xcode testing (those numbers are test config, not real prices). `PurchaseManager` reads `Transaction.currentEntitlements`, finishes transactions, and exposes `isPro`. Restore uses `AppStore.sync()`. No receipt server.

Paywall copy states what Pro unlocks. It does not claim health outcomes.

## File layout (after milestone 1 replaces the template)

```text
project.yml
AlkoholfreiTracker/
  App/                  entry, container, root tabs
  Domain/               Easter, challenges, streak, savings, badges
  Persistence/          SwiftData models, widget snapshot
  Features/Onboarding/
  Features/Home/
  Features/Progress/
  Features/Statistics/
  Features/Settings/
  Features/Paywall/
  Features/Help/
  Notifications/
  Purchases/
  Resources/Localizable.xcstrings
  Resources/Products.storekit
AlkoholfreiWidget/
AlkoholfreiTrackerTests/
PLAN.md
README.md                 milestone 6, started earlier if useful
APPSTORE.md               milestone 6
PRIVACY.md                milestone 6
```

## Milestones

Each milestone ends with `xcodegen`, `xcodebuild test` on an iPhone simulator, fixes, a git commit, and a short summary. No push.

### 1 — Data model, challenge dates, tests

SwiftData models, Easter and challenge math, streak, savings, badges, widget snapshot type (no widget UI yet). Unit tests listed above. App still shows a quiet placeholder home so the target builds. Replace the template project with XcodeGen.

### 2 — Onboarding, home, check-in

Three onboarding screens, tab shell, Heute with counter, streak, challenge ring, savings, and the two check-in actions. VoiceOver labels and Dynamic Type on these screens.

### 3 — Stats, garden, badges

Fortschritt garden and badges. Statistik heatmap and totals. Week/month breakdowns behind the Pro flag (a debug override in Settings, `#if DEBUG`, so we can test before StoreKit). Editing a past day from the calendar, with the same kind slip copy.

### 4 — Notifications and widget

Daily reminder, German rotating texts, time picker. Widget extension, App Group, small and medium families, snapshot refresh.

### 5 — StoreKit paywall

`Products.storekit`, `PurchaseManager`, German paywall, Restore, Pro gates wired to real entitlements. Debug override remains available only in DEBUG builds.

### 6 — Polish, localization, store texts

English strings, empty states, reset flow, Hilfe / Datenschutz / Impressum, accessibility pass. `README.md` (architecture, build, local IAP test). `APPSTORE.md` in German: name, subtitle ≤ 30 characters, keywords ≤ 100 characters covering Alkoholfrei, Dry January, Trockener Januar, Fastenzeit, weniger trinken, Tage ohne Alkohol, description draft, two Custom Product Page ideas (Dry January, Fastenzeit). `PRIVACY.md` for the privacy label „Data Not Collected“.

## Wording rules

- Supportive and neutral. A slip is a logged day, not a failure.
- No claim that the app treats addiction, diagnoses anything, or gives medical advice.
- Savings and calories are estimates from numbers the user entered.
- `TODO(Goran)` marks anything you must decide: signing team, bundle ID, real product prices, Impressum, confirmed help URLs and phone numbers, support URL, screenshots.

## What you will do manually (also listed again at the end)

- Apple Developer signing team and final bundle IDs (app, widget, App Group).
- App Store Connect app record, products `pro.monthly`, `pro.yearly`, `pro.lifetime`, and real prices.
- Screenshots and Custom Product Pages.
- Impressum with your legal details.
- Confirm help-line numbers and URLs.
- Privacy label in App Store Connect using `PRIVACY.md`.
- Push the git remote, if you want one. This plan does not push.

## Out of scope for the MVP

Accounts, iCloud sync, analytics, ads, third-party SDKs, Apple Watch, multiple parallel habits, social features, export.
