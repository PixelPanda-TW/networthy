# v0.4.0 Design: Stock Assets Tracking MVP

## Scope

v0.4.0 adds a first stock/asset tracking layer on top of the v0.3.0 cash
ledger. The release focuses on manually maintained asset snapshots. It does
not model buy/sell transactions or cash-account movement yet.

This release includes:

- a new bottom navigation tab: `資產`;
- stock accounts;
- stock holdings under each stock account;
- account-level tracking modes;
- manual current price entry for valuation-mode holdings;
- principal-only holdings for selected account modes;
- asset summary rows on overview;
- archive support for stock accounts and holdings.

This release does not include:

- buy/sell transaction history;
- cash-account integration;
- automatic quotes;
- exchange-rate conversion;
- realized gain/loss;
- tax, fee, dividend, or split handling.

## Product decisions

- Bottom navigation order is `總覽`, `資產`, `紀錄`, `設定`.
- Stock account mode determines behavior. A single stock account cannot mix
  modes.
- Currencies are fixed by account mode.
- Stock accounts can be archived but not deleted.
- Stock holdings can be archived but not deleted.
- Archived accounts and holdings are hidden from active lists but remain stored.
- Stock assets appear in overview as separate summary sections. They are not
  merged with cash totals, and no cross-currency net-worth total is calculated.

## Account modes

### Taiwan stock account

This mode is for Taiwan individual stocks.

- Display label: `台股個股`
- Currency: `TWD`
- Tracking: valuation mode
- Holdings store quantity, average cost, and current price.
- The app calculates cost, market value, and unrealized gain/loss.

### Taiwan ETF account

This mode is for Taiwan ETF principal tracking.

- Display label: `台股 ETF`
- Currency: `TWD`
- Tracking: principal mode
- Holdings store principal only.
- The app does not store quantity or current price for this mode.
- The app does not calculate market value or unrealized gain/loss for this
  mode.

### US stock account

This mode is for US-market principal tracking.

- Display label: `美股`
- Currency: `USD`
- Tracking: principal mode
- Holdings store principal only.
- The app does not store quantity or current price for this mode.
- The app does not calculate market value or unrealized gain/loss for this
  mode.

## Data model

### StockAccount

`StockAccount` represents a container for stock holdings.

Fields:

- `id`: UUID string.
- `name`: user-visible account name, up to 30 Unicode code points after
  trimming.
- `mode`: one of `taiwanStock`, `taiwanEtf`, `usStock`.
- `currencyCode`: derived from `mode`; persisted for stable querying.
- `isArchived`: archived accounts are hidden from active account lists.
- `createdAtUtc`: UTC creation timestamp.
- `updatedAtUtc`: UTC update timestamp.

Validation:

- `id` must be a UUID string.
- `name` is required after trimming and must be at most 30 Unicode code points.
- `mode` must be one of the supported modes.
- `currencyCode` must match the selected mode.
- timestamps must be UTC.
- active account names must be unique within the same mode.

### StockHolding

`StockHolding` represents one holding/principal row under a stock account.

Common fields:

- `id`: UUID string.
- `accountId`: parent stock account id.
- `symbol`: user-entered stock or ETF symbol.
- `name`: user-visible security name.
- `isArchived`: archived holdings are hidden from active holding lists.
- `createdAtUtc`: UTC creation timestamp.
- `updatedAtUtc`: UTC update timestamp.

Valuation-mode fields, used only by Taiwan stock accounts:

- `quantityMicro`: quantity stored as fixed-point units with 6 decimal places.
- `averageCostMinor`: average cost price stored with 2 decimal places.
- `currentPriceMinor`: current price stored with 2 decimal places.

Principal-mode fields, used only by Taiwan ETF and US stock accounts:

- `principalMinor`: manually tracked principal amount in the account currency.

Validation:

- `symbol` and `name` are required after trimming.
- `quantityMicro` must be positive for valuation-mode holdings.
- `averageCostMinor` must be non-negative for valuation-mode holdings.
- `currentPriceMinor` must be non-negative for valuation-mode holdings.
- `principalMinor` must be non-negative for principal-mode holdings.
- principal-mode holdings must not require quantity or current price input.

## Calculations

### Valuation mode

For Taiwan stock holdings:

- cost = `quantity * averageCost`
- market value = `quantity * currentPrice`
- unrealized gain/loss = `market value - cost`

Implementation uses integer fixed-point arithmetic:

- quantity scale: 6 decimal places;
- price scale: 2 decimal places.

Rounding policy:

- display currency amounts rounded to the nearest minor currency unit;
- intermediate calculations stay in integer/fixed-point form.

