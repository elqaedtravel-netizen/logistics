import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
  Index,
} from 'typeorm';
import { OrderItem } from './order-item.entity';

@Entity('products')
export class Product {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index({ unique: true })
  @Column({ type: 'varchar', length: 100, unique: true })
  sku: string;

  @Column({ type: 'varchar', length: 255 })
  name: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  price: number; // Selling price (EGP)

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  cost_price: number; // Cost price (EGP)

  @Column({ type: 'int', default: 0 })
  stock_quantity: number;

  @Column({ type: 'varchar', length: 100, default: 'Warehouse-Cairo-Main' })
  warehouse_location: string;

  @Column({ type: 'text', nullable: true })
  barcode_qr_data: string;

  @Column({ type: 'text', nullable: true })
  image_url: string;

  @Column({ type: 'varchar', length: 100, default: 'General' })
  category: string;

  @Column({ type: 'boolean', default: true })
  is_active: boolean;

  @OneToMany(() => OrderItem, (item) => item.product)
  order_items: OrderItem[];

  @CreateDateColumn({ type: 'timestamp with time zone' })
  created_at: Date;

  @UpdateDateColumn({ type: 'timestamp with time zone' })
  updated_at: Date;
}
