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

export enum UserRole {
  SUPER_ADMIN = 'SuperAdmin',
  HUB_MANAGER = 'HubManager',
  FINANCE_ADMIN = 'FinanceAdmin',
  OPERATIONS_ADMIN = 'OperationsAdmin',
  MERCHANT_ADMIN = 'MerchantAdmin',
  DRIVER = 'Driver',
  CUSTOMER = 'Customer',
}

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true, nullable: false })
  email: string;

  @Column({ nullable: false })
  password_hash: string;

  @Column({ nullable: false })
  full_name: string;

  @Column({ nullable: true })
  phone: string;

  @Column({
    type: 'enum',
    enum: UserRole,
    default: UserRole.CUSTOMER,
  })
  role: UserRole;

  @Column('simple-array', { nullable: true, default: '' })
  permissions: string[]; // e.g. ['orders.create', 'orders.dispatch', 'finance.settle', 'inventory.manage', 'users.manage', 'settings.edit']

  @Column({ default: true })
  is_active: boolean;

  @Column({ nullable: true })
  hub_id: string;

  // Driver-Specific Fields
  @Column({ nullable: true })
  national_id: string;

  @Column({ nullable: true })
  driving_license_number: string;

  @Column({ nullable: true, default: 'موتوسيكل' })
  vehicle_type: string; // موتوسيكل, سيارة, فان, تروسيكل

  @Column({ type: 'decimal', precision: 5, scale: 2, default: 10.0 })
  commission_percentage: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0.0 })
  current_cash_in_hand: number;

  @Column({ nullable: true })
  assigned_zone_id: string;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}
