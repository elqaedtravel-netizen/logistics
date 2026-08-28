import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DriverLedger } from '../../database/entities/driver-ledger.entity';
import { User } from '../../database/entities/user.entity';
import { RecordSettlementPayoutDto, ManualAdjustmentDto } from './dto/ledger.dto';
import { LedgerTransactionType } from '../../common/enums/ledger-transaction-type.enum';
import { UserRole } from '../../common/enums/roles.enum';

@Injectable()
export class DriverLedgerService {
  constructor(
    @InjectRepository(DriverLedger)
    private ledgerRepository: Repository<DriverLedger>,
    @InjectRepository(User)
    private userRepository: Repository<User>,
  ) {}

  async getDriverBalance(driverId: string): Promise<{
    driver_id: string;
    driver_name: string;
    total_cash_collected: number;
    total_commission_earned: number;
    total_settled_payouts: number;
    current_cash_in_hand_to_handover: number;
    net_commission_receivable: number;
    running_balance: number;
  }> {
    const driver = await this.userRepository.findOne({ where: { id: driverId } });
    if (!driver || driver.role !== UserRole.DRIVER) {
      throw new NotFoundException('Driver not found');
    }

    const entries = await this.ledgerRepository.find({
      where: { driver_id: driverId },
      order: { created_at: 'ASC' },
    });

    let totalCashCollected = 0;
    let totalCommissionEarned = 0;
    let totalSettledPayouts = 0;

    for (const entry of entries) {
      const amt = Number(entry.amount);
      if (entry.transaction_type === LedgerTransactionType.CASH_COLLECTED) {
        totalCashCollected += amt;
      } else if (entry.transaction_type === LedgerTransactionType.COMMISSION_EARNED) {
        totalCommissionEarned += amt;
      } else if (entry.transaction_type === LedgerTransactionType.SETTLEMENT_PAYOUT) {
        totalSettledPayouts += amt;
      }
    }

    const lastEntry = entries[entries.length - 1];
    const runningBalance = lastEntry ? Number(lastEntry.running_balance) : 0;
    const remainingCashToHandover = Math.max(0, totalCashCollected - totalSettledPayouts);

    return {
      driver_id: driver.id,
      driver_name: driver.full_name,
      total_cash_collected: parseFloat(totalCashCollected.toFixed(2)),
      total_commission_earned: parseFloat(totalCommissionEarned.toFixed(2)),
      total_settled_payouts: parseFloat(totalSettledPayouts.toFixed(2)),
      current_cash_in_hand_to_handover: parseFloat(remainingCashToHandover.toFixed(2)),
      net_commission_receivable: parseFloat(totalCommissionEarned.toFixed(2)),
      running_balance: parseFloat(runningBalance.toFixed(2)),
    };
  }

  async getDriverStatement(driverId: string, limit = 50): Promise<DriverLedger[]> {
    return this.ledgerRepository.find({
      where: { driver_id: driverId },
      relations: ['order'],
      order: { created_at: 'DESC' },
      take: limit,
    });
  }

  async recordSettlementPayout(dto: RecordSettlementPayoutDto): Promise<DriverLedger> {
    const driver = await this.userRepository.findOne({ where: { id: dto.driver_id } });
    if (!driver || driver.role !== UserRole.DRIVER) {
      throw new NotFoundException('Driver not found');
    }

    const lastEntry = await this.ledgerRepository.findOne({
      where: { driver_id: dto.driver_id },
      order: { created_at: 'DESC' },
    });

    const currentBalance = lastEntry ? Number(lastEntry.running_balance) : 0;
    const newBalance = currentBalance - Number(dto.amount); // Cash handed over reduces driver balance

    const entry = this.ledgerRepository.create({
      driver_id: dto.driver_id,
      transaction_type: LedgerTransactionType.SETTLEMENT_PAYOUT,
      amount: dto.amount,
      running_balance: newBalance,
      description: dto.description,
      reference_code: dto.reference_code || `PAYOUT-${Date.now()}`,
    });

    return this.ledgerRepository.save(entry);
  }

  async recordAdjustment(dto: ManualAdjustmentDto): Promise<DriverLedger> {
    const driver = await this.userRepository.findOne({ where: { id: dto.driver_id } });
    if (!driver || driver.role !== UserRole.DRIVER) {
      throw new NotFoundException('Driver not found');
    }

    const lastEntry = await this.ledgerRepository.findOne({
      where: { driver_id: dto.driver_id },
      order: { created_at: 'DESC' },
    });

    const currentBalance = lastEntry ? Number(lastEntry.running_balance) : 0;
    const newBalance = currentBalance + Number(dto.amount);

    const entry = this.ledgerRepository.create({
      driver_id: dto.driver_id,
      transaction_type: LedgerTransactionType.ADJUSTMENT,
      amount: dto.amount,
      running_balance: newBalance,
      description: dto.description,
      reference_code: dto.reference_code || `ADJ-${Date.now()}`,
    });

    return this.ledgerRepository.save(entry);
  }

  async getAllDriversSummary(): Promise<any[]> {
    const drivers = await this.userRepository.find({
      where: { role: UserRole.DRIVER, is_active: true },
    });

    const summaries = [];
    for (const driver of drivers) {
      const balance = await this.getDriverBalance(driver.id);
      summaries.push(balance);
    }

    return summaries;
  }
}
