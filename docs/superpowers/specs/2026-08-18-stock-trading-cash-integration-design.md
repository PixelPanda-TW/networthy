# v0.5/v0.6 Design: Stock Trading and Cash Integration

## Scope

v0.5 adds manually entered stock buy/sell trades and synchronizes each trade
with one same-currency cash account and the stock holding snapshot. The
operation is atomic: the trade record, holding update, and cash ledger entry
are committed together or none is committed.

v0.6 adds editing, deletion/voiding, historical average-cost recalculation,
realized gain/loss, and richer trade reports. Those behaviors are explicitly
outside v0.5.

## Product decisions

- Stock accounts and cash accounts remain separate account types.
- A trade must select one active stock account and one active cash account.
- The cash account currency must match the stock account's fixed currency.
- Buy debits the cash ledger and increases the holding snapshot.
- Sell credits the cash ledger and decreases the holding snapshot.
- Selling more than the current holding quantity or principal is rejected.
- Archived stock or cash accounts cannot be used for new trades.
- v0.5 excludes fees, taxes, dividends, splits, exchange-rate conversion, and
  automatic quotes.
- A trade's price becomes the current price for a Taiwan individual-stock
  holding after a successful buy or sell.
- Historical trades are append-only in v0.5; editing and deletion are v0.6.

## Account-mode behavior

### Taiwan individual stocks

- Currency is TWD.
- A trade requires `quantityMicro` and `priceMinor`.
- Buy quantity is added to the holding.
- Sell quantity is subtracted and cannot exceed the holding quantity.
- Buy updates weighted average cost:

  ```text
  newCost = oldQuantity * oldAverageCost + buyQuantity * buyPrice
  newAverageCost = round(newCost / newQuantity)
  ```

- Buy and sell set the holding current price to the trade price.
- Sell does not change average cost for the remaining quantity.
- When a sell consumes the complete quantity, the holding snapshot is archived
  at zero quantity; a later buy creates a new active snapshot.

### Taiwan ETF and US stocks

- Taiwan ETF currency is TWD; US stock currency is USD.
- A trade requires `principalMinor` and has no quantity or price fields.
- Buy adds principal; sell subtracts principal.
- The result must not be negative.
- No market value, quantity, average cost, or unrealized gain/loss is
  calculated for these modes.
- When a sell consumes the complete principal, the holding snapshot is archived
  at zero principal; a later buy creates a new active snapshot.

### Cash movement

- For Taiwan individual stocks, the cash amount is
  `quantityMicro * priceMinor / quantityScale`, rounded to the repository's
  existing minor-unit convention.
- For Taiwan ETF and US stocks, the cash amount is `principalMinor`.
- A buy writes the amount as an investment expense and a sell writes it as an
  investment income, using stable application-owned categories. No fee or tax
  entry is generated in v0.5.

## Trade data model

`StockTrade` contains:

- `id`: UUID;
- `stockAccountId`;
- `cashAccountId`;
- `side`: `buy` or `sell`;
- `symbol` and `name`;
- `accountMode` and persisted `currencyCode`;
- nullable `quantityMicro` and `priceMinor` for Taiwan individual stocks;
- nullable `principalMinor` for Taiwan ETF and US stocks;
- `tradeDate`;
- optional `note`;
- UTC creation and update timestamps.

The database adds a `stock_trades` table and migrates from schema v4 to v5.
Existing cash ledger and v0.4 stock snapshots are preserved without backfill.

## Atomic application service

`ExecuteStockTradeUseCase` validates and coordinates the operation:

1. Load the active stock account.
2. Load the active cash account.
3. Verify currency compatibility.
4. Load the active holding for the stock account and symbol, if present.
5. Validate mode-specific fields and sell limits.
6. Create the stock trade row.
7. Update or create the stock holding snapshot.
8. Calculate the cash movement and create a ledger aggregate for the cash
   movement.
9. Commit all writes in one database transaction.

Repository/application failures use `ApplicationFailure.validation(...)` for
user-correctable errors and the existing persistence-safe failure for storage
errors. A failed operation must leave the trade table, holding snapshot, and
cash ledger unchanged.

## UI flow

The `資產` page adds `買入` and `賣出` actions to active stock account cards.
The form selects the stock account and a compatible active cash account,
collects symbol/name, mode-specific trade fields, date, and note. On success,
the page refreshes holdings and the overview refreshes its stock and cash
summaries.

The v0.5 trade history is shown as read-only rows. Each row identifies the
side, symbol, amount, date, and linked accounts. No edit or delete action is
shown until v0.6.

## v0.6 boundary

v0.6 will rebuild the affected holding state from the append-only trade
history when a trade is edited, voided, or removed. It will then calculate
realized gain/loss for Taiwan individual stocks and expose trade reports.
The v0.6 design must define whether deletion is a tombstone/void operation or
physical deletion before implementation begins.

## Verification

v0.5 requires tests for domain validation, same-currency enforcement,
weighted-cost updates, principal updates, repository persistence, schema v5
migration, atomic rollback, application failure mapping, and assets/overview
widget flows. Release verification must run the complete Flutter test suite,
analyzer, Android release build, iOS simulator build, and `git diff --check`.
