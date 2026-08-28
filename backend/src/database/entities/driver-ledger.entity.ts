import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { LedgerTransactionType } from '../../common/enums/ledger-transaction-type.enum';
import { User } from './user.entity';
import { Order } from './order.entity';

@Entity('driver_ledgers')
export class DriverLedger {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ type: 'uuid' })
  driver_id: string;

  @ManyToOne(() => User, (user) => user.ledger_entries, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'driver_id' })
  driver: User;

  @Index()
  @Column({ type: 'uuid', nullable: true })
  order_id: string;

  @ManyToOne(() => Order, (order) => order.ledger_records, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'order_id' })
  order: Order;

  @Column({
    type: 'enum',
    enum: LedgerTransactionType,
  })
  transaction_type: LedgerTransactionType;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  amount: number; // Positive for cash collected or commission earned, negative for settlement payouts

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  running_balance: number; // Driver's net cash owed to company

  @Column({ type: 'text' })
  description: string;

  @Index()
  @Column({ type: 'varchar', length: 100, nullable: true })
  reference_code: string;

  @CreateDateColumn({ type: 'timestamp with time zone' })
  created_at: Date;
}
