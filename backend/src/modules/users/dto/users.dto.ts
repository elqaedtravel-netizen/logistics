import { IsEmail, IsNotEmpty, MinLength, IsOptional, IsEnum, IsString, IsNumber, IsBoolean } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { UserRole } from '../../../common/enums/roles.enum';

export class CreateUserDto {
  @ApiProperty({ example: 'driver2@antigravity.io' })
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @ApiProperty({ example: 'SecurePassword2026!' })
  @IsNotEmpty()
  @MinLength(6)
  password: string;

  @ApiProperty({ example: 'Mahmoud Hassan' })
  @IsString()
  @IsNotEmpty()
  full_name: string;

  @ApiPropertyOptional({ example: '+201099887766' })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiProperty({ enum: UserRole, default: UserRole.DRIVER })
  @IsEnum(UserRole)
  role: UserRole;

  @ApiPropertyOptional({ example: 10.0, description: 'Commission rate in percentage for drivers' })
  @IsOptional()
  @IsNumber()
  commission_rate?: number;
}

export class UpdateUserDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  full_name?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({ enum: UserRole })
  @IsOptional()
  @IsEnum(UserRole)
  role?: UserRole;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  is_active?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  commission_rate?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  fcm_token?: string;
}
