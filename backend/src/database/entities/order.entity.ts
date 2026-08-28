import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  OneToMany,
  JoinColumn,
  Index,
} from 'typeorm';
import { OrderStatus } from '../../common/enums/order-status.enum';
import { PaymentMethod, PaymentStatus } from '../../common/enums/payment-method.enum';
import { PostponementReason } from '../../common/enums/postponement-reason.enum';
import { User } from './user.entity';
import { OrderItem } from './order-item.entity';
import { OrderTrackingHistory } from './order-tracking-history.entity';
import { DriverLedger } from './driver-ledger.entity';
import { PaymentTransaction } from './payment-transaction.entity';

@Entity('orders')
export class Order {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index({ unique: true })
  @Column({ type: 'varchar', length: 50, unique: true })
  order_number: string;

  @Column({ type: 'uuid', nullable: true })
  customer_id: string;

  @ManyToOne(() => User, (user) => user.orders_as_customer, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'customer_id' })
  customer: User;

  @Column({ type: 'varchar', length: 255 })
  customer_name: string;

  @Column({ type: 'varchar', length: 50 })
  customer_phone: string;

  @Column({ type: 'text' })
  shipping_address: string;

  @Column({ type: 'varchar', length: 100, default: 'Cairo' })
  city: string;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  geo_lat: number;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  geo_lng: number;

  @Index()
  @Column({
    type: 'enum',
    enum: OrderStatus,
    default: OrderStatus.Pending,
  })
  status: OrderStatus;

  @Column({
    type: 'enum',
    enum: PaymentMethod,
    default: PaymentMethod.CASH_ON_DELIVERY,
  })
  payment_method: PaymentMethod;

  @Column({
    type: 'enum',
    enum: PaymentStatus,
    default: PaymentStatus.UNPAID,
  })
  payment_status: PaymentStatus;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  subtotal: number;

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 50.0 })
  shipping_fee: number;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  total_amount: number;

  @Index()
  @Column({ type: 'uuid', nullable: true })
  assigned_driver_id: string;

  @ManyToOne(() => User, (user) => user.orders_as_driver, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'assigned_driver_id' })
  assigned_driver: User;

  @Column({ type: 'timestamp with time zone', nullable: true })
  scheduled_delivery_date: Date;

  @Column({
    type: 'enum',
    enum: PostponementReason,
    nullable: true,
  })
  postponement_reason: PostponementReason;

  @Column({ type: 'text', nullable: true })
  postponement_notes: string;

  @Column({ type: 'text', nullable: true })
  waybill_qr_code: string; // QR code data payload for waybill scanning

  @Column({ type: 'timestamp with time zone', nullable: true })
  delivered_at: Date;

  @Column({ type: 'text', nullable: true })
  delivery_signature_url: string;

  @Column({ type: 'text', nullable: true })
  delivery_notes: string;

  @OneToMany(() => OrderItem, (item) => item.order, { cascade: true })
  items: OrderItem[];

  @OneToMany(() => OrderTrackingHistory, (history) => history.order)
  tracking_history: OrderTrackingHistory[];

  @OneToMany(() => DriverLedger, (ledger) => ledger.order)
  ledger_records: DriverLedger[];

  @OneToMany(() => PaymentTransaction, (payment) => payment.order)
  payment_transactions: PaymentTransaction[];

  @CreateDateColumn({ type: 'timestamp with time zone' })
  created_at: Date;

  @UpdateDateColumn({ type: 'timestamp with time zone' })
  updated_at: Date;
}
