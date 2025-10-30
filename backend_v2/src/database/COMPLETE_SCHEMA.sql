-- ============================================
-- POS ENTERPRISE DATABASE SCHEMA - COMPLETE
-- PostgreSQL 16+
-- Multi-Branch Support
-- DENGAN QUANTITY SUPPORT DECIMAL (Mendukung pecahan: 1.5, 2.75, dll)
-- ============================================
-- Version: 2.0
-- Last Updated: 28 Oktober 2025
-- ============================================

-- ============================================
-- STEP 1: DROP EXISTING DATABASE (OPTIONAL - HATI-HATI!)
-- ============================================
-- Uncomment baris di bawah jika ingin reset total
-- DROP DATABASE IF EXISTS pos_enterprise;
-- CREATE DATABASE pos_enterprise;

-- ============================================
-- STEP 2: ENABLE EXTENSIONS
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For fuzzy text search

-- ============================================
-- STEP 3: DROP ALL EXISTING TABLES & TYPES (Clean Start)
-- ============================================

-- Drop tables in reverse order (child tables first)
DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS sync_logs CASCADE;
DROP TABLE IF EXISTS stock_adjustments CASCADE;
DROP TABLE IF EXISTS purchase_return_items CASCADE;
DROP TABLE IF EXISTS purchase_returns CASCADE;
DROP TABLE IF EXISTS receiving_items CASCADE;
DROP TABLE IF EXISTS receivings CASCADE;
DROP TABLE IF EXISTS purchase_items CASCADE;
DROP TABLE IF EXISTS purchases CASCADE;
DROP TABLE IF EXISTS sale_items CASCADE;
DROP TABLE IF EXISTS sales CASCADE;
DROP TABLE IF EXISTS product_stocks CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS suppliers CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS cashier_settings CASCADE;
DROP TABLE IF EXISTS user_branches CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS branches CASCADE;

-- Drop custom types
DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS user_status CASCADE;
DROP TYPE IF EXISTS customer_type CASCADE;
DROP TYPE IF EXISTS sale_status CASCADE;
DROP TYPE IF EXISTS payment_method CASCADE;
DROP TYPE IF EXISTS purchase_status CASCADE;
DROP TYPE IF EXISTS receiving_status CASCADE;
DROP TYPE IF EXISTS adjustment_type CASCADE;
DROP TYPE IF EXISTS sync_operation CASCADE;
DROP TYPE IF EXISTS sync_entity_type CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS update_updated_at() CASCADE;
DROP FUNCTION IF EXISTS update_stock_on_sale() CASCADE;
DROP FUNCTION IF EXISTS calculate_sale_totals() CASCADE;

-- ============================================
-- SECTION 1: BRANCH MANAGEMENT
-- ============================================

CREATE TABLE branches (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    address TEXT,
    city VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    is_head_office BOOLEAN DEFAULT false,
    api_key VARCHAR(64) UNIQUE NOT NULL,
    timezone VARCHAR(50) DEFAULT 'Asia/Jakarta',
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

CREATE INDEX idx_branches_code ON branches(code);
CREATE INDEX idx_branches_active ON branches(is_active);
CREATE INDEX idx_branches_api_key ON branches(api_key);

-- ============================================
-- SECTION 2: USER MANAGEMENT
-- ============================================

CREATE TYPE user_role AS ENUM ('super_admin', 'admin', 'manager', 'cashier', 'staff');
CREATE TYPE user_status AS ENUM ('active', 'inactive', 'suspended');

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role user_role DEFAULT 'cashier',
    status user_status DEFAULT 'active',
    phone VARCHAR(20),
    avatar_url TEXT,
    last_login_at TIMESTAMP,
    last_login_ip INET,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_status ON users(status);

-- User-Branch mapping (many-to-many)
CREATE TABLE user_branches (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    branch_id INTEGER NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, branch_id)
);

CREATE INDEX idx_user_branches_user ON user_branches(user_id);
CREATE INDEX idx_user_branches_branch ON user_branches(branch_id);

