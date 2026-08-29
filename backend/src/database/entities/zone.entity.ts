import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('zones')
export class Zone {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true, nullable: false })
  zone_code: string; // e.g. 'CAI-MAADI', 'CAI-NASRCITY', 'GZA-DOKKI'

  @Column({ nullable: false })
  zone_name_ar: string; // 'المعادي وطرة', 'مدينة نصر ومصر الجديدة'

  @Column({ nullable: false })
  governorate: string; // 'القاهرة', 'الجيزة'

  @Column({ nullable: false })
  city: string;

  @Column({ nullable: true })
  hub_id: string;

  @Column({ type: 'decimal', precision: 6, scale: 2, default: 50.0 })
  standard_shipping_fee_egp: number;

  @Column({ type: 'int', default: 24 })
  estimated_delivery_hours: number;

  @Column({ default: true })
  is_active: boolean;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}
