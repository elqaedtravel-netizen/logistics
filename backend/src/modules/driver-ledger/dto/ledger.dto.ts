import { IsNotEmpty, IsNumber, IsString, IsOptional, IsUUID, Min } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class RecordSettlementPayoutDto {
  @ApiProperty({ example: 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380b22' })
  @IsUUID()
  @IsNotEmpty()
  driver_id: string;

  @ApiProperty({ example: 4500.0, description: 'Amount of collected cash handed over to company' })
  @IsNumber()
  @Min(0.01)
  amount: number;

  @ApiProperty({ example: 'Handover of Cairo Downtown route cash collection' })
  @IsString()
  @IsNotEmpty()
  description: string;

  @ApiPropertyOptional({ example: 'RCPT-2026-0829-01' })
  @IsOptional()
  @IsString()
  reference_code?: string;
}

export class ManualAdjustmentDto {
  @ApiProperty({ example: 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380b22' })
  @IsUUID()
  @IsNotEmpty()
  driver_id: string;

  @ApiProperty({ example: 50.0, description: 'Positive or negative adjustment' })
  @IsNumber()
  amount: number;

  @ApiProperty({ example: 'Fuel allowance compensation' })
  @IsString()
  @IsNotEmpty()
  description: string;

  @ApiPropertyOptional({ example: 'ADJ-FUEL-01' })
  @IsOptional()
  @IsString()
  reference_code?: string;
}
