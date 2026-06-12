# Expenses UI

## Requirements

1. This is a application that renders Expenses transactions.
2. It is written in Flutter. 
3. It reads a Sqlite Database from the provided location and renders the transactions. 
4. Multiple filter criteria is offered:
  a. User can select monthly/category wise
  b. Custom periods
  c. One/more categories in a customer period
5. Use Riverpod for state management
6. Use a modern Material 3 design language: soft surfaces, rounded corners,
   ambient palette-coloured accents.
7. Color themes: a curated set of seed-based palettes (defined in
   `lib/theme/app_themes.dart`). Each theme provides three seed colours for
   the Material colour scheme plus a six-colour, high-contrast chart palette,
   and supports light/dark/system mode.

8. Dont use Bottom navigation bar
9. Use a sidebar to select options like Dashboard, settings
10. Each transaction shoulld have the following:
  a. SNO
  b. Date
  c. Description
  d. Amount
  e. Bank
  f. Category

11. Render the transactions in a table format sorted by date.
12. Use Latest Flutter UI widgets available.
