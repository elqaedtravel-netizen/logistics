export enum LedgerTransactionType {
  CASH_COLLECTED = 'CASH_COLLECTED', // Cash collected from customer for COD order (+)
  COMMISSION_EARNED = 'COMMISSION_EARNED', // Commission due to driver (+)
  SETTLEMENT_PAYOUT = 'SETTLEMENT_PAYOUT', // Cash handed over to company / balance settled (-)
  ADJUSTMENT = 'ADJUSTMENT', // Administrative correction (+ / -)
}
