-- =======================================================================
-- ANTGRAVITY LOGISTICS & E-COMMERCE PLATFORM - PRODUCTION SUPABASE SCHEMA
-- Project Reference: ilbwotqmlrsrleebwned
-- Created for: PostgreSQL on Supabase
-- =======================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Create Enums
DO $$ BEGIN
    CREATE TYPE user_role_enum AS ENUM (
        'SuperAdmin', 'HubManager', 'FinanceAdmin', 'OperationsAdmin', 'MerchantAdmin', 'Driver', 'Customer'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE order_status_enum AS ENUM (
        'Pending', 'Ready_For_Pickup', 'In_Transit_To_Hub', 'At_Hub', 'Out_For_Delivery',
        'Delivered', 'Partially_Delivered', 'Postponed', 'Canceled', 'RTO'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_method_enum AS ENUM (
        'CASH_ON_DELIVERY', 'PAYMOB_CARD', 'PAYMOB_WALLET', 'PAYMOB_MEEZA', 'INSTAPAY'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_status_enum AS ENUM (
        'UNPAID', 'PAID', 'REFUNDED'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE rto_status_enum AS ENUM (
        'Initiated_By_Driver', 'Received_At_Hub', 'Returned_To_Merchant'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE entity_type_enum AS ENUM (
        'MERCHANT', 'DRIVER', 'COMPANY_VAULT'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE wallet_tx_type_enum AS ENUM (
        'ORDER_DELIVERY_CREDIT', 'SHIPPING_FEE_DEBIT', 'DRIVER_COMMISSION_CREDIT',
        'DRIVER_CASH_COLLECTED', 'DRIVER_CASH_SETTLEMENT', 'INSTAPAY_DEPOSIT',
        'MERCHANT_WITHDRAWAL', 'RTO_FEE_DEBIT'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- =======================================================================
-- 2. Create Tables
-- =======================================================================

-- Table: Users (Admins, Managers, Drivers, Customers)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    role user_role_enum DEFAULT 'Customer',
    permissions TEXT DEFAULT '',
    is_active BOOLEAN DEFAULT TRUE,
    hub_id UUID,
    national_id VARCHAR(50),
    driving_license_number VARCHAR(100),
    vehicle_type VARCHAR(50) DEFAULT 'موتوسيكل',
    commission_percentage DECIMAL(5, 2) DEFAULT 10.00,
    current_cash_in_hand DECIMAL(10, 2) DEFAULT 0.00,
    assigned_zone_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: Company Payment Settings (Official Payment Receiving Details)
CREATE TABLE IF NOT EXISTS company_payment_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_name VARCHAR(255) DEFAULT 'شركة أنتيجرافيتي إكسبريس للخدمات اللوجستية والشحن',
    instapay_address VARCHAR(255) DEFAULT 'antigravity.logistics@instapay',
    instapay_qr_image_url TEXT,
    vodafone_cash_number VARCHAR(50) DEFAULT '01012345678',
    orange_cash_number VARCHAR(50) DEFAULT '01212345678',
    etisalat_cash_number VARCHAR(50) DEFAULT '01112345678',
    we_pay_number VARCHAR(50) DEFAULT '01512345678',
    bank_name VARCHAR(255) DEFAULT 'البنك التجاري الدولي (CIB مصر)',
    bank_account_holder VARCHAR(255) DEFAULT 'شركة أنتيجرافيتي إكسبريس ش.م.م',
    bank_account_number VARCHAR(100) DEFAULT '100045892019',
    bank_iban VARCHAR(100) DEFAULT 'EG380010004589201900000000000',
    bank_swift_code VARCHAR(50) DEFAULT 'CIBEEGCX',
    is_active BOOLEAN DEFAULT TRUE,
    updated_by_admin_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: Hubs (Distribution Centers / Warehouses)
CREATE TABLE IF NOT EXISTS hubs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    hub_code VARCHAR(100) UNIQUE NOT NULL,
    hub_name VARCHAR(255) NOT NULL,
    governorate VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    manager_id UUID REFERENCES users(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: Zones (Routing & Geographic Zones)
CREATE TABLE IF NOT EXISTS zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    zone_code VARCHAR(100) UNIQUE NOT NULL,
    zone_name_ar VARCHAR(255) NOT NULL,
    governorate VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    hub_id UUID REFERENCES hubs(id) ON DELETE SET NULL,
    standard_shipping_fee_egp DECIMAL(6, 2) DEFAULT 50.00,
    estimated_delivery_hours INT DEFAULT 24,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: Merchants (Vendors / Commercial Accounts)
CREATE TABLE IF NOT EXISTS merchants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_name VARCHAR(255) NOT NULL,
    commercial_register VARCHAR(100),
    tax_id VARCHAR(100),
    contact_name VARCHAR(255) NOT NULL,
    contact_phone VARCHAR(50) NOT NULL,
    contact_email VARCHAR(255),
    wallet_balance_egp DECIMAL(12, 2) DEFAULT 0.00,
    cod_hold_balance_egp DECIMAL(12, 2) DEFAULT 0.00,
    default_shipping_fee_egp DECIMAL(6, 2) DEFAULT 50.00,
    return_shipping_fee_egp DECIMAL(6, 2) DEFAULT 25.00,
    bank_account_number VARCHAR(100),
    bank_iban VARCHAR(100),
    instapay_address VARCHAR(255),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: Products (Inventory Stock)
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sku VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    stock_quantity INT DEFAULT 0,
    min_stock_alert INT DEFAULT 5,
    warehouse_zone VARCHAR(100) DEFAULT 'رف A12',
    image_url TEXT,
    category VARCHAR(100) DEFAULT 'إلكترونيات',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: Orders
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number VARCHAR(100) UNIQUE NOT NULL,
    merchant_id UUID REFERENCES merchants(id) ON DELETE SET NULL,
    customer_name VARCHAR(255) NOT NULL,
    customer_phone VARCHAR(50) NOT NULL,
    customer_secondary_phone VARCHAR(50),
    shipping_address TEXT NOT NULL,
    city VARCHAR(100) DEFAULT 'القاهرة',
    governorate VARCHAR(100) DEFAULT 'القاهرة',
    zone_id UUID REFERENCES zones(id) ON DELETE SET NULL,
    hub_id UUID REFERENCES hubs(id) ON DELETE SET NULL,
    status order_status_enum DEFAULT 'Pending',
    payment_method payment_method_enum DEFAULT 'CASH_ON_DELIVERY',
    payment_status payment_status_enum DEFAULT 'UNPAID',
    total_amount DECIMAL(10, 2) DEFAULT 0.00,
    collected_amount DECIMAL(10, 2) DEFAULT 0.00,
    shipping_fee DECIMAL(6, 2) DEFAULT 50.00,
    driver_commission DECIMAL(6, 2) DEFAULT 15.00,
    merchant_net_payout DECIMAL(10, 2) DEFAULT 0.00,
    is_cod BOOLEAN DEFAULT TRUE,
    is_partially_delivered BOOLEAN DEFAULT FALSE,
    assigned_driver_id UUID REFERENCES users(id) ON DELETE SET NULL,
    waybill_qr_code TEXT,
    postponement_reason VARCHAR(255),
    rto_reason VARCHAR(255),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: Order Items (With Partial Delivery Quantities)
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    quantity INT DEFAULT 1,
    delivered_quantity INT DEFAULT 1,
    returned_quantity INT DEFAULT 0,
    unit_price DECIMAL(10, 2) NOT NULL,
    subtotal DECIMAL(10, 2) NOT NULL,
    is_rejected BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: Order Tracking History
CREATE TABLE IF NOT EXISTS order_tracking_histories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    status order_status_enum NOT NULL,
    changed_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: Proof Of Delivery (POD)
CREATE TABLE IF NOT EXISTS proof_of_deliveries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    recipient_name VARCHAR(255) NOT NULL,
    recipient_national_id VARCHAR(50),
    recipient_relation VARCHAR(100) DEFAULT 'المستلم شخصياً',
    photo_pod_url TEXT,
    signature_svg_data TEXT,
    gps_latitude DECIMAL(10, 7),
    gps_longitude DECIMAL(10, 7),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: Return To Origin Logs (RTO)
CREATE TABLE IF NOT EXISTS rto_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES users(id) ON DELETE SET NULL,
    hub_id UUID REFERENCES hubs(id) ON DELETE SET NULL,
    merchant_id UUID REFERENCES merchants(id) ON DELETE SET NULL,
    rto_status rto_status_enum DEFAULT 'Initiated_By_Driver',
    reason_code VARCHAR(100) NOT NULL,
    reason_description TEXT,
    return_shipping_fee DECIMAL(6, 2) DEFAULT 25.00,
    received_at_hub_at TIMESTAMP WITH TIME ZONE,
    returned_to_merchant_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: Wallet Transactions (Double-Entry Financial Ledger)
CREATE TABLE IF NOT EXISTS wallet_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_type entity_type_enum NOT NULL,
    entity_id UUID NOT NULL,
    transaction_type wallet_tx_type_enum NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    balance_before DECIMAL(12, 2) NOT NULL,
    balance_after DECIMAL(12, 2) NOT NULL,
    reference_order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
    payment_reference VARCHAR(255),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =======================================================================
-- 3. Initial Seed Data (SuperAdmin, Official Company Settings, Zones, Products)
-- =======================================================================

-- Seed SuperAdmin (Password: Password@123)
INSERT INTO users (id, email, password_hash, full_name, phone, role, permissions, is_active)
VALUES (
    'a0000000-0000-0000-0000-000000000001',
    'admin@antigravity.eg',
    '$2b$10$eprnXvVbB7z3VjG83aKkNu10FkIekxN5uW87Y2L9K6Y.XqHj8q57i',
    'المدير العام لمنظومة أنتيجرافيتي',
    '01012345678',
    'SuperAdmin',
    'orders.create,orders.dispatch,finance.settle,inventory.manage,users.manage,settings.edit',
    TRUE
)
ON CONFLICT (email) DO NOTHING;

-- Seed Official Company Payment Details
INSERT INTO company_payment_settings (
    company_name, instapay_address, vodafone_cash_number, orange_cash_number,
    etisalat_cash_number, we_pay_number, bank_name, bank_account_holder,
    bank_account_number, bank_iban, bank_swift_code, is_active
)
VALUES (
    'شركة أنتيجرافيتي إكسبريس للخدمات اللوجستية والشحن ش.م.م',
    'antigravity.logistics@instapay',
    '01012345678',
    '01212345678',
    '01112345678',
    '01512345678',
    'البنك التجاري الدولي (CIB مصر)',
    'شركة أنتيجرافيتي إكسبريس ش.م.م',
    '100045892019',
    'EG380010004589201900000000000',
    'CIBEEGCX',
    TRUE
)
ON CONFLICT DO NOTHING;

-- Seed Products
INSERT INTO products (sku, name, description, price, stock_quantity, min_stock_alert, warehouse_zone, category)
VALUES 
('ELEC-WRLS-001', 'سماعات بلوتوث لاسلكية عازلة للضوضاء ANC Pro', 'صوت عالي النقاء وبطارية ٤٠ ساعة', 1450.00, 50, 5, 'رف A12', 'إلكترونيات'),
('ELEC-SMWT-002', 'ساعة رياضية ذكية بشاشة أموليد GPS', 'تتبع اللياقة والمكالمات ونبضات القلب', 2850.00, 35, 5, 'رف B04', 'ساعات ذكية'),
('ELEC-CHRG-003', 'باور بنك سريع 20000mAh مع شحن PD 65W', 'شحن سريع للابتوب والهواتف الذكية', 1150.00, 80, 10, 'رف A14', 'شواحن وبطاريات'),
('ELEC-GAME-004', 'ذراع تحكم لاسلكي للألعاب والكمبيوتر', 'اهتزاز مزدوج واستجابة فائقة السرعة', 950.00, 45, 5, 'رف C08', 'ألعاب')
ON CONFLICT (sku) DO NOTHING;
