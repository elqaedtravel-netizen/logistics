import { Controller, Get, Put, Body, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { CompanySettingsService } from './company-settings.service';
import { CompanyPaymentSetting } from '../../database/entities/company-payment-setting.entity';

@ApiTags('Company Payment Settings (بيانات الدفع الرسمية للشركة)')
@Controller('company-settings')
export class CompanySettingsController {
  constructor(private readonly settingsService: CompanySettingsService) {}

  @Get('public')
  @ApiOperation({
    summary:
      'الحصول على بيانات الدفع البنكية والرسمية للشركة (تظهر للعملاء والمناديب إلزامياً)',
  })
  @ApiResponse({
    status: 200,
    description:
      'عنوان إنستاباي، أرقام المحافظ الإلكترونية، وبيانات الحساب البنكي الرسمي',
  })
  async getPublicSettings(): Promise<CompanyPaymentSetting> {
    return this.settingsService.getPublicSettings();
  }

  @Put('admin-update')
  @ApiOperation({
    summary: 'تعديل بيانات الدفع والحسابات البنكية الخاصة بالشركة (للمدير العام)',
  })
  async updateSettings(
    @Body() dto: Partial<CompanyPaymentSetting>,
    @Req() req: any,
  ): Promise<CompanyPaymentSetting> {
    const adminId = req?.user?.id;
    return this.settingsService.updateSettings(dto, adminId);
  }
}
