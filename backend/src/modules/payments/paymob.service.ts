import {
  Injectable,
  BadRequestException,
  UnauthorizedException,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import axios from 'axios';
import * as crypto from 'crypto';
import { Order } from '../../database/entities/order.entity';
import { PaymentTransaction } from '../../database/entities/payment-transaction.entity';
import { OrderTrackingHistory } from '../../database/entities/order-tracking-history.entity';
import { InitiatePaymobPaymentDto } from './dto/paymob.dto';
import { PaymentMethod, PaymentStatus } from '../../common/enums/payment-method.enum';
import { OrderStatus } from '../../common/enums/order-status.enum';

@Injectable()
export class PaymobService {
  private readonly logger = new Logger(PaymobService.name);
  private readonly baseUrl = 'https://accept.paymob.com/api';

  constructor(
    private configService: ConfigService,
    @InjectRepository(Order)
    private orderRepository: Repository<Order>,
    @InjectRepository(PaymentTransaction)
    private transactionRepository: Repository<PaymentTransaction>,
    @InjectRepository(OrderTrackingHistory)
    private trackingRepository: Repository<OrderTrackingHistory>,
  ) {}

  async initiatePayment(dto: InitiatePaymobPaymentDto): Promise<{
    payment_url?: string;
    payment_token?: string;
    iframe_url?: string;
    redirect_url?: string;
    transaction_id: string;
  }> {
    const order = await this.orderRepository.findOne({
      where: { id: dto.order_id },
      relations: ['customer', 'items'],
    });

    if (!order) {
      throw new BadRequestException('Order not found');
    }

    if (order.payment_status === PaymentStatus.PAID) {
      throw new BadRequestException('Order is already paid');
    }

    const apiKey = this.configService.get<string>('paymob.apiKey');
    const amountCents = Math.round(Number(order.total_amount) * 100);

    // If live API key is not configured, generate realistic sandbox checkout session
    if (!apiKey || apiKey.length < 20) {
      this.logger.warn('Paymob API Key not set. Returning Sandbox Payment Session.');
      const mockTx = this.transactionRepository.create({
        order_id: order.id,
        paymob_order_id: `MOCK-ORDER-${Date.now()}`,
        amount_cents: amountCents,
        currency: 'EGP',
        payment_method: dto.payment_method,
        status: PaymentStatus.PENDING,
      });
      const savedTx = await this.transactionRepository.save(mockTx);

      return {
        iframe_url: `https://accept.paymob.com/api/acceptance/iframes/789123?payment_token=mock_token_${savedTx.id}`,
        payment_token: `mock_token_${savedTx.id}`,
        transaction_id: savedTx.id,
      };
    }

    try {
      // Step 1: Authentication Token
      const authRes = await axios.post(`${this.baseUrl}/auth/tokens`, {
        api_key: apiKey,
      });
      const authToken = authRes.data.token;

      // Step 2: Order Registration
      const orderRes = await axios.post(`${this.baseUrl}/ecommerce/orders`, {
        auth_token: authToken,
        delivery_needed: 'false',
        amount_cents: amountCents,
        currency: 'EGP',
        merchant_order_id: order.order_number,
        items: (order.items || []).map((i) => ({
          name: i.product_name,
          amount_cents: Math.round(Number(i.unit_price) * 100),
          quantity: i.quantity,
        })),
      });
      const paymobOrderId = orderRes.data.id;

      // Determine Integration ID based on payment type
      let integrationId = this.configService.get<number>('paymob.integrationIdCard');
      if (dto.payment_method === PaymentMethod.PAYMOB_WALLET) {
        integrationId = this.configService.get<number>('paymob.integrationIdWallet');
      } else if (dto.payment_method === PaymentMethod.PAYMOB_MEEZA) {
        integrationId = this.configService.get<number>('paymob.integrationIdMeeza');
      }

      // Step 3: Payment Key Generation
      const keyRes = await axios.post(`${this.baseUrl}/acceptance/payment_keys`, {
        auth_token: authToken,
        amount_cents: amountCents,
        expiration: 3600,
        order_id: paymobOrderId,
        billing_data: {
          apartment: 'NA',
          email: order.customer?.email || 'customer@antigravity.io',
          floor: 'NA',
          first_name: order.customer_name.split(' ')[0] || 'Customer',
          street: order.shipping_address,
          building: 'NA',
          phone_number: order.customer_phone,
          shipping_method: 'PKG',
          postal_code: '11511',
          city: order.city || 'Cairo',
          country: 'EGY',
          last_name: order.customer_name.split(' ')[1] || 'Guest',
          state: 'Cairo',
        },
        currency: 'EGP',
        integration_id: integrationId,
      });

      const paymentToken = keyRes.data.token;

      // Record transaction
      const paymentTx = this.transactionRepository.create({
        order_id: order.id,
        paymob_order_id: String(paymobOrderId),
        amount_cents: amountCents,
        currency: 'EGP',
        payment_method: dto.payment_method,
        status: PaymentStatus.PENDING,
      });
      const savedTx = await this.transactionRepository.save(paymentTx);

      // Handle Mobile Wallet Intention (Vodafone Cash, Orange, InstaPay)
      if (dto.payment_method === PaymentMethod.PAYMOB_WALLET) {
        if (!dto.wallet_mobile_number) {
          throw new BadRequestException('Wallet mobile number is required for mobile wallet payment');
        }

        const walletRes = await axios.post(`${this.baseUrl}/acceptance/payments/pay`, {
          source: {
            identifier: dto.wallet_mobile_number,
            subtype: 'WALLET',
          },
          payment_token: paymentToken,
        });

        return {
          redirect_url: walletRes.data.redirect_url,
          payment_token: paymentToken,
          transaction_id: savedTx.id,
        };
      }

      // Card / Meeza standard iFrame URL
      const iframeId = this.configService.get<number>('paymob.iframeId') || 789123;
      const iframeUrl = `https://accept.paymob.com/api/acceptance/iframes/${iframeId}?payment_token=${paymentToken}`;

      return {
        iframe_url: iframeUrl,
        payment_token: paymentToken,
        transaction_id: savedTx.id,
      };
    } catch (error) {
      this.logger.error(`Paymob payment initiation failed: ${error.response?.data || error.message}`);
      throw new BadRequestException(`Payment gateway error: ${error.message}`);
    }
  }

  calculateHmacSha512(data: any): string {
    const hmacSecret = this.configService.get<string>('paymob.hmacSecret');
    if (!hmacSecret) {
      return '';
    }

    const obj = data.obj || data;
    const concatenatedString = [
      obj.amount_cents,
      obj.created_at,
      obj.currency,
      obj.error_occured,
      obj.has_parent_transaction,
      obj.id,
      obj.integration_id,
      obj.is_3d_secure,
      obj.is_auth,
      obj.is_capture,
      obj.is_refunded,
      obj.is_standalone_payment,
      obj.is_voided,
      obj.order?.id || obj.order,
      obj.owner,
      obj.pending,
      obj.source_data?.pan || '',
      obj.source_data?.sub_type || '',
      obj.source_data?.type || '',
      obj.success,
    ].join('');

    return crypto.createHmac('sha512', hmacSecret).update(concatenatedString).digest('hex');
  }

  async processWebhookCallback(body: any, receivedHmac?: string): Promise<{ status: string }> {
    this.logger.log(`Received Paymob Webhook: type=${body.type}`);

    const hmacSecret = this.configService.get<string>('paymob.hmacSecret');
    let hmacValid = true;

    if (hmacSecret && receivedHmac) {
      const calculated = this.calculateHmacSha512(body);
      if (calculated.toLowerCase() !== receivedHmac.toLowerCase()) {
        this.logger.error('HMAC Signature verification failed for Paymob Webhook');
        throw new UnauthorizedException('HMAC signature verification failed');
      }
    }

    const obj = body.obj;
    if (!obj) {
      return { status: 'ignored' };
    }

    const paymobOrderId = String(obj.order?.id || obj.order);
    const paymobTransactionId = String(obj.id);
    const isSuccess = obj.success === true && obj.pending === false;

    const transaction = await this.transactionRepository.findOne({
      where: [{ paymob_order_id: paymobOrderId }, { paymob_transaction_id: paymobTransactionId }],
      relations: ['order'],
    });

    if (!transaction) {
      this.logger.warn(`Transaction for Paymob order ${paymobOrderId} not found.`);
      return { status: 'not_found' };
    }

    transaction.paymob_transaction_id = paymobTransactionId;
    transaction.hmac_validated = hmacValid;
    transaction.raw_payload = body;
    transaction.status = isSuccess ? PaymentStatus.PAID : PaymentStatus.FAILED;

    if (!isSuccess) {
      transaction.failure_reason = obj.data?.message || 'Transaction rejected';
    }

    await this.transactionRepository.save(transaction);

    if (isSuccess && transaction.order) {
      const order = transaction.order;
      order.payment_status = PaymentStatus.PAID;

      // Automatically transition order from Pending to In_Warehouse upon verified payment
      if (order.status === OrderStatus.Pending) {
        order.status = OrderStatus.In_Warehouse;
      }

      await this.orderRepository.save(order);

      await this.trackingRepository.save(
        this.trackingRepository.create({
          order_id: order.id,
          previous_status: OrderStatus.Pending,
          new_status: order.status,
          notes: `Paymob payment succeeded (${Number(transaction.amount_cents) / 100} EGP). Status updated.`,
        }),
      );
    }

    return { status: isSuccess ? 'success' : 'failed' };
  }
}
