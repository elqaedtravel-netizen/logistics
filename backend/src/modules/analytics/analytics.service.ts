import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Order } from '../../database/entities/order.entity';
import { User } from '../../database/entities/user.entity';
import { Product } from '../../database/entities/product.entity';
import { DriverLedger } from '../../database/entities/driver-ledger.entity';
import { OrderStatus } from '../../common/enums/order-status.enum';
import { UserRole } from '../../common/enums/roles.enum';
import { PaymentStatus } from '../../common/enums/payment-method.enum';
import { LedgerTransactionType } from '../../common/enums/ledger-transaction-type.enum';

@Injectable()
export class AnalyticsService {
  constructor(
    @InjectRepository(Order)
    private orderRepository: Repository<Order>,
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(Product)
    private productRepository: Repository<Product>,
    @InjectRepository(DriverLedger)
    private ledgerRepository: Repository<DriverLedger>,
  ) {}

  async getAdminDashboardMetrics() {
    // 1. Order Status Counts
    const orders = await this.orderRepository.find();
    const totalOrders = orders.length;

    const statusBreakdown: Record<string, number> = {
      [OrderStatus.Pending]: 0,
      [OrderStatus.In_Warehouse]: 0,
      [OrderStatus.Dispatched_to_Driver]: 0,
      [OrderStatus.Delivered]: 0,
      [OrderStatus.Postponed]: 0,
      [OrderStatus.Canceled]: 0,
      [OrderStatus.Returned]: 0,
    };

    let totalRevenue = 0;
    let pendingCodToCollect = 0;

    for (const ord of orders) {
      if (statusBreakdown[ord.status] !== undefined) {
        statusBreakdown[ord.status]++;
      }
      if (ord.payment_status === PaymentStatus.PAID) {
        totalRevenue += Number(ord.total_amount);
      } else if (ord.status === OrderStatus.Dispatched_to_Driver) {
        pendingCodToCollect += Number(ord.total_amount);
      }
    }

    // 2. Driver Metrics
    const drivers = await this.userRepository.find({ where: { role: UserRole.DRIVER, is_active: true } });
    const activeDriversCount = drivers.length;

    // 3. Low Stock Inventory Count
    const lowStockCount = await this.productRepository
      .createQueryBuilder('p')
      .where('p.stock_quantity <= 5')
      .andWhere('p.is_active = true')
      .getCount();

    // 4. Postponement Reasons Breakdown
    const postponedOrders = orders.filter((o) => o.status === OrderStatus.Postponed && o.postponement_reason);
    const postponementReasons: Record<string, number> = {};
    for (const ord of postponedOrders) {
      const reason = ord.postponement_reason;
      postponementReasons[reason] = (postponementReasons[reason] || 0) + 1;
    }

    // 5. Total Driver Outstanding Cash in Hand
    const ledgerEntries = await this.ledgerRepository.find();
    let totalCashCollectedByDrivers = 0;
    let totalSettledPayouts = 0;

    for (const entry of ledgerEntries) {
      if (entry.transaction_type === LedgerTransactionType.CASH_COLLECTED) {
        totalCashCollectedByDrivers += Number(entry.amount);
      } else if (entry.transaction_type === LedgerTransactionType.SETTLEMENT_PAYOUT) {
        totalSettledPayouts += Number(entry.amount);
      }
    }
    const currentUnsettledDriverCash = Math.max(0, totalCashCollectedByDrivers - totalSettledPayouts);

    // 6. Recent 10 Orders
    const recentOrders = await this.orderRepository.find({
      order: { created_at: 'DESC' },
      take: 10,
      relations: ['customer', 'assigned_driver'],
    });

    return {
      kpis: {
        total_revenue_egp: parseFloat(totalRevenue.toFixed(2)),
        total_orders_count: totalOrders,
        active_drivers_count: activeDriversCount,
        pending_cod_in_route_egp: parseFloat(pendingCodToCollect.toFixed(2)),
        unsettled_driver_cash_egp: parseFloat(currentUnsettledDriverCash.toFixed(2)),
        low_stock_alerts_count: lowStockCount,
      },
      status_breakdown: statusBreakdown,
      postponement_analysis: postponementReasons,
      recent_orders: recentOrders.map((o) => ({
        id: o.id,
        order_number: o.order_number,
        customer_name: o.customer_name,
        total_amount: o.total_amount,
        status: o.status,
        payment_method: o.payment_method,
        payment_status: o.payment_status,
        driver_name: o.assigned_driver ? o.assigned_driver.full_name : null,
        created_at: o.created_at,
      })),
    };
  }
}
