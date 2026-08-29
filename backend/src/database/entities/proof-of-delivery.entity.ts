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

@Entity('proof_of_deliveries')
export class ProofOfDelivery {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ nullable: false })
  order_id: string;

  @ManyToOne(() => Order, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'order_id' })
  order: Order;

  @Column({ nullable: false })
  driver_id: string;

  @ManyToOne(() => User, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'driver_id' })
  driver: User;

  @Column({ nullable: false })
  recipient_name: string;

  @Column({ nullable: true })
  recipient_national_id: string;

  @Column({ nullable: true, default: 'المستلم شخصياً' })
  recipient_relation: string; // 'المستلم شخصياً', 'أحد أفراد الأسرة', 'حارس العقار', 'زميل عمل'

  @Column({ nullable: true })
  photo_pod_url: string;

  @Column({ type: 'text', nullable: true })
  signature_svg_data: string;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  gps_latitude: number;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  gps_longitude: number;

  @Column({ nullable: true })
  notes: string;

  @CreateDateColumn()
  created_at: Date;
}
