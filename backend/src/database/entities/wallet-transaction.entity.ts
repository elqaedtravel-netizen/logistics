import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

export enum EntityType {
  MERCHANT = 'MERCHANT',
  DRIVER = 'DRIVER',
  COMPANY_VAULT = 'COMPANY_VAULT',
}

export enum WalletTransactionType {
  ORDER_DELIVERY_CREDIT = 'ORDER_DELIVERY_CREDIT',
  SHIPPING_FEE_DEBIT = 'SHIPPING_FEE_DEBIT',
  DRIVER_COMMISSION_CREDIT = 'DRIVER_COMMISSION_CREDIT',
  DRIVER_CASH_COLLECTED = 'DRIVER_CASH_COLLECTED',
  DRIVER_CASH_SETTLEMENT = 'DRIVER_CASH_SETTLEMENT',
  INSTAPAY_DEPOSIT = 'INSTAPAY_DEPOSIT',
  MERCHANT_WITHDRAWAL = 'MERCHANT_WITHDRAWAL',
  RTO_FEE_DEBIT = 'RTO_FEE_DEBIT',
}

@Entity('wallet_transactions')
export class WalletTransaction {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({
    type: 'enum',
    enum: EntityType,
    nullable: false,
  })
  entity_type: EntityType;

  @Column({ nullable: false })
  entity_id: string; // merchant_id or driver_id

  @Column({
    type: 'enum',
    enum: WalletTransactionType,
    nullable: false,
  })
  transaction_type: WalletTransactionType;

  @Column({ type: 'decimal', precision: 12, scale: 2, nullable: false })
  amount: number;

  @Column({ type: 'decimal', precision: 12, scale: 2, nullable: false })
  balance_before: number;

  @Column({ type: 'decimal', precision: 12, scale: 2, nullable: false })
  balance_after: number;

  @Column({ nullable: true })
  reference_order_id: string;

  @Column({ nullable: true })
  payment_reference: string; // e.g. InstaPay Tx ID or Bank ref

  @Column({ nullable: true })
  notes: string;

  @CreateDateColumn()
  created_at: Date;
}
