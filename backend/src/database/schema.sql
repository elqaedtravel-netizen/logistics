-- PostgreSQL Normalized Schema for Enterprise Logistics & E-Commerce Platform
-- Author: Antigravity Multi-Agent Development Team

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enum Types
DO $$ BEGIN
    CREATE TYPE user_role_enum AS ENUM ('ADMIN', 'DISPATCHER', 'DRIVER', 'CUSTOMER');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE order_status_enum AS ENUM (
        'Pending',
        'In_Warehouse',
        'Dispatched_to_Driver',
        'Delivered',
        'Postponed',
        'Canceled',
        'Returned'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_method_enum AS ENUM (
        'CASH_ON_DELIVERY',
        'PAYMOB_CARD',
        'PAYMOB_WALLET',
        'PAYMOB_MEEZA'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_status_enum AS ENUM (
        'UNPAID',
        'PENDING',
        'PAID',
        'FAILED',
        'REFUNDED'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE postponement_reason_enum AS ENUM (
        'CUSTOMER_UNREACHABLE',
        'CUSTOMER_REQUESTED_RESCHEDULE',
        'CUSTOMER_REFUSED_DELIVERY_TEMPORARILY',
        'INCORRECT_ADDRESS',
        'OUT_OF_ROUTE_TIME',
        'WEATHER_OR_ROAD_BLOCKAGE',
        'VEHICLE_BREAKDOWN',
        'CASH_NOT_AVAILABLE',
        'OTHER'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE ledger_transaction_type_enum AS ENUM (
        'CASH_COLLECTED',
        'COMMISSION_EARNED',
        'SETTLEMENT_PAYOUT',
        'ADJUSTMENT'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Users Table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    firebase_uid VARCHAR(255) UNIQUE,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    role user_role_enum NOT NULL DEFAULT 'CUSTOMER',
    is_active BOOLEAN NOT NULL DEFAULT true,
    commission_rate NUMERIC(5, 2) NOT NULL DEFAULT 10.00,
    fcm_token TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Products & Inventory Table
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sku VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price NUMERIC(12, 2) NOT NULL,
    cost_price NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    stock_quantity INT NOT NULL DEFAULT 0,
    warehouse_location VARCHAR(100) NOT NULL DEFAULT 'Warehouse-Cairo-Main',
    barcode_qr_data TEXT,
    image_url TEXT,
    category VARCHAR(100) NOT NULL DEFAULT 'General',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_products_sku ON products(sku);

-- Orders Table
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id UUID REFERENCES users(id) ON DELETE SET NULL,
    customer_name VARCHAR(255) NOT NULL,
    customer_phone VARCHAR(50) NOT NULL,
    shipping_address TEXT NOT NULL,
    city VARCHAR(100) NOT NULL DEFAULT 'Cairo',
    geo_lat NUMERIC(10, 7),
    geo_lng NUMERIC(10, 7),
    status order_status_enum NOT NULL DEFAULT 'Pending',
    payment_method payment_method_enum NOT NULL DEFAULT 'CASH_ON_DELIVERY',
    payment_status payment_status_enum NOT NULL DEFAULT 'UNPAID',
    subtotal NUMERIC(12, 2) NOT NULL,
    shipping_fee NUMERIC(12, 2) NOT NULL DEFAULT 50.00,
    total_amount NUMERIC(12, 2) NOT NULL,
    assigned_driver_id UUID REFERENCES users(id) ON DELETE SET NULL,
    scheduled_delivery_date TIMESTAMPTZ,
    postponement_reason postponement_reason_enum,
    postponement_notes TEXT,
    waybill_qr_code TEXT,
    delivered_at TIMESTAMPTZ,
    delivery_signature_url TEXT,
    delivery_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_orders_order_number ON orders(order_number);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_driver ON orders(assigned_driver_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id);

-- Order Items Table
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    product_name VARCHAR(255) NOT NULL,
    product_sku VARCHAR(100) NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12, 2) NOT NULL,
    total_price NUMERIC(12, 2) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);

-- Order Tracking History Table
CREATE TABLE IF NOT EXISTS order_tracking_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    previous_status order_status_enum,
    new_status order_status_enum NOT NULL,
    changed_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    driver_id UUID REFERENCES users(id) ON DELETE SET NULL,
    notes TEXT,
    reason_code VARCHAR(100),
    location_lat NUMERIC(10, 7),
    location_lng NUMERIC(10, 7),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tracking_order_id ON order_tracking_history(order_id);

-- Driver Ledgers Table
CREATE TABLE IF NOT EXISTS driver_ledgers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
    transaction_type ledger_transaction_type_enum NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    running_balance NUMERIC(12, 2) NOT NULL,
    description TEXT NOT NULL,
    reference_code VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_driver_ledgers_driver_id ON driver_ledgers(driver_id);
CREATE INDEX IF NOT EXISTS idx_driver_ledgers_order_id ON driver_ledgers(order_id);

-- Payment Transactions Table (Paymob Gateway)
CREATE TABLE IF NOT EXISTS payment_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    paymob_order_id VARCHAR(100),
    paymob_transaction_id VARCHAR(100) UNIQUE,
    amount_cents BIGINT NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'EGP',
    payment_method payment_method_enum NOT NULL,
    status payment_status_enum NOT NULL DEFAULT 'PENDING',
    hmac_validated BOOLEAN NOT NULL DEFAULT false,
    raw_payload JSONB,
    failure_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_order ON payment_transactions(order_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_paymob_order ON payment_transactions(paymob_order_id);