-- Cashier Settings (Device & Location Configuration)
CREATE TABLE cashier_settings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    branch_id INTEGER NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    
    -- Device Information
    device_name VARCHAR(100) NOT NULL DEFAULT 'Kasir-1',
    device_type VARCHAR(50) DEFAULT 'windows',
    device_identifier VARCHAR(255),
    
    -- Location Information
    cashier_location VARCHAR(255),
    counter_number VARCHAR(20),
    floor_level VARCHAR(20),
    
    -- Display & UI Settings
    receipt_printer VARCHAR(255),
    cash_drawer_port VARCHAR(50),
    display_type VARCHAR(50) DEFAULT 'standard',
    theme_preference VARCHAR(50) DEFAULT 'light',
    
    -- Operational Settings
    is_active BOOLEAN DEFAULT true,
    allow_offline_mode BOOLEAN DEFAULT true,
    auto_print_receipt BOOLEAN DEFAULT true,
    require_customer_display BOOLEAN DEFAULT false,
    
    -- Additional Settings (JSON for flexibility)
    settings JSONB DEFAULT '{}',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, branch_id)
);

CREATE INDEX idx_cashier_settings_user ON cashier_settings(user_id);
CREATE INDEX idx_cashier_settings_branch ON cashier_settings(branch_id);
CREATE INDEX idx_cashier_settings_active ON cashier_settings(is_active);

-- ============================================
-- SECTION 3: PRODUCT MANAGEMENT
-- ============================================

CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    parent_id INTEGER REFERENCES categories(id),
    icon VARCHAR(50),
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

