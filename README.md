# Expenses Dashboard

A Flutter desktop app for exploring personal expense transactions stored in a
SQLite database. Point it at your `expenses.db` and it gives you a filterable,
searchable transaction table plus KPIs and charts.

## Features

- **Transactions table** — sortable, paginated, resizable columns, free-text
  search (Ctrl+F), per-row detail dialog, CSV export via a save dialog.
- **Overview charts** — spending over time, spending by category, spending by
  bank, and a category-share donut. Charts always reflect exactly the rows on
  screen, including any active search.
- **KPI header** — expenses, income, net, transaction count, average and
  largest expense, savings rate, with ▲/▼ deltas against the previous
  month/year/period.
- **Filters** — monthly (year + month dropdowns, limited to months that have
  data) or a custom date range, plus a multi-select category checklist scoped
  to the selected period. Transfers between your own accounts
  (`category = TRANSFERS`) are excluded everywhere.
- **Theming** — a set of curated colour themes (light/dark/system) with a
  colour-intensity setting (tonal / vibrant / expressive seed-scheme
  variants), selectable Google Fonts and text size, all persisted.

## Data format

The app reads a single `expenses` table with these columns:

| column        | type | notes                          |
| ------------- | ---- | ------------------------------ |
| `date`        | TEXT | `YYYY-MM-DD`                   |
| `description` | TEXT |                                |
| `debit`       | TEXT/REAL | spend amount (0 if credit) |
| `credit`      | TEXT/REAL | income amount (0 if debit) |
| `source`      | TEXT | bank/account name              |
| `category`    | TEXT |                                |

On first launch the app asks you to choose the database file (you can change
it later under **Settings → Data source**).

## Running

```sh
flutter pub get
flutter run -d linux    # or -d macos / -d windows
```

This is a desktop app (Linux/macOS/Windows); it uses `sqflite_common_ffi` and
local file access, so there is no web target.

## Development

```sh
flutter analyze
flutter test
```

Pure logic (SQL fragment building, CSV export, aggregations, filter state) is
kept in `lib/services/query_builder.dart` and the providers so it can be unit
tested without a UI; `test/database_service_test.dart` exercises the SQL layer
against an in-memory SQLite database. CI runs analyze + test on every PR.
