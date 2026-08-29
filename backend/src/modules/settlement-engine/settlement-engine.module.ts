import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Order } from '../../database/entities/order.entity';
import { Merchant } from '../../database/entities/merchant.entity';
import { User } from '../../database/entities/user.entity';
import { WalletTransaction } from '../../database/entities/wallet-transaction.entity';
import { SettlementEngineService } from './settlement-engine.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([Order, Merchant, User, WalletTransaction]),
  ],
  providers: [SettlementEngineService],
  exports: [SettlementEngineService],
})
export class SettlementEngineModule {}
