import { Controller, Get, Post, Body, Param, UseGuards, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { DriverLedgerService } from './driver-ledger.service';
import { RecordSettlementPayoutDto, ManualAdjustmentDto } from './dto/ledger.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { UserRole } from '../../common/enums/roles.enum';
import { User } from '../../database/entities/user.entity';

@ApiTags('Driver Financials & Ledger')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('driver-ledger')
export class DriverLedgerController {
  constructor(private readonly ledgerService: DriverLedgerService) {}

  @Get('my-balance')
  @Roles(UserRole.DRIVER)
  @ApiOperation({ summary: 'Driver views their own real-time collected cash, commissions, and running balance' })
  async getMyBalance(@CurrentUser() driver: User) {
    return this.ledgerService.getDriverBalance(driver.id);
  }

  @Get('my-statement')
  @Roles(UserRole.DRIVER)
  @ApiOperation({ summary: 'Driver views their own itemized financial transaction history' })
  async getMyStatement(@CurrentUser() driver: User, @Query('limit') limit?: number) {
    return this.ledgerService.getDriverStatement(driver.id, limit ? Number(limit) : 50);
  }

  @Get('summary')
  @Roles(UserRole.ADMIN, UserRole.DISPATCHER)
  @ApiOperation({ summary: 'Admin overview of all drivers cash collected vs outstanding balance' })
  async getAllDriversSummary() {
    return this.ledgerService.getAllDriversSummary();
  }

  @Get(':driverId/balance')
  @Roles(UserRole.ADMIN, UserRole.DISPATCHER)
  @ApiOperation({ summary: 'Admin views balance for specific driver' })
  async getDriverBalance(@Param('driverId') driverId: string) {
    return this.ledgerService.getDriverBalance(driverId);
  }

  @Get(':driverId/statement')
  @Roles(UserRole.ADMIN, UserRole.DISPATCHER)
  @ApiOperation({ summary: 'Admin views full ledger statement for specific driver' })
  async getDriverStatement(@Param('driverId') driverId: string, @Query('limit') limit?: number) {
    return this.ledgerService.getDriverStatement(driverId, limit ? Number(limit) : 50);
  }

  @Post('settlement-payout')
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Admin accepts cash handover from driver and records settlement' })
  async recordSettlementPayout(@Body() dto: RecordSettlementPayoutDto) {
    return this.ledgerService.recordSettlementPayout(dto);
  }

  @Post('adjustment')
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Admin applies a manual financial debit/credit adjustment' })
  async recordAdjustment(@Body() dto: ManualAdjustmentDto) {
    return this.ledgerService.recordAdjustment(dto);
  }
}