CREATE INDEX idx_categories_parent ON categories(parent_id);
CREATE INDEX idx_categories_active ON categories(is_active);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    sku VARCHAR(50) UNIQUE NOT NULL,
    barcode VARCHAR(100),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category_id INTEGER REFERENCES categories(id),
    unit VARCHAR(50) DEFAULT 'PCS',
    cost_price DECIMAL(15, 2) DEFAULT 0,
    selling_price DECIMAL(15, 2) NOT NULL,
    min_stock DECIMAL(15, 3) DEFAULT 0,
    max_stock DECIMAL(15, 3) DEFAULT 0,
    reorder_point DECIMAL(15, 3) DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    is_trackable BOOLEAN DEFAULT true,
    image_url TEXT,
    attributes JSONB DEFAULT '{}',
    tax_rate DECIMAL(5, 2) DEFAULT 0,
    discount_percentage DECIMAL(5, 2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_barcode ON products(barcode);
CREATE INDEX idx_products_name ON products USING gin (name gin_trgm_ops);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_active ON products(is_active);

-- Product stock per branch (DENGAN DECIMAL UNTUK QUANTITY)
CREATE TABLE product_stocks (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    branch_id INTEGER NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    quantity DECIMAL(15, 3) DEFAULT 0,
    reserved_quantity DECIMAL(15, 3) DEFAULT 0,
    available_quantity DECIMAL(15, 3) GENERATED ALWAYS AS (quantity - reserved_quantity) STORED,
    last_stock_count_at TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(product_id, branch_id)
);

CREATE INDEX idx_product_stocks_product ON product_stocks(product_id);
CREATE INDEX idx_product_stocks_branch ON product_stocks(branch_id);
CREATE INDEX idx_product_stocks_available ON product_stocks(available_quantity);

-- ============================================
-- SECTION 4: CUSTOMER MANAGEMENT
-- ============================================

CREATE TYPE customer_type AS ENUM ('regular', 'vip', 'wholesale', 'retail');

CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(100),
    customer_type customer_type DEFAULT 'regular',
    tax_id VARCHAR(50),
    credit_limit DECIMAL(15, 2) DEFAULT 0,
    current_balance DECIMAL(15, 2) DEFAULT 0,
    total_purchases DECIMAL(15, 2) DEFAULT 0,
    total_points INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

CREATE INDEX idx_customers_code ON customers(code);
CREATE INDEX idx_customers_name ON customers USING gin (name gin_trgm_ops);
CREATE INDEX idx_customers_phone ON customers(phone);
CREATE INDEX idx_customers_type ON customers(customer_type);
CREATE INDEX idx_customers_active ON customers(is_active);

-- ============================================
-- SECTION 5: SUPPLIER MANAGEMENT
-- ============================================

CREATE TABLE suppliers (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(100),
    tax_id VARCHAR(50),
    payment_terms VARCHAR(100),
    credit_limit DECIMAL(15, 2) DEFAULT 0,
    current_balance DECIMAL(15, 2) DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

CREATE INDEX idx_suppliers_code ON suppliers(code);
CREATE INDEX idx_suppliers_name ON suppliers USING gin (name gin_trgm_ops);
CREATE INDEX idx_suppliers_active ON suppliers(is_active);

-- ============================================
-- SECTION 6: SALES TRANSACTIONS
-- ============================================

CREATE TYPE sale_status AS ENUM ('pending', 'completed', 'cancelled', 'refunded');
CREATE TYPE payment_method AS ENUM ('cash', 'card', 'transfer', 'ewallet', 'credit');

CREATE TABLE sales (
    id BIGSERIAL PRIMARY KEY,
    sale_number VARCHAR(50) UNIQUE NOT NULL,
    branch_id INTEGER NOT NULL REFERENCES branches(id),
    customer_id INTEGER REFERENCES customers(id),
    cashier_id INTEGER NOT NULL REFERENCES users(id),
    sale_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status sale_status DEFAULT 'completed',
    
    subtotal DECIMAL(15, 2) NOT NULL,
    discount_amount DECIMAL(15, 2) DEFAULT 0,
    discount_percentage DECIMAL(5, 2) DEFAULT 0,
    tax_amount DECIMAL(15, 2) DEFAULT 0,
    total_amount DECIMAL(15, 2) NOT NULL,
    paid_amount DECIMAL(15, 2) DEFAULT 0,
    change_amount DECIMAL(15, 2) DEFAULT 0,
    
    -- Cost & Profit Tracking
    total_cost DECIMAL(15, 2) DEFAULT 0,
    gross_profit DECIMAL(15, 2) DEFAULT 0,
    profit_margin DECIMAL(5, 2) DEFAULT 0,
    
    payment_method payment_method NOT NULL,
    payment_reference VARCHAR(100),
    
    -- Cashier & Location Info
    cashier_location VARCHAR(255),
    device_info JSONB,
    
    notes TEXT,
    metadata JSONB DEFAULT '{}',
    
    synced_at TIMESTAMP,
    sync_status VARCHAR(20) DEFAULT 'pending',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

CREATE INDEX idx_sales_number ON sales(sale_number);
CREATE INDEX idx_sales_branch ON sales(branch_id);
CREATE INDEX idx_sales_customer ON sales(customer_id);
CREATE INDEX idx_sales_cashier ON sales(cashier_id);
CREATE INDEX idx_sales_date ON sales(sale_date);
CREATE INDEX idx_sales_status ON sales(status);
CREATE INDEX idx_sales_sync ON sales(sync_status);

CREATE TABLE sale_items (
    id BIGSERIAL PRIMARY KEY,
    sale_id BIGINT NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    branch_id INTEGER NOT NULL REFERENCES branches(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    product_name VARCHAR(255) NOT NULL,
    sku VARCHAR(50) NOT NULL,
    quantity DECIMAL(15, 3) NOT NULL,
    unit_price DECIMAL(15, 2) NOT NULL,
    discount_amount DECIMAL(15, 2) DEFAULT 0,
    discount_percentage DECIMAL(5, 2) DEFAULT 0,
    tax_amount DECIMAL(15, 2) DEFAULT 0,
    subtotal DECIMAL(15, 2) NOT NULL,
    total DECIMAL(15, 2) NOT NULL,
    
    -- Cost & Profit Tracking (Snapshot at transaction time)
    cost_price DECIMAL(15, 2),
    total_cost DECIMAL(15, 2) GENERATED ALWAYS AS (cost_price * quantity) STORED,
    item_profit DECIMAL(15, 2) GENERATED ALWAYS AS (total - (cost_price * quantity)) STORED,
    
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sale_items_sale ON sale_items(sale_id);
CREATE INDEX idx_sale_items_branch ON sale_items(branch_id);
CREATE INDEX idx_sale_items_product ON sale_items(product_id);

-- ============================================
-- SECTION 7: PURCHASE TRANSACTIONS
-- ============================================

CREATE TYPE purchase_status AS ENUM ('draft', 'ordered', 'approved', 'partial', 'received', 'cancelled');

CREATE TABLE purchases (
    id BIGSERIAL PRIMARY KEY,
    purchase_number VARCHAR(50) UNIQUE NOT NULL,
    branch_id INTEGER NOT NULL REFERENCES branches(id),
    supplier_id INTEGER REFERENCES suppliers(id),
    created_by INTEGER NOT NULL REFERENCES users(id),
    purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expected_date DATE,
    status purchase_status DEFAULT 'draft',
    
    subtotal DECIMAL(15, 2) NOT NULL,
    discount_amount DECIMAL(15, 2) DEFAULT 0,
    tax_amount DECIMAL(15, 2) DEFAULT 0,
    shipping_cost DECIMAL(15, 2) DEFAULT 0,
    total_amount DECIMAL(15, 2) NOT NULL,
    paid_amount DECIMAL(15, 2) DEFAULT 0,
    
    payment_terms VARCHAR(100),
    payment_method payment_method,
    
    notes TEXT,
    metadata JSONB DEFAULT '{}',
    
    synced_at TIMESTAMP,
    sync_status VARCHAR(20) DEFAULT 'pending',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

CREATE INDEX idx_purchases_number ON purchases(purchase_number);
CREATE INDEX idx_purchases_branch ON purchases(branch_id);
CREATE INDEX idx_purchases_supplier ON purchases(supplier_id);
CREATE INDEX idx_purchases_date ON purchases(purchase_date);
CREATE INDEX idx_purchases_status ON purchases(status);

CREATE TABLE purchase_items (
    id BIGSERIAL PRIMARY KEY,
    purchase_id BIGINT NOT NULL REFERENCES purchases(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id),
    product_name VARCHAR(255) NOT NULL,
    sku VARCHAR(50) NOT NULL,
    quantity_ordered DECIMAL(15, 3) NOT NULL,
    quantity_received DECIMAL(15, 3) DEFAULT 0,
    unit_price DECIMAL(15, 2) NOT NULL,
    discount_amount DECIMAL(15, 2) DEFAULT 0,
    tax_amount DECIMAL(15, 2) DEFAULT 0,
    subtotal DECIMAL(15, 2) NOT NULL,
    total DECIMAL(15, 2) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_purchase_items_purchase ON purchase_items(purchase_id);
CREATE INDEX idx_purchase_items_product ON purchase_items(product_id);

-- ============================================
-- SECTION 8: RECEIVING (PENERIMAAN BARANG)
-- ============================================

CREATE TYPE receiving_status AS ENUM ('completed', 'partial', 'cancelled');

CREATE TABLE receivings (
    id BIGSERIAL PRIMARY KEY,
    receiving_number VARCHAR(50) UNIQUE NOT NULL,
    purchase_id BIGINT NOT NULL REFERENCES purchases(id),
    purchase_number VARCHAR(50) NOT NULL,
    supplier_id INTEGER REFERENCES suppliers(id),
    supplier_name VARCHAR(255),
    receiving_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Delivery Information
    invoice_number VARCHAR(100),
    delivery_order_number VARCHAR(100),
    vehicle_number VARCHAR(50),
    driver_name VARCHAR(255),
    
    -- Financial Summary
    subtotal DECIMAL(15, 2) NOT NULL,
    item_discount DECIMAL(15, 2) DEFAULT 0,
    item_tax DECIMAL(15, 2) DEFAULT 0,
    total_discount DECIMAL(15, 2) DEFAULT 0,
    total_tax DECIMAL(15, 2) DEFAULT 0,
    total DECIMAL(15, 2) NOT NULL,
    
    status receiving_status DEFAULT 'completed',
    notes TEXT,
    received_by INTEGER REFERENCES users(id),
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    synced_at TIMESTAMP,
    sync_status VARCHAR(20) DEFAULT 'pending',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

CREATE INDEX idx_receivings_number ON receivings(receiving_number);
CREATE INDEX idx_receivings_purchase ON receivings(purchase_id);
CREATE INDEX idx_receivings_supplier ON receivings(supplier_id);
CREATE INDEX idx_receivings_date ON receivings(receiving_date);
CREATE INDEX idx_receivings_status ON receivings(status);

CREATE TABLE receiving_items (
    id BIGSERIAL PRIMARY KEY,
    receiving_id BIGINT NOT NULL REFERENCES receivings(id) ON DELETE CASCADE,
    purchase_item_id BIGINT REFERENCES purchase_items(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    product_name VARCHAR(255) NOT NULL,
    
    -- PO Reference
    po_quantity DECIMAL(15, 3) DEFAULT 0,
    po_price DECIMAL(15, 2) DEFAULT 0,
    
    -- Received Data
    received_quantity DECIMAL(15, 3) NOT NULL,
    received_price DECIMAL(15, 2) NOT NULL,
    
    -- Discount & Tax per item
    discount DECIMAL(15, 2) DEFAULT 0,
    discount_type VARCHAR(20) DEFAULT 'AMOUNT', -- AMOUNT or PERCENTAGE
    tax DECIMAL(15, 2) DEFAULT 0,
    tax_type VARCHAR(20) DEFAULT 'AMOUNT', -- AMOUNT or PERCENTAGE
    
    subtotal DECIMAL(15, 2) NOT NULL,
    total DECIMAL(15, 2) NOT NULL,
    notes TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_receiving_items_receiving ON receiving_items(receiving_id);
CREATE INDEX idx_receiving_items_product ON receiving_items(product_id);

-- ============================================
-- SECTION 9: PURCHASE RETURNS
-- ============================================

CREATE TABLE purchase_returns (
    id BIGSERIAL PRIMARY KEY,
    return_number VARCHAR(50) UNIQUE NOT NULL,
    receiving_id BIGINT NOT NULL REFERENCES receivings(id),
    purchase_id BIGINT NOT NULL REFERENCES purchases(id),
    supplier_id INTEGER REFERENCES suppliers(id),
    return_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    subtotal DECIMAL(15, 2) NOT NULL,
    total_discount DECIMAL(15, 2) DEFAULT 0,
    total_tax DECIMAL(15, 2) DEFAULT 0,
    total DECIMAL(15, 2) NOT NULL,
    
    status VARCHAR(20) DEFAULT 'DRAFT',
    reason TEXT,
    notes TEXT,
    returned_by INTEGER REFERENCES users(id),
    
    metadata JSONB DEFAULT '{}',
    synced_at TIMESTAMP,
    sync_status VARCHAR(20) DEFAULT 'pending',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_purchase_returns_number ON purchase_returns(return_number);
CREATE INDEX idx_purchase_returns_receiving ON purchase_returns(receiving_id);
CREATE INDEX idx_purchase_returns_purchase ON purchase_returns(purchase_id);
CREATE INDEX idx_purchase_returns_supplier ON purchase_returns(supplier_id);

CREATE TABLE purchase_return_items (
    id BIGSERIAL PRIMARY KEY,
    return_id BIGINT NOT NULL REFERENCES purchase_returns(id) ON DELETE CASCADE,
    receiving_item_id BIGINT NOT NULL REFERENCES receiving_items(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    product_name VARCHAR(255) NOT NULL,
    
    received_quantity DECIMAL(15, 3) NOT NULL,
    return_quantity DECIMAL(15, 3) NOT NULL,
    price DECIMAL(15, 2) NOT NULL,
    
    discount DECIMAL(15, 2) DEFAULT 0,
    discount_type VARCHAR(20) DEFAULT 'AMOUNT',
    tax DECIMAL(15, 2) DEFAULT 0,
    tax_type VARCHAR(20) DEFAULT 'AMOUNT',
    
    subtotal DECIMAL(15, 2) NOT NULL,
    total DECIMAL(15, 2) NOT NULL,
    reason TEXT,
    notes TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_purchase_return_items_return ON purchase_return_items(return_id);
CREATE INDEX idx_purchase_return_items_product ON purchase_return_items(product_id);

-- ============================================
-- SECTION 10: INVENTORY ADJUSTMENTS
-- ============================================

CREATE TYPE adjustment_type AS ENUM ('increase', 'decrease', 'transfer', 'damage', 'lost', 'found');

CREATE TABLE stock_adjustments (
    id BIGSERIAL PRIMARY KEY,
    adjustment_number VARCHAR(50) UNIQUE NOT NULL,
    branch_id INTEGER NOT NULL REFERENCES branches(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    adjustment_type adjustment_type NOT NULL,
    quantity DECIMAL(15, 3) NOT NULL,
    previous_quantity DECIMAL(15, 3) NOT NULL,
    new_quantity DECIMAL(15, 3) NOT NULL,
    cost_impact DECIMAL(15, 2) DEFAULT 0,
    reason TEXT,
    approved_by INTEGER REFERENCES users(id),
    created_by INTEGER NOT NULL REFERENCES users(id),
    adjustment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_stock_adjustments_branch ON stock_adjustments(branch_id);
CREATE INDEX idx_stock_adjustments_product ON stock_adjustments(product_id);
CREATE INDEX idx_stock_adjustments_date ON stock_adjustments(adjustment_date);

-- ============================================
-- SECTION 11: SYNC LOG
-- ============================================

CREATE TYPE sync_operation AS ENUM ('create', 'update', 'delete');
CREATE TYPE sync_entity_type AS ENUM ('product', 'customer', 'supplier', 'sale', 'purchase', 'stock');

CREATE TABLE sync_logs (
    id BIGSERIAL PRIMARY KEY,
    branch_id INTEGER NOT NULL REFERENCES branches(id),
    entity_type sync_entity_type NOT NULL,
    entity_id BIGINT NOT NULL,
    operation sync_operation NOT NULL,
    data JSONB,
    sync_status VARCHAR(20) DEFAULT 'pending',
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    synced_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sync_logs_branch ON sync_logs(branch_id);
CREATE INDEX idx_sync_logs_entity ON sync_logs(entity_type, entity_id);
CREATE INDEX idx_sync_logs_status ON sync_logs(sync_status);
CREATE INDEX idx_sync_logs_date ON sync_logs(created_at);

-- ============================================
-- SECTION 12: AUDIT LOG
-- ============================================

CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    branch_id INTEGER REFERENCES branches(id),
    action VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id BIGINT,
    old_data JSONB,
    new_data JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_branch ON audit_logs(branch_id);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_date ON audit_logs(created_at);

-- ============================================
-- SECTION 13: FUNCTIONS & TRIGGERS
-- ============================================

-- Update timestamp function
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update timestamp trigger to all tables
CREATE TRIGGER update_branches_timestamp BEFORE UPDATE ON branches FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_users_timestamp BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_cashier_settings_timestamp BEFORE UPDATE ON cashier_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_products_timestamp BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_customers_timestamp BEFORE UPDATE ON customers FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_suppliers_timestamp BEFORE UPDATE ON suppliers FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_sales_timestamp BEFORE UPDATE ON sales FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_purchases_timestamp BEFORE UPDATE ON purchases FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_receivings_timestamp BEFORE UPDATE ON receivings FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Auto-calculate sale profit totals
CREATE OR REPLACE FUNCTION calculate_sale_totals()
RETURNS TRIGGER AS $$
DECLARE
    v_total_cost DECIMAL(15, 2);
    v_total_amount DECIMAL(15, 2);
    v_gross_profit DECIMAL(15, 2);
    v_profit_margin DECIMAL(5, 2);
BEGIN
    -- Calculate totals from sale_items
    SELECT 
        COALESCE(SUM(total_cost), 0),
        COALESCE(SUM(total), 0)
    INTO v_total_cost, v_total_amount
    FROM sale_items
    WHERE sale_id = NEW.sale_id;
    
    -- Calculate profit
    v_gross_profit := v_total_amount - v_total_cost;
    
    -- Calculate profit margin (avoid division by zero)
    IF v_total_amount > 0 THEN
        v_profit_margin := (v_gross_profit / v_total_amount) * 100;
    ELSE
        v_profit_margin := 0;
    END IF;
    
    -- Update sales table
    UPDATE sales
    SET 
        total_cost = v_total_cost,
        gross_profit = v_gross_profit,
        profit_margin = v_profit_margin
    WHERE id = NEW.sale_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calculate_sale_totals
AFTER INSERT OR UPDATE ON sale_items
FOR EACH ROW
EXECUTE FUNCTION calculate_sale_totals();

-- Auto-update product stock when sale is created
CREATE OR REPLACE FUNCTION update_stock_on_sale()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' THEN
        UPDATE product_stocks
        SET quantity = quantity - (
            SELECT COALESCE(SUM(quantity), 0)
            FROM sale_items
            WHERE sale_id = NEW.id AND product_id = product_stocks.product_id
        )
        WHERE branch_id = NEW.branch_id
        AND product_id IN (SELECT product_id FROM sale_items WHERE sale_id = NEW.id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_stock_on_sale
AFTER INSERT OR UPDATE ON sales
FOR EACH ROW
EXECUTE FUNCTION update_stock_on_sale();

-- ============================================
-- SECTION 14: VIEWS FOR REPORTING
-- ============================================

-- Sales Profit Analysis View
CREATE OR REPLACE VIEW v_sales_profit_analysis AS
SELECT 
    s.id,
    s.sale_number,
    s.sale_date,
    b.name as branch_name,
    u.full_name as cashier_name,
    c.name as customer_name,
    s.subtotal,
    s.discount_amount,
    s.tax_amount,
    s.total_amount,
    s.total_cost,
    s.gross_profit,
    s.profit_margin,
    s.cashier_location,
    s.device_info,
    s.payment_method,
    s.status,
    COUNT(si.id) as total_items,
    SUM(si.quantity) as total_quantity
FROM sales s
LEFT JOIN branches b ON s.branch_id = b.id
LEFT JOIN users u ON s.cashier_id = u.id
LEFT JOIN customers c ON s.customer_id = c.id
LEFT JOIN sale_items si ON s.id = si.sale_id
GROUP BY s.id, b.name, u.full_name, c.name;

-- Sale Items with Profit Detail View
CREATE OR REPLACE VIEW v_sale_items_profit AS
SELECT 
    si.id,
    si.sale_id,
    s.sale_number,
    s.sale_date,
    b.name as branch_name,
    si.product_id,
    si.product_name,
    si.sku,
    si.quantity,
    si.unit_price,
    si.cost_price,
    si.total_cost,
    si.total,
    si.item_profit,
    CASE 
        WHEN si.total > 0 THEN ((si.item_profit / si.total) * 100)
        ELSE 0
    END as item_profit_margin
FROM sale_items si
JOIN sales s ON si.sale_id = s.id
JOIN branches b ON si.branch_id = b.id;

-- ============================================
-- SECTION 15: INITIAL DATA
-- ============================================

-- Default super admin user (password: admin123)
INSERT INTO users (username, email, password_hash, full_name, role, status)
VALUES ('admin', 'admin@pos.com', '$2a$10$rG7QVqvN8z3V.gFZ8yQrB.vH9p7zLVXQx6F7ij9jZJU9YW7KJt5.a', 'System Administrator', 'super_admin', 'active')
ON CONFLICT (username) DO NOTHING;

-- Default head office branch
INSERT INTO branches (code, name, is_head_office, api_key)
VALUES ('HQ', 'Head Office', true, uuid_generate_v4()::text)
ON CONFLICT (code) DO NOTHING;

-- Default category
INSERT INTO categories (name, description)
VALUES ('General', 'General products')
ON CONFLICT DO NOTHING;

-- Assign admin to head office
INSERT INTO user_branches (user_id, branch_id, is_default)
SELECT u.id, b.id, true
FROM users u, branches b
WHERE u.username = 'admin' AND b.code = 'HQ'
ON CONFLICT (user_id, branch_id) DO NOTHING;

-- Default cashier settings for admin
INSERT INTO cashier_settings (user_id, branch_id, device_name, cashier_location, counter_number)
SELECT u.id, b.id, 'Kasir-Admin', 'Head Office', '1'
FROM users u, branches b
WHERE u.username = 'admin' AND b.code = 'HQ'
ON CONFLICT (user_id, branch_id) DO NOTHING;

-- ============================================
-- COMPLETE! DATABASE READY TO USE
-- ============================================

SELECT '✅ Database schema created successfully!' as status;
SELECT '✅ QUANTITY Support: DECIMAL(15, 3) - Mendukung pecahan (1.5, 2.75, dll)' as feature;
SELECT '✅ COST & PROFIT Tracking: Auto-calculate profit per item & per sale' as feature2;
SELECT '✅ CASHIER Settings: Device name, location, counter tracking' as feature3;
SELECT 'Username: admin | Password: admin123' as credentials;
SELECT 'Total Tables: ' || COUNT(*) || ' tables created' as summary
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
