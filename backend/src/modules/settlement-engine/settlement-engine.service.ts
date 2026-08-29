import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { Order, OrderStatus } from '../../database/entities/order.entity';
import { Merchant } from '../../database/entities/merchant.entity';
import { User } from '../../database/entities/user.entity';
import {
  WalletTransaction,
  EntityType,
  WalletTransactionType,
} from '../../database/entities/wallet-transaction.entity';

@Injectable()
export class SettlementEngineService {
  private readonly logger = new Logger(SettlementEngineService.name);

  constructor(
    private readonly dataSource: DataSource,
    @InjectRepository(Order)
    private readonly orderRepo: Repository<Order>,
    @InjectRepository(Merchant)
    private readonly merchantRepo: Repository<Merchant>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    @InjectRepository(WalletTransaction)
    private readonly walletTxRepo: Repository<WalletTransaction>,
  ) {}

  /**
   * Automated settlement executed when order reaches DELIVERED or PARTIALLY_DELIVERED
   */
  async processOrderSettlement(
    orderId: string,
    collectedAmount: number,
    isPartialDelivery = false,
  ): Promise<{
    driverCommission: number;
    merchantNetPayout: number;
    shippingFee: number;
  }> {
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      const order = await queryRunner.manager.findOne(Order, {
        where: { id: orderId },
        relations: ['merchant', 'assigned_driver'],
      });

      if (!order) {
        throw new Error(`Order #${orderId} not found for settlement`);
      }

      const shippingFee = Number(order.shipping_fee) || 50.0;
      const driver = order.assigned_driver;
      const merchant = order.merchant;

      // 1. Calculate Driver Commission
      const commissionPct = driver ? Number(driver.commission_percentage) || 10.0 : 10.0;
      const driverCommission = (collectedAmount * commissionPct) / 100.0;

      // 2. Calculate Merchant Net Payout (Collected Amount minus Shipping Fee)
      const merchantNetPayout = Math.max(0, collectedAmount - shippingFee);

      // 3. Update Order financial fields
      order.collected_amount = collectedAmount;
      order.driver_commission = driverCommission;
      order.merchant_net_payout = merchantNetPayout;
      order.status = isPartialDelivery
        ? OrderStatus.PARTIALLY_DELIVERED
        : OrderStatus.DELIVERED;
      order.is_partially_delivered = isPartialDelivery;

      await queryRunner.manager.save(order);

      // 4. Update Merchant Wallet & Log Transaction
      if (merchant) {
        const merchantBefore = Number(merchant.wallet_balance_egp) || 0;
        const merchantAfter = merchantBefore + merchantNetPayout;
        merchant.wallet_balance_egp = merchantAfter;
        await queryRunner.manager.save(merchant);

        // Record Merchant Credit in Wallet Transactions
        const merchantTx = this.walletTxRepo.create({
          entity_type: EntityType.MERCHANT,
          entity_id: merchant.id,
          transaction_type: WalletTransactionType.ORDER_DELIVERY_CREDIT,
          amount: merchantNetPayout,
          balance_before: merchantBefore,
          balance_after: merchantAfter,
          reference_order_id: order.id,
          notes: `تسوية أوردر مسلم #${order.order_number} (تحصيل: ${collectedAmount} ج.م - مصاريف شحن: ${shippingFee} ج.م)`,
        });
        await queryRunner.manager.save(merchantTx);
      }

      // 5. Update Driver Cash in Hand & Log Commission
      if (driver && order.is_cod) {
        const driverCashBefore = Number(driver.current_cash_in_hand) || 0;
        const driverCashAfter = driverCashBefore + collectedAmount;
        driver.current_cash_in_hand = driverCashAfter;
        await queryRunner.manager.save(driver);

        const driverTx = this.walletTxRepo.create({
          entity_type: EntityType.DRIVER,
          entity_id: driver.id,
          transaction_type: WalletTransactionType.DRIVER_CASH_COLLECTED,
          amount: collectedAmount,
          balance_before: driverCashBefore,
          balance_after: driverCashAfter,
          reference_order_id: order.id,
          notes: `تحصيل كاش من العميل لشحنة #${order.order_number} (عمولة مستحقة: ${driverCommission.toFixed(2)} ج.م)`,
        });
        await queryRunner.manager.save(driverTx);
      }

      await queryRunner.commitTransaction();
      this.logger.log(
        `✅ Automated settlement completed for Order #${order.order_number}: Merchant Net: ${merchantNetPayout} EGP, Driver Comm: ${driverCommission} EGP`,
      );

      return {
        driverCommission,
        merchantNetPayout,
        shippingFee,
      };
    } catch (err) {
      await queryRunner.rollbackTransaction();
      this.logger.error(`Settlement failed for Order #${orderId}: ${err.message}`);
      throw err;
    } finally {
      await queryRunner.release();
    }
  }
}
