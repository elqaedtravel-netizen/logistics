import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource, Between, LessThanOrEqual, MoreThanOrEqual } from 'typeorm';
import { Order } from '../../database/entities/order.entity';
import { OrderItem } from '../../database/entities/order-item.entity';
import { OrderTrackingHistory } from '../../database/entities/order-tracking-history.entity';
import { User } from '../../database/entities/user.entity';
import { DriverLedger } from '../../database/entities/driver-ledger.entity';
import { ProductsService } from '../products/products.service';
import { OrderStateMachineService } from './state-machine.service';
import { WaybillService } from './waybill.service';
import {
  CreateOrderDto,
  UpdateOrderStatusDto,
  AssignDriverDto,
  PostponeOrderDto,
  DeliverOrderDto,
  QueryOrdersDto,
} from './dto/orders.dto';
import { OrderStatus } from '../../common/enums/order-status.enum';
import { PaymentMethod, PaymentStatus } from '../../common/enums/payment-method.enum';
import { LedgerTransactionType } from '../../common/enums/ledger-transaction-type.enum';
import { UserRole } from '../../common/enums/roles.enum';

@Injectable()
export class OrdersService {
  private readonly logger = new Logger(OrdersService.name);

  constructor(
    @InjectRepository(Order)
    private orderRepository: Repository<Order>,
    @InjectRepository(OrderItem)
    private orderItemRepository: Repository<OrderItem>,
    @InjectRepository(OrderTrackingHistory)
    private trackingRepository: Repository<OrderTrackingHistory>,
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(DriverLedger)
    private ledgerRepository: Repository<DriverLedger>,
    private productsService: ProductsService,
    private stateMachineService: OrderStateMachineService,
    private waybillService: WaybillService,
    private dataSource: DataSource,
  ) {}

