import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DriverLedgerService } from './driver-ledger.service';
import { DriverLedgerController } from './driver-ledger.controller';
import { DriverLedger } from '../../database/entities/driver-ledger.entity';
import { User } from '../../database/entities/user.entity';

@Module({
  imports: [TypeOrmModule.forFeature([DriverLedger, User])],
  controllers: [DriverLedgerController],
  providers: [DriverLedgerService],
  exports: [DriverLedgerService],
})
export class DriverLedgerModule {}
