import { Controller, Post, Body, Headers, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { PaymobService } from './paymob.service';
import { InitiatePaymobPaymentDto, PaymobWebhookDto } from './dto/paymob.dto';
import { Public } from '../../common/decorators/public.decorator';

@ApiTags('Egyptian Payment Gateway (Paymob)')
@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymobService: PaymobService) {}

  @Public()
  @Post('initiate')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Initiate Paymob payment for Card, Meeza, or Egyptian Mobile Wallet' })
  async initiatePayment(@Body() dto: InitiatePaymobPaymentDto) {
    return this.paymobService.initiatePayment(dto);
  }

  @Public()
  @Post('paymob-webhook')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Paymob Webhook transaction callback listener with HMAC-SHA512 verification' })
  async handleWebhook(
    @Body() payload: PaymobWebhookDto,
    @Headers('hmac') hmac?: string,
  ) {
    return this.paymobService.processWebhookCallback(payload, hmac);
  }
}
