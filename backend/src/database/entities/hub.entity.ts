import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('hubs')
export class Hub {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true, nullable: false })
  hub_code: string; // e.g. 'HUB-CAI-CENTRAL', 'HUB-GZA-WEST', 'HUB-ALX-MAIN'

  @Column({ nullable: false })
  hub_name: string; // 'مخزن وتوزيع القاهرة المركزي'

  @Column({ nullable: false })
  governorate: string;

  @Column({ nullable: false })
  address: string;

  @Column({ nullable: true })
  manager_id: string;

  @Column({ default: true })
  is_active: boolean;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}
