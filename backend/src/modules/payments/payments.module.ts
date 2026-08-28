import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { PaymobService } from './paymob.service';
import { PaymentsController } from './payments.controller';
import { Order } from '../../database/entities/order.entity';
import { PaymentTransaction } from '../../database/entities/payment-transaction.entity';
import { OrderTrackingHistory } from '../../database/entities/order-tracking-history.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Order, PaymentTransaction, OrderTrackingHistory]),
    ConfigModule,
  ],
  controllers: [PaymentsController],
  providers: [PaymobService],
  exports: [PaymobService],
})
export class PaymentsModule {}
