import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { OrderStatus } from '../../common/enums/order-status.enum';
import { Order } from './order.entity';
import { User } from './user.entity';

@Entity('order_tracking_history')
export class OrderTrackingHistory {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ type: 'uuid' })
  order_id: string;

  @ManyToOne(() => Order, (order) => order.tracking_history, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'order_id' })
  order: Order;

  @Column({
    type: 'enum',
    enum: OrderStatus,
    nullable: true,
  })
  previous_status: OrderStatus;

  @Column({
    type: 'enum',
    enum: OrderStatus,
  })
  new_status: OrderStatus;

  @Column({ type: 'uuid', nullable: true })
  changed_by_user_id: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'changed_by_user_id' })
  changed_by_user: User;

  @Column({ type: 'uuid', nullable: true })
  driver_id: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'driver_id' })
  driver: User;

  @Column({ type: 'text', nullable: true })
  notes: string;

  @Column({ type: 'varchar', length: 100, nullable: true })
  reason_code: string;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  location_lat: number;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  location_lng: number;

  @CreateDateColumn({ type: 'timestamp with time zone' })
  created_at: Date;
}
