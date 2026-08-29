import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from './user.entity';
import { OrderItem } from './order-item.entity';
import { OrderTrackingHistory } from './order-tracking-history.entity';
import { Merchant } from './merchant.entity';

export enum OrderStatus {
  PENDING = 'Pending',
  READY_FOR_PICKUP = 'Ready_For_Pickup',
  IN_TRANSIT_TO_HUB = 'In_Transit_To_Hub',
  AT_HUB = 'At_Hub',
  OUT_FOR_DELIVERY = 'Out_For_Delivery',
  DELIVERED = 'Delivered',
  PARTIALLY_DELIVERED = 'Partially_Delivered',
  POSTPONED = 'Postponed',
  CANCELED = 'Canceled',
  RTO = 'RTO', // Return To Origin
}

export enum PaymentMethod {
  COD = 'CASH_ON_DELIVERY',
  PAYMOB_CARD = 'PAYMOB_CARD',
  PAYMOB_WALLET = 'PAYMOB_WALLET',
  PAYMOB_MEEZA = 'PAYMOB_MEEZA',
  INSTAPAY = 'INSTAPAY',
}

export enum PaymentStatus {
  UNPAID = 'UNPAID',
  PAID = 'PAID',
  REFUNDED = 'REFUNDED',
}

@Entity('orders')
export class Order {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true, nullable: false })
  order_number: string;

  @Column({ nullable: true })
  merchant_id: string;

  @ManyToOne(() => Merchant, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'merchant_id' })
  merchant: Merchant;

  @Column({ nullable: false })
  customer_name: string;

  @Column({ nullable: false })
  customer_phone: string;

  @Column({ nullable: true })
  customer_secondary_phone: string;

  @Column({ nullable: false })
  shipping_address: string;

  @Column({ nullable: false, default: 'القاهرة' })
  city: string;

  @Column({ nullable: false, default: 'القاهرة' })
  governorate: string;

  @Column({ nullable: true })
  zone_id: string;

  @Column({ nullable: true })
  hub_id: string;

  @Column({
    type: 'enum',
    enum: OrderStatus,
    default: OrderStatus.PENDING,
  })
  status: OrderStatus;

  @Column({
    type: 'enum',
    enum: PaymentMethod,
    default: PaymentMethod.COD,
  })
  payment_method: PaymentMethod;

  @Column({
    type: 'enum',
    enum: PaymentStatus,
    default: PaymentStatus.UNPAID,
  })
  payment_status: PaymentStatus;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0.0 })
  total_amount: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0.0 })
  collected_amount: number;

  @Column({ type: 'decimal', precision: 6, scale: 2, default: 50.0 })
  shipping_fee: number;

  @Column({ type: 'decimal', precision: 6, scale: 2, default: 15.0 })
  driver_commission: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0.0 })
  merchant_net_payout: number;

  @Column({ default: true })
  is_cod: boolean;

  @Column({ default: false })
  is_partially_delivered: boolean;

  @Column({ nullable: true })
  assigned_driver_id: string;

  @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'assigned_driver_id' })
  assigned_driver: User;

  @Column({ nullable: true })
  waybill_qr_code: string;

  @Column({ nullable: true })
  postponement_reason: string;

  @Column({ nullable: true })
  rto_reason: string;

  @Column({ nullable: true })
  notes: string;

  @OneToMany(() => OrderItem, (item) => item.order, { cascade: true })
  items: OrderItem[];

  @OneToMany(() => OrderTrackingHistory, (history) => history.order, {
    cascade: true,
  })
  tracking_history: OrderTrackingHistory[];

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}
