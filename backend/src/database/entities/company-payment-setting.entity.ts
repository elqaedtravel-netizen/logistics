import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('company_payment_settings')
export class CompanyPaymentSetting {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ default: 'شركة أنتيجرافيتي إكسبريس للخدمات اللوجستية والشحن' })
  company_name: string;

  // InstaPay Details (عنوان وتطبيق إنستاباي الرسمي للشركة)
  @Column({ nullable: true, default: 'antigravity.logistics@instapay' })
  instapay_address: string;

  @Column({ nullable: true })
  instapay_qr_image_url: string;

  // Mobile Wallets (أرقام محافظ فودافون كاش، أورنج، اتصالات، وي الرسمية)
  @Column({ nullable: true, default: '01000000001' })
  vodafone_cash_number: string;

  @Column({ nullable: true, default: '01200000002' })
  orange_cash_number: string;

  @Column({ nullable: true, default: '01100000003' })
  etisalat_cash_number: string;

  @Column({ nullable: true, default: '01500000004' })
  we_pay_number: string;

  // Official Bank Details (الحساب البنكي والآيبان)
  @Column({ nullable: true, default: 'البنك التجاري الدولي (CIB مصر)' })
  bank_name: string;

  @Column({ nullable: true, default: 'شركة أنتيجرافيتي إكسبريس ش.م.م' })
  bank_account_holder: string;

  @Column({ nullable: true, default: '100045892019' })
  bank_account_number: string;

  @Column({ nullable: true, default: 'EG380010004589201900000000000' })
  bank_iban: string;

  @Column({ nullable: true, default: 'CIBEEGCX' })
  bank_swift_code: string;

  @Column({ default: true })
  is_active: boolean;

  @Column({ nullable: true })
  updated_by_admin_id: string;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}
