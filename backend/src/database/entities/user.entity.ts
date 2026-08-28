import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
  Index,
} from 'typeorm';
import { UserRole } from '../../common/enums/roles.enum';
import { Order } from './order.entity';
import { DriverLedger } from './driver-ledger.entity';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index({ unique: true })
  @Column({ type: 'varchar', length: 255, unique: true })
  email: string;

  @Column({ type: 'varchar', length: 255, nullable: true })
  password_hash: string;

  @Index({ unique: true, where: 'firebase_uid IS NOT NULL' })
  @Column({ type: 'varchar', length: 255, nullable: true, unique: true })
  firebase_uid: string;

  @Column({ type: 'varchar', length: 255 })
  full_name: string;

  @Column({ type: 'varchar', length: 50, nullable: true })
  phone: string;

  @Column({
    type: 'enum',
    enum: UserRole,
    default: UserRole.CUSTOMER,
  })
  role: UserRole;

  @Column({ type: 'boolean', default: true })
  is_active: boolean;

  @Column({ type: 'decimal', precision: 5, scale: 2, default: 10.0 })
  commission_rate: number; // Commission percentage for drivers

  @Column({ type: 'text', nullable: true })
  fcm_token: string;

  @OneToMany(() => Order, (order) => order.customer)
  orders_as_customer: Order[];

  @OneToMany(() => Order, (order) => order.assigned_driver)
  orders_as_driver: Order[];

  @OneToMany(() => DriverLedger, (ledger) => ledger.driver)
  ledger_entries: DriverLedger[];

  @CreateDateColumn({ type: 'timestamp with time zone' })
  created_at: Date;

  @UpdateDateColumn({ type: 'timestamp with time zone' })
  updated_at: Date;
}
