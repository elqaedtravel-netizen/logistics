import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { OrdersService } from './orders.service';
import { OrdersController } from './orders.controller';
import { OrderStateMachineService } from './state-machine.service';
import { WaybillService } from './waybill.service';
import { Order } from '../../database/entities/order.entity';
import { OrderItem } from '../../database/entities/order-item.entity';
import { OrderTrackingHistory } from '../../database/entities/order-tracking-history.entity';
import { User } from '../../database/entities/user.entity';
import { DriverLedger } from '../../database/entities/driver-ledger.entity';
import { ProductsModule } from '../products/products.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Order, OrderItem, OrderTrackingHistory, User, DriverLedger]),
    ProductsModule,
  ],
  controllers: [OrdersController],
  providers: [OrdersService, OrderStateMachineService, WaybillService],
  exports: [OrdersService, OrderStateMachineService, WaybillService],
})
export class OrdersModule {}
