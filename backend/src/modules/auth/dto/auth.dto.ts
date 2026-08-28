import { IsEmail, IsNotEmpty, MinLength, IsOptional, IsEnum, IsString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { UserRole } from '../../../common/enums/roles.enum';

export class LoginDto {
  @ApiProperty({ example: 'admin@antigravity.io' })
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @ApiProperty({ example: 'AdminPassword2026!' })
  @IsNotEmpty()
  @MinLength(6)
  password: string;
}

export class RegisterDto {
  @ApiProperty({ example: 'customer@antigravity.io' })
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @ApiProperty({ example: 'SecurePassword2026!' })
  @IsNotEmpty()
  @MinLength(6)
  password: string;

  @ApiProperty({ example: 'Sara Ibrahim' })
  @IsString()
  @IsNotEmpty()
  full_name: string;

  @ApiPropertyOptional({ example: '+201098765432' })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({ enum: UserRole, default: UserRole.CUSTOMER })
  @IsOptional()
  @IsEnum(UserRole)
  role?: UserRole;
}

export class FirebaseLoginDto {
  @ApiProperty({ description: 'Firebase ID Token obtained from Google Sign-In' })
  @IsNotEmpty()
  @IsString()
  id_token: string;

  @ApiPropertyOptional({ description: 'Optional user full name' })
  @IsOptional()
  @IsString()
  full_name?: string;

  @ApiPropertyOptional({ description: 'Optional FCM token for push notifications' })
  @IsOptional()
  @IsString()
  fcm_token?: string;
}