  async create(createOrderDto: CreateOrderDto, customerUser?: User): Promise<Order> {
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      if (!createOrderDto.items || createOrderDto.items.length === 0) {
        throw new BadRequestException('Order must contain at least one item');
      }

      // Generate Order Number
      const randomSuffix = Math.floor(10000 + Math.random() * 90000);
      const orderNumber = `ORD-2026-${randomSuffix}`;

      let subtotal = 0;
      const orderItemsToCreate: OrderItem[] = [];

      for (const itemDto of createOrderDto.items) {
        const product = await this.productsService.findOne(itemDto.product_id);
        if (product.stock_quantity < itemDto.quantity) {
          throw new BadRequestException(
            `Insufficient stock for "${product.name}". Available: ${product.stock_quantity}, requested: ${itemDto.quantity}`,
          );
        }

        const itemTotal = Number(product.price) * itemDto.quantity;
        subtotal += itemTotal;

        const orderItem = this.orderItemRepository.create({
          product_id: product.id,
          product_name: product.name,
          product_sku: product.sku,
          quantity: itemDto.quantity,
          unit_price: product.price,
          total_price: itemTotal,
        });
        orderItemsToCreate.push(orderItem);

        // Decrement stock
        product.stock_quantity -= itemDto.quantity;
        await queryRunner.manager.save(product);
      }

      const shippingFee = 50.0;
      const totalAmount = subtotal + shippingFee;

      const order = this.orderRepository.create({
        order_number: orderNumber,
        customer_id: customerUser ? customerUser.id : null,
        customer_name: createOrderDto.customer_name,
        customer_phone: createOrderDto.customer_phone,
        shipping_address: createOrderDto.shipping_address,
        city: createOrderDto.city || 'Cairo',
        geo_lat: createOrderDto.geo_lat,
        geo_lng: createOrderDto.geo_lng,
        status: OrderStatus.Pending,
        payment_method: createOrderDto.payment_method,
        payment_status:
          createOrderDto.payment_method === PaymentMethod.CASH_ON_DELIVERY
            ? PaymentStatus.UNPAID
            : PaymentStatus.PENDING,
        subtotal: subtotal,
        shipping_fee: shippingFee,
        total_amount: totalAmount,
        waybill_qr_code: `WAYBILL:${orderNumber}|${createOrderDto.payment_method === PaymentMethod.CASH_ON_DELIVERY ? `COD:${totalAmount}` : `PREPAID:${totalAmount}`}|PHONE:${createOrderDto.customer_phone}`,
      });

      const savedOrder = await queryRunner.manager.save(order);

      // Save order items
      for (const item of orderItemsToCreate) {
        item.order_id = savedOrder.id;
        await queryRunner.manager.save(item);
      }

      // Initial Tracking History Record
      const tracking = this.trackingRepository.create({
        order_id: savedOrder.id,
        previous_status: null,
        new_status: OrderStatus.Pending,
        changed_by_user_id: customerUser ? customerUser.id : null,
        notes: 'Order created and entered Pending status',
      });
      await queryRunner.manager.save(tracking);

      await queryRunner.commitTransaction();

      return this.findOne(savedOrder.id);
    } catch (error) {
      await queryRunner.rollbackTransaction();
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  async findAll(query: QueryOrdersDto): Promise<{ orders: Order[]; count: number }> {
    const qb = this.orderRepository
      .createQueryBuilder('order')
      .leftJoinAndSelect('order.customer', 'customer')
      .leftJoinAndSelect('order.assigned_driver', 'driver')
      .leftJoinAndSelect('order.items', 'items')
      .orderBy('order.created_at', 'DESC');

    if (query.status) {
      qb.andWhere('order.status = :status', { status: query.status });
    }

    if (query.driver_id) {
      qb.andWhere('order.assigned_driver_id = :driverId', { driverId: query.driver_id });
    }

    if (query.search) {
      qb.andWhere(
        '(LOWER(order.order_number) LIKE :search OR LOWER(order.customer_name) LIKE :search OR order.customer_phone LIKE :search)',
        { search: `%${query.search.toLowerCase()}%` },
      );
    }

    if (query.date_from && query.date_to) {
      qb.andWhere('order.created_at BETWEEN :from AND :to', {
        from: new Date(query.date_from),
        to: new Date(query.date_to),
      });
    }

    const [orders, count] = await qb.getManyAndCount();
    return { orders, count };
  }

  async findOne(id: string): Promise<Order> {
    const order = await this.orderRepository.findOne({
      where: { id },
      relations: ['customer', 'assigned_driver', 'items', 'tracking_history', 'ledger_records', 'payment_transactions'],
    });
    if (!order) {
      throw new NotFoundException(`Order with ID ${id} not found`);
    }
    return order;
  }

  async findByOrderNumber(orderNumber: string): Promise<Order> {
    const order = await this.orderRepository.findOne({
      where: { order_number: orderNumber.trim() },
      relations: ['customer', 'assigned_driver', 'items', 'tracking_history'],
    });
    if (!order) {
      throw new NotFoundException(`Order with number "${orderNumber}" not found`);
    }
    return order;
  }

  async findDriverAssignedOrders(driverId: string, status?: OrderStatus): Promise<Order[]> {
    const qb = this.orderRepository
      .createQueryBuilder('order')
      .leftJoinAndSelect('order.items', 'items')
      .leftJoinAndSelect('order.customer', 'customer')
      .where('order.assigned_driver_id = :driverId', { driverId });

    if (status) {
      qb.andWhere('order.status = :status', { status });
    } else {
      qb.andWhere('order.status IN (:...statuses)', {
        statuses: [OrderStatus.Dispatched_to_Driver, OrderStatus.Postponed],
      });
    }

    qb.orderBy('order.scheduled_delivery_date', 'ASC').addOrderBy('order.created_at', 'ASC');

    return qb.getMany();
  }

  async updateStatus(id: string, dto: UpdateOrderStatusDto, actorUser: User): Promise<Order> {
    const order = await this.findOne(id);
    const isAdmin = actorUser.role === UserRole.ADMIN;

    this.stateMachineService.validateTransition(order.status, dto.status, isAdmin);

    const prevStatus = order.status;
    order.status = dto.status;

    if (dto.status === OrderStatus.Delivered && !order.delivered_at) {
      order.delivered_at = new Date();
    }

    // If order was canceled or returned, restock products
    if (
      (dto.status === OrderStatus.Canceled || dto.status === OrderStatus.Returned) &&
      prevStatus !== OrderStatus.Canceled &&
      prevStatus !== OrderStatus.Returned
    ) {
      for (const item of order.items) {
        await this.productsService.incrementStock(item.product_id, item.quantity);
      }
    }

    const saved = await this.orderRepository.save(order);

    await this.trackingRepository.save(
      this.trackingRepository.create({
        order_id: order.id,
        previous_status: prevStatus,
        new_status: dto.status,
        changed_by_user_id: actorUser.id,
        driver_id: order.assigned_driver_id,
        notes: dto.notes || `Status changed from ${prevStatus} to ${dto.status}`,
        location_lat: dto.location_lat,
        location_lng: dto.location_lng,
      }),
    );

    return saved;
  }

  async assignDriver(id: string, dto: AssignDriverDto, actorUser: User): Promise<Order> {
    const order = await this.findOne(id);
    const driver = await this.userRepository.findOne({ where: { id: dto.driver_id } });

    if (!driver || driver.role !== UserRole.DRIVER) {
      throw new BadRequestException('Assigned user must be an active Driver');
    }

    const prevStatus = order.status;
    order.assigned_driver_id = driver.id;
    order.assigned_driver = driver;
    order.scheduled_delivery_date = dto.scheduled_delivery_date
      ? new Date(dto.scheduled_delivery_date)
      : new Date();

    if (order.status === OrderStatus.In_Warehouse || order.status === OrderStatus.Pending) {
      order.status = OrderStatus.Dispatched_to_Driver;
    }

    const saved = await this.orderRepository.save(order);

    await this.trackingRepository.save(
      this.trackingRepository.create({
        order_id: order.id,
        previous_status: prevStatus,
        new_status: order.status,
        changed_by_user_id: actorUser.id,
        driver_id: driver.id,
        notes: `Order assigned to driver ${driver.full_name} (${driver.phone})`,
      }),
    );

    return saved;
  }

  async postponeOrder(id: string, dto: PostponeOrderDto, driverUser: User): Promise<Order> {
    const order = await this.findOne(id);

    if (order.assigned_driver_id !== driverUser.id && driverUser.role !== UserRole.ADMIN) {
      throw new BadRequestException('You can only postpone orders assigned to your route');
    }

    const prevStatus = order.status;
    order.status = OrderStatus.Postponed;
    order.postponement_reason = dto.reason;
    order.postponement_notes = dto.notes;

    if (dto.new_delivery_date) {
      order.scheduled_delivery_date = new Date(dto.new_delivery_date);
    }

    const saved = await this.orderRepository.save(order);

    await this.trackingRepository.save(
      this.trackingRepository.create({
        order_id: order.id,
        previous_status: prevStatus,
        new_status: OrderStatus.Postponed,
        changed_by_user_id: driverUser.id,
        driver_id: driverUser.id,
        reason_code: dto.reason,
        notes: `Order postponed: [${dto.reason}] - ${dto.notes || 'No extra notes'}`,
      }),
    );

    return saved;
  }

  async deliverOrder(id: string, dto: DeliverOrderDto, driverUser: User): Promise<Order> {
    const order = await this.findOne(id);

    if (order.assigned_driver_id !== driverUser.id && driverUser.role !== UserRole.ADMIN) {
      throw new BadRequestException('You can only deliver orders assigned to your route');
    }

    const prevStatus = order.status;
    order.status = OrderStatus.Delivered;
    order.delivered_at = new Date();
    order.delivery_notes = dto.delivery_notes;
    order.delivery_signature_url = dto.signature_url;

    // If payment method is COD, mark paid and record in driver financial ledger
    if (order.payment_method === PaymentMethod.CASH_ON_DELIVERY) {
      order.payment_status = PaymentStatus.PAID;

      // Calculate driver latest balance
      const lastLedger = await this.ledgerRepository.findOne({
        where: { driver_id: driverUser.id },
        orderBy: { created_at: 'DESC' },
      });

      const currentBalance = lastLedger ? Number(lastLedger.running_balance) : 0;
      const orderAmount = Number(order.total_amount);
      const newBalance = currentBalance + orderAmount; // Driver owes company the collected cash

      await this.ledgerRepository.save(
        this.ledgerRepository.create({
          driver_id: driverUser.id,
          order_id: order.id,
          transaction_type: LedgerTransactionType.CASH_COLLECTED,
          amount: orderAmount,
          running_balance: newBalance,
          description: `COD collected for delivered order #${order.order_number}`,
          reference_code: `COD-${order.order_number}`,
        }),
      );

      // Record Driver Commission (e.g. 10% of shipping fee or base delivery allowance)
      const commissionRate = driverUser.commission_rate || 10.0;
      const commissionAmount = (Number(order.shipping_fee) * commissionRate) / 100;
      const balanceAfterCommission = newBalance - commissionAmount;

      await this.ledgerRepository.save(
        this.ledgerRepository.create({
          driver_id: driverUser.id,
          order_id: order.id,
          transaction_type: LedgerTransactionType.COMMISSION_EARNED,
          amount: commissionAmount,
          running_balance: balanceAfterCommission,
          description: `Delivery commission (${commissionRate}%) for order #${order.order_number}`,
          reference_code: `COMM-${order.order_number}`,
        }),
      );
    }

    const saved = await this.orderRepository.save(order);

    await this.trackingRepository.save(
      this.trackingRepository.create({
        order_id: order.id,
        previous_status: prevStatus,
        new_status: OrderStatus.Delivered,
        changed_by_user_id: driverUser.id,
        driver_id: driverUser.id,
        notes: dto.delivery_notes || 'Delivered successfully and confirmed by driver',
        location_lat: dto.location_lat,
        location_lng: dto.location_lng,
      }),
    );

    return saved;
  }

  async bulkUpdateStatusViaScan(
    barcodes: string[],
    targetStatus: OrderStatus,
    actorUser: User,
  ): Promise<{ updatedCount: number; errors: { barcode: string; error: string }[] }> {
    let updatedCount = 0;
    const errors: { barcode: string; error: string }[] = [];

    for (const rawBarcode of barcodes) {
      try {
        const { orderNumber } = this.waybillService.parseScannedBarcode(rawBarcode);
        const order = await this.findByOrderNumber(orderNumber);
        await this.updateStatus(order.id, { status: targetStatus }, actorUser);
        updatedCount++;
      } catch (err) {
        errors.push({ barcode: rawBarcode, error: err.message });
      }
    }

    return { updatedCount, errors };
  }

  async getTrackingHistory(orderNumber: string) {
    const order = await this.findByOrderNumber(orderNumber);
    const tracking = await this.trackingRepository.find({
      where: { order_id: order.id },
      relations: ['changed_by_user', 'driver'],
      order: { created_at: 'ASC' },
    });

    return {
      order_number: order.order_number,
      current_status: order.status,
      customer_name: order.customer_name,
      shipping_address: order.shipping_address,
      city: order.city,
      payment_method: order.payment_method,
      total_amount: order.total_amount,
      scheduled_delivery_date: order.scheduled_delivery_date,
      delivered_at: order.delivered_at,
      assigned_driver: order.assigned_driver
        ? {
            id: order.assigned_driver.id,
            name: order.assigned_driver.full_name,
            phone: order.assigned_driver.phone,
          }
        : null,
      timeline: tracking.map((t) => ({
        previous_status: t.previous_status,
        status: t.new_status,
        timestamp: t.created_at,
        notes: t.notes,
        reason_code: t.reason_code,
        actor: t.changed_by_user ? t.changed_by_user.full_name : 'System',
      })),
    };
  }

  async getWaybillData(orderId: string) {
    const order = await this.findOne(orderId);
    return this.waybillService.generateWaybill(order);
  }
}
