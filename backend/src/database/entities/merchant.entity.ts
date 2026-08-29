import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';

@Entity('merchants')
export class Merchant {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ nullable: false })
  business_name: string;

  @Column({ nullable: true })
  commercial_register: string;

  @Column({ nullable: true })
  tax_id: string;

  @Column({ nullable: false })
  contact_name: string;

  @Column({ nullable: false })
  contact_phone: string;

  @Column({ nullable: true })
  contact_email: string;

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0.0 })
  wallet_balance_egp: number;

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0.0 })
  cod_hold_balance_egp: number; // المبلغ المحتجز قيد التسليم

  @Column({ type: 'decimal', precision: 6, scale: 2, default: 50.0 })
  default_shipping_fee_egp: number;

  @Column({ type: 'decimal', precision: 6, scale: 2, default: 25.0 })
  return_shipping_fee_egp: number;

  @Column({ nullable: true })
  bank_account_number: string;

  @Column({ nullable: true })
  bank_iban: string;

  @Column({ nullable: true })
  instapay_address: string;

  @Column({ nullable: true })
  user_id: string;

  @Column({ default: true })
  is_active: boolean;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}
