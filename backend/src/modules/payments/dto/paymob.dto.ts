import { IsNotEmpty, IsUUID, IsEnum, IsString, IsOptional, IsObject } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { PaymentMethod } from '../../../common/enums/payment-method.enum';

export class InitiatePaymobPaymentDto {
  @ApiProperty({ example: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11' })
  @IsUUID()
  @IsNotEmpty()
  order_id: string;

  @ApiProperty({ enum: [PaymentMethod.PAYMOB_CARD, PaymentMethod.PAYMOB_WALLET, PaymentMethod.PAYMOB_MEEZA] })
  @IsEnum(PaymentMethod)
  @IsNotEmpty()
  payment_method: PaymentMethod;

  @ApiPropertyOptional({ example: '01012345678', description: 'Required if payment_method is PAYMOB_WALLET' })
  @IsOptional()
  @IsString()
  wallet_mobile_number?: string;
}

export class PaymobWebhookDto {
  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  type: string;

  @ApiProperty()
  @IsNotEmpty()
  @IsObject()
  obj: any;
}
