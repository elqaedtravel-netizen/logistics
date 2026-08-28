import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { Order } from './order.entity';
import { PaymentMethod, PaymentStatus } from '../../common/enums/payment-method.enum';

@Entity('payment_transactions')
export class PaymentTransaction {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ type: 'uuid' })
  order_id: string;

  @ManyToOne(() => Order, (order) => order.payment_transactions, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'order_id' })
  order: Order;

  @Index()
  @Column({ type: 'varchar', length: 100, nullable: true })
  paymob_order_id: string;

  @Index({ unique: true, where: 'paymob_transaction_id IS NOT NULL' })
  @Column({ type: 'varchar', length: 100, nullable: true, unique: true })
  paymob_transaction_id: string;

  @Column({ type: 'bigint' })
  amount_cents: number;

  @Column({ type: 'varchar', length: 10, default: 'EGP' })
  currency: string;

  @Column({
    type: 'enum',
    enum: PaymentMethod,
  })
  payment_method: PaymentMethod;

  @Column({
    type: 'enum',
    enum: PaymentStatus,
    default: PaymentStatus.PENDING,
  })
  status: PaymentStatus;

  @Column({ type: 'boolean', default: false })
  hmac_validated: boolean;

  @Column({ type: 'jsonb', nullable: true })
  raw_payload: any;

  @Column({ type: 'text', nullable: true })
  failure_reason: string;

  @CreateDateColumn({ type: 'timestamp with time zone' })
  created_at: Date;
}
