import { DataSource } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User } from '../entities/user.entity';
import { Product } from '../entities/product.entity';
import { Order } from '../entities/order.entity';
import { OrderItem } from '../entities/order-item.entity';
import { OrderTrackingHistory } from '../entities/order-tracking-history.entity';
import { DriverLedger } from '../entities/driver-ledger.entity';
import { PaymentTransaction } from '../entities/payment-transaction.entity';
import { UserRole } from '../../common/enums/roles.enum';
import { OrderStatus } from '../../common/enums/order-status.enum';
import { PaymentMethod, PaymentStatus } from '../../common/enums/payment-method.enum';
import { LedgerTransactionType } from '../../common/enums/ledger-transaction-type.enum';

export async function runInitialSeed(dataSource: DataSource) {
  const userRepo = dataSource.getRepository(User);
  const productRepo = dataSource.getRepository(Product);
  const orderRepo = dataSource.getRepository(Order);
  const orderItemRepo = dataSource.getRepository(OrderItem);
  const trackingRepo = dataSource.getRepository(OrderTrackingHistory);
  const ledgerRepo = dataSource.getRepository(DriverLedger);

  console.log('🌱 Starting Database Seeding...');

  // 1. Seed Users
  const passwordHash = await bcrypt.hash('AdminPassword2026!', 10);
  const driverHash = await bcrypt.hash('DriverPassword2026!', 10);
  const customerHash = await bcrypt.hash('CustomerPassword2026!', 10);

  let admin = await userRepo.findOne({ where: { email: 'admin@antigravity.io' } });
  if (!admin) {
    admin = userRepo.create({
      email: 'admin@antigravity.io',
      password_hash: passwordHash,
      full_name: 'System Super Admin',
      phone: '+201000000001',
      role: UserRole.ADMIN,
      is_active: true,
    });
    admin = await userRepo.save(admin);
    console.log('✅ Created Admin user');
  }

  let driver = await userRepo.findOne({ where: { email: 'driver1@antigravity.io' } });
  if (!driver) {
    driver = userRepo.create({
      email: 'driver1@antigravity.io',
      password_hash: driverHash,
      full_name: 'Ahmed Mahmoud (Driver)',
      phone: '+201012345678',
      role: UserRole.DRIVER,
      is_active: true,
      commission_rate: 10.0,
    });
    driver = await userRepo.save(driver);
    console.log('✅ Created Driver user');
  }

  let customer = await userRepo.findOne({ where: { email: 'customer@antigravity.io' } });
  if (!customer) {
    customer = userRepo.create({
      email: 'customer@antigravity.io',
      password_hash: customerHash,
      full_name: 'Sara Ibrahim',
      phone: '+201098765432',
      role: UserRole.CUSTOMER,
      is_active: true,
    });
    customer = await userRepo.save(customer);
    console.log('✅ Created Customer user');
  }

  // 2. Seed Products
  const sampleProducts = [
    {
      sku: 'ELEC-WRLS-001',
      name: 'Wireless Bluetooth Earbuds Pro',
      description: 'Active Noise Cancelling high-fidelity earbuds with 36hr battery.',
      price: 1450.0,
      cost_price: 900.0,
      stock_quantity: 50,
      warehouse_location: 'Warehouse-Cairo-A12',
      barcode_qr_data: 'SKU:ELEC-WRLS-001|PRICE:1450',
      category: 'Electronics',
      image_url: 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=500&auto=format&fit=crop&q=60',
    },
    {
      sku: 'ELEC-SMWT-002',
      name: 'Ultra AMOLED Smartwatch GPS',
      description: 'Waterproof sports watch with heart rate and blood oxygen sensor.',
      price: 2850.0,
      cost_price: 1800.0,
      stock_quantity: 35,
      warehouse_location: 'Warehouse-Cairo-B04',
      barcode_qr_data: 'SKU:ELEC-SMWT-002|PRICE:2850',
      category: 'Electronics',
      image_url: 'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?w=500&auto=format&fit=crop&q=60',
    },
    {
      sku: 'APPR-JACK-003',
      name: 'Waterproof Winter Windbreaker',
      description: 'Thermal insulated breathable outdoor rain jacket.',
      price: 1200.0,
      cost_price: 750.0,
      stock_quantity: 80,
      warehouse_location: 'Warehouse-Giza-C01',
      barcode_qr_data: 'SKU:APPR-JACK-003|PRICE:1200',
      category: 'Apparel',
      image_url: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=500&auto=format&fit=crop&q=60',
    },
    {
      sku: 'HOME-ESPR-004',
      name: 'Compact Italian Espresso Machine 15-Bar',
      description: 'Professional milk frother with pressure gauge and dual filters.',
      price: 4950.0,
      cost_price: 3200.0,
      stock_quantity: 20,
      warehouse_location: 'Warehouse-Cairo-D09',
      barcode_qr_data: 'SKU:HOME-ESPR-004|PRICE:4950',
      category: 'Home & Kitchen',
      image_url: 'https://images.unsplash.com/photo-1517668808822-9ebb02f2a0e6?w=500&auto=format&fit=crop&q=60',
    },
  ];

  const savedProducts: Product[] = [];
  for (const item of sampleProducts) {
    let prod = await productRepo.findOne({ where: { sku: item.sku } });
    if (!prod) {
      prod = productRepo.create(item);
      prod = await productRepo.save(prod);
      console.log(`✅ Created Product: ${prod.name}`);
    }
    savedProducts.push(prod);
  }

  // 3. Seed Sample Orders
  const existingOrdersCount = await orderRepo.count();
  if (existingOrdersCount === 0) {
    // Order 1: Dispatched to Driver
    const order1 = orderRepo.create({
      order_number: 'ORD-2026-10001',
      customer: customer,
      customer_name: customer.full_name,
      customer_phone: customer.phone,
      shipping_address: '15 El-Tahrir Square, Downtown, Cairo',
      city: 'Cairo',
      geo_lat: 30.0444,
      geo_lng: 31.2357,
      status: OrderStatus.Dispatched_to_Driver,
      payment_method: PaymentMethod.CASH_ON_DELIVERY,
      payment_status: PaymentStatus.UNPAID,
      subtotal: 1450.0,
      shipping_fee: 50.0,
      total_amount: 1500.0,
      assigned_driver: driver,
      scheduled_delivery_date: new Date(),
      waybill_qr_code: 'WAYBILL:ORD-2026-10001|COD:1500|ADDR:Tahrir_Cairo',
    });
    const savedOrder1 = await orderRepo.save(order1);

    await orderItemRepo.save(
      orderItemRepo.create({
        order: savedOrder1,
        product: savedProducts[0],
        product_name: savedProducts[0].name,
        product_sku: savedProducts[0].sku,
        quantity: 1,
        unit_price: 1450.0,
        total_price: 1450.0,
      }),
    );

    await trackingRepo.save([
      trackingRepo.create({
        order: savedOrder1,
        previous_status: null,
        new_status: OrderStatus.Pending,
        changed_by_user: customer,
        notes: 'Order placed by customer via Storefront',
      }),
      trackingRepo.create({
        order: savedOrder1,
        previous_status: OrderStatus.Pending,
        new_status: OrderStatus.In_Warehouse,
        changed_by_user: admin,
        notes: 'Items picked and packed in Cairo Central Warehouse',
      }),
      trackingRepo.create({
        order: savedOrder1,
        previous_status: OrderStatus.In_Warehouse,
        new_status: OrderStatus.Dispatched_to_Driver,
        changed_by_user: admin,
        driver: driver,
        notes: 'Handed over to Ahmed Mahmoud for route delivery',
      }),
    ]);

    // Order 2: Delivered & Paid via Paymob Card
    const order2 = orderRepo.create({
      order_number: 'ORD-2026-10002',
      customer: customer,
      customer_name: customer.full_name,
      customer_phone: customer.phone,
      shipping_address: '42 Road 9, Maadi, Cairo',
      city: 'Cairo',
      geo_lat: 29.9592,
      geo_lng: 31.2612,
      status: OrderStatus.Delivered,
      payment_method: PaymentMethod.PAYMOB_CARD,
      payment_status: PaymentStatus.PAID,
      subtotal: 2850.0,
      shipping_fee: 50.0,
      total_amount: 2900.0,
      assigned_driver: driver,
      delivered_at: new Date(),
      waybill_qr_code: 'WAYBILL:ORD-2026-10002|PREPAID:2900|ADDR:Maadi_Cairo',
      delivery_notes: 'Delivered to reception at Maadi branch',
    });
    const savedOrder2 = await orderRepo.save(order2);

    await orderItemRepo.save(
      orderItemRepo.create({
        order: savedOrder2,
        product: savedProducts[1],
        product_name: savedProducts[1].name,
        product_sku: savedProducts[1].sku,
        quantity: 1,
        unit_price: 2850.0,
        total_price: 2850.0,
      }),
    );

    await trackingRepo.save([
      trackingRepo.create({
        order: savedOrder2,
        previous_status: OrderStatus.Dispatched_to_Driver,
        new_status: OrderStatus.Delivered,
        changed_by_user: driver,
        driver: driver,
        notes: 'Customer signed waybill and package received successfully',
      }),
    ]);

    // Driver Commission for Order 2 (10% of shipping fee or base delivery fee: e.g., 25 EGP)
    await ledgerRepo.save(
      ledgerRepo.create({
        driver: driver,
        order: savedOrder2,
        transaction_type: LedgerTransactionType.COMMISSION_EARNED,
        amount: 25.0,
        running_balance: -25.0, // Company owes driver 25 EGP
        description: 'Commission for delivering ORD-2026-10002',
        reference_code: 'COMM-ORD-2026-10002',
      }),
    );

    console.log('✅ Seeded Sample Orders, Tracking History & Driver Ledger');
  }

  console.log('✨ Seeding completed successfully!');
}