### Principal mode

For Taiwan ETF and US stock holdings:

- principal = `principalMinor`
- market value is not calculated;
- unrealized gain/loss is not calculated.

## Repository contracts

Add a stock asset repository layer separate from the existing cash ledger:

- `StockAccountRepository`
  - list active accounts;
  - list all accounts;
  - find by id;
  - create;
  - rename;
  - archive.

- `StockHoldingRepository`
  - list active holdings by account;
  - list all holdings by account;
  - find by id;
  - save valuation-mode holding;
  - save principal-mode holding;
  - archive.

The cash `AccountRepository` and `LedgerRepository` remain unchanged.

## Database migration

The Drift schema moves from version 3 to version 4.

New tables:

- `stock_accounts`
- `stock_holdings`

Migration from v3:

1. Create stock account and holding tables.
2. Do not seed default stock accounts.
3. Preserve all v3 cash ledger data unchanged.

No data backfill is required because v0.4.0 introduces new asset data.

## Application behavior

Stock account use cases:

- create stock account with name and mode;
- rename stock account;
- archive stock account;
- list active stock accounts;
- list all stock accounts for historical/future display.

Stock holding use cases:

- add valuation holding under Taiwan stock account;
- edit valuation holding;
- add principal holding under Taiwan ETF or US stock account;
- edit principal holding;
- archive holding;
- list active holdings for an account.

Validation:

- valuation holding commands are accepted only for Taiwan stock accounts;
- principal holding commands are accepted only for Taiwan ETF and US stock
  accounts;
- archived accounts cannot receive new or edited active holdings;
- archived holdings cannot be edited from the active management UI.

## UI behavior

### Bottom navigation

Add a `資產` tab between `總覽` and `紀錄`.

Order:

1. `總覽`
2. `資產`
3. `紀錄`
4. `設定`

### Assets page

The `資產` page contains:

- stock account list;
- account creation action;
- account rename action;
- account archive action;
- selected account detail area;
- holding list under the selected account;
- holding creation action;
- holding edit action;
- holding archive action.

Account creation fields:

- account name;
- account mode:
  - `台股個股`;
  - `台股 ETF`;
  - `美股`.

Valuation holding fields:

- symbol;
- name;
- quantity;
- average cost;
- current price.

Principal holding fields:

- symbol;
- name;
- principal.

### Overview page

Overview keeps the existing cash ledger summary and adds asset summary sections.

Example display:

- `現金 TWD：NT$10,000`
- `台股個股市值：NT$200,000`
- `台股 ETF 本金：NT$100,000`
- `美股本金：US$5,000`

Rules:

- cash totals and stock asset summaries are displayed separately;
- TWD and USD are not converted or combined;
- principal-mode rows are labeled as principal, not market value;
- valuation-mode rows are labeled as market value and may show unrealized
  gain/loss.

### Settings page

Stock asset management is not placed under Settings. Settings remains for app
configuration, category management, account management for cash accounts,
security, and local data controls.

## Error handling

Use existing application failure patterns:

- validation failures return safe user-visible messages;
- persistence failures show a generic local-save/load failure message;
- no sensitive database paths, keys, or raw exceptions are shown in UI.

Expected validation messages should be explicit and localizable later:

- account name required;
- holding symbol/name required;
- quantity must be positive;
- price must be a valid amount with at most 2 decimal places;
- principal must be a valid non-negative amount;
- account mode does not support this holding type.

## Testing strategy

Domain tests:

- stock account mode determines fixed currency;
- stock account validation;
- valuation holding fixed-point quantity and price validation;
- principal holding validation;
- valuation calculations for cost, market value, and unrealized gain/loss.

Repository contract tests:

- create, rename, archive stock accounts;
- save, edit, archive valuation holdings;
- save, edit, archive principal holdings;
- active lists hide archived rows;
- all lists preserve archived rows.

Data tests:

- Drift migration from v3 to v4 creates stock tables without changing cash
  ledger data;
- stock account and holding repositories persist and reload data.

Application tests:

- account use cases reject invalid mode/currency combinations;
- holding use cases reject mismatched account modes;
- archived accounts reject new holdings.

Presentation tests:

- bottom navigation includes `資產` in the expected order;
- assets page creates, renames, and archives a stock account;
- assets page creates valuation holdings for Taiwan stock accounts;
- assets page creates principal holdings for Taiwan ETF and US stock accounts;
- overview displays cash and stock summaries separately.

Release verification:

- `flutter test`
- `flutter analyze`
- `flutter build apk --release`
- `flutter build ios --simulator`
- `git diff --check`
