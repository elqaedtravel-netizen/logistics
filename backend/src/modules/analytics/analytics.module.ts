import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AnalyticsService } from './analytics.service';
import { AnalyticsController } from './analytics.controller';
import { Order } from '../../database/entities/order.entity';
import { User } from '../../database/entities/user.entity';
import { Product } from '../../database/entities/product.entity';
import { DriverLedger } from '../../database/entities/driver-ledger.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Order, User, Product, DriverLedger])],
  controllers: [AnalyticsController],
  providers: [AnalyticsService],
  exports: [AnalyticsService],
})
export class AnalyticsModule {}
