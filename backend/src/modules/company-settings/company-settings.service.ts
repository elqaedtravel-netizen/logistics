import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CompanyPaymentSetting } from '../../database/entities/company-payment-setting.entity';

@Injectable()
export class CompanySettingsService {
  constructor(
    @InjectRepository(CompanyPaymentSetting)
    private readonly settingsRepo: Repository<CompanyPaymentSetting>,
  ) {}

  async getPublicSettings(): Promise<CompanyPaymentSetting> {
    let settings = await this.settingsRepo.findOne({
      where: { is_active: true },
      order: { created_at: 'DESC' },
    });

    if (!settings) {
      // Create initial default company settings if none exists
      settings = this.settingsRepo.create({
        company_name: 'شركة أنتيجرافيتي إكسبريس للخدمات اللوجستية والشحن (مصر)',
        instapay_address: 'antigravity.logistics@instapay',
        vodafone_cash_number: '01012345678',
        orange_cash_number: '01212345678',
        etisalat_cash_number: '01112345678',
        we_pay_number: '01512345678',
        bank_name: 'البنك التجاري الدولي (CIB مصر)',
        bank_account_holder: 'شركة أنتيجرافيتي إكسبريس ش.م.م',
        bank_account_number: '100045892019',
        bank_iban: 'EG380010004589201900000000000',
        bank_swift_code: 'CIBEEGCX',
        is_active: true,
      });
      await this.settingsRepo.save(settings);
    }

    return settings;
  }

  async updateSettings(
    dto: Partial<CompanyPaymentSetting>,
    adminId?: string,
  ): Promise<CompanyPaymentSetting> {
    let settings = await this.settingsRepo.findOne({
      where: { is_active: true },
      order: { created_at: 'DESC' },
    });

    if (!settings) {
      settings = this.settingsRepo.create({ ...dto, updated_by_admin_id: adminId });
    } else {
      Object.assign(settings, dto);
      if (adminId) settings.updated_by_admin_id = adminId;
    }

    return this.settingsRepo.save(settings);
  }
}
