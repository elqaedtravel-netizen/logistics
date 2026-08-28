import {
  IsNotEmpty,
  IsString,
  IsNumber,
  IsOptional,
  IsEnum,
  IsArray,
  ValidateNested,
  Min,
  IsUUID,
  IsDateString,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { OrderStatus } from '../../../common/enums/order-status.enum';
import { PaymentMethod } from '../../../common/enums/payment-method.enum';
import { PostponementReason } from '../../../common/enums/postponement-reason.enum';

export class OrderItemDto {
  @ApiProperty({ example: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11' })
  @IsUUID()
  @IsNotEmpty()
  product_id: string;

  @ApiProperty({ example: 2 })
  @IsNumber()
  @Min(1)
  quantity: number;
}

export class CreateOrderDto {
  @ApiProperty({ example: 'Sara Ibrahim' })
  @IsString()
  @IsNotEmpty()
  customer_name: string;

  @ApiProperty({ example: '+201098765432' })
  @IsString()
  @IsNotEmpty()
  customer_phone: string;

  @ApiProperty({ example: '15 El-Tahrir Square, Downtown, Cairo' })
  @IsString()
  @IsNotEmpty()
  shipping_address: string;

  @ApiPropertyOptional({ example: 'Cairo' })
  @IsOptional()
  @IsString()
  city?: string;

  @ApiPropertyOptional({ example: 30.0444 })
  @IsOptional()
  @IsNumber()
  geo_lat?: number;

  @ApiPropertyOptional({ example: 31.2357 })
  @IsOptional()
  @IsNumber()
  geo_lng?: number;

  @ApiProperty({ enum: PaymentMethod, default: PaymentMethod.CASH_ON_DELIVERY })
  @IsEnum(PaymentMethod)
  payment_method: PaymentMethod;

  @ApiProperty({ type: [OrderItemDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OrderItemDto)
  items: OrderItemDto[];
}

export class UpdateOrderStatusDto {
  @ApiProperty({ enum: OrderStatus })
  @IsEnum(OrderStatus)
  status: OrderStatus;

  @ApiPropertyOptional({ example: 'Scanned waybill and verified package contents.' })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiPropertyOptional({ example: 30.0444 })
  @IsOptional()
  @IsNumber()
  location_lat?: number;

  @ApiPropertyOptional({ example: 31.2357 })
  @IsOptional()
  @IsNumber()
  location_lng?: number;
}

export class AssignDriverDto {
  @ApiProperty({ example: 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380b22' })
  @IsUUID()
  @IsNotEmpty()
  driver_id: string;

  @ApiPropertyOptional({ example: '2026-08-30T10:00:00Z' })
  @IsOptional()
  @IsDateString()
  scheduled_delivery_date?: string;
}

export class PostponeOrderDto {
  @ApiProperty({ enum: PostponementReason, example: PostponementReason.CUSTOMER_REQUESTED_RESCHEDULE })
  @IsEnum(PostponementReason)
  @IsNotEmpty()
  reason: PostponementReason;

  @ApiPropertyOptional({ example: 'Customer asked to deliver tomorrow between 2 PM and 5 PM.' })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiPropertyOptional({ example: '2026-08-31T14:00:00Z' })
  @IsOptional()
  @IsDateString()
  new_delivery_date?: string;
}

export class DeliverOrderDto {
  @ApiPropertyOptional({ example: 'Package received by customer Sara Ibrahim' })
  @IsOptional()
  @IsString()
  delivery_notes?: string;

  @ApiPropertyOptional({ example: 'https://storage.antigravity.io/signatures/ord-12345.png' })
  @IsOptional()
  @IsString()
  signature_url?: string;

  @ApiPropertyOptional({ example: 30.0444 })
  @IsOptional()
  @IsNumber()
  location_lat?: number;

  @ApiPropertyOptional({ example: 31.2357 })
  @IsOptional()
  @IsNumber()
  location_lng?: number;
}

export class QueryOrdersDto {
  @ApiPropertyOptional({ enum: OrderStatus })
  @IsOptional()
  @IsEnum(OrderStatus)
  status?: OrderStatus;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  driver_id?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  date_from?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  date_to?: string;
}
