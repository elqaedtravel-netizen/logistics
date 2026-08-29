import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Order } from './order.entity';
import { User } from './user.entity';

export enum RtoStatus {
  INITIATED_BY_DRIVER = 'Initiated_By_Driver',
  RECEIVED_AT_HUB = 'Received_At_Hub',
  RETURNED_TO_MERCHANT = 'Returned_To_Merchant',
}

@Entity('rto_logs')
export class ReturnToOriginLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ nullable: false })
  order_id: string;

  @ManyToOne(() => Order, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'order_id' })
  order: Order;

  @Column({ nullable: true })
  driver_id: string;

  @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'driver_id' })
  driver: User;

  @Column({ nullable: true })
  hub_id: string;

  @Column({ nullable: true })
  merchant_id: string;

  @Column({
    type: 'enum',
    enum: RtoStatus,
    default: RtoStatus.INITIATED_BY_DRIVER,
  })
  rto_status: RtoStatus;

  @Column({ nullable: false })
  reason_code: string; // 'CUSTOMER_REJECTED', 'WRONG_ADDRESS', 'DAMAGED_PACKAGE', 'FAILED_3_ATTEMPTS'

  @Column({ nullable: true })
  reason_description: string;

  @Column({ type: 'decimal', precision: 6, scale: 2, default: 25.0 })
  return_shipping_fee: number;

  @Column({ type: 'timestamp', nullable: true })
  received_at_hub_at: Date;

  @Column({ type: 'timestamp', nullable: true })
  returned_to_merchant_at: Date;

  @CreateDateColumn()
  created_at: Date;
}
