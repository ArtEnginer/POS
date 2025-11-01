-- ============================================
-- POS ENTERPRISE DATABASE SCHEMA - COMPLETE V4
-- PostgreSQL 16+
-- Multi-Branch + Multi-Unit + Branch-Specific Pricing
-- ============================================
-- Version: 4.0 - COMPLETE WITH MULTI-UNIT SUPPORT
-- Last Updated: 1 November 2025
-- ============================================
-- File ini berisi SEMUA schema termasuk:
-- - Basic tables (branches, users, products, dll)
-- - Multi-unit conversion (product_units)
-- - Branch-specific pricing (product_branch_prices)
-- - Sales, purchases, returns
-- - Stock management
-- ============================================

-- ============================================
-- ENABLE EXTENSIONS
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For fuzzy text search

-- ============================================
-- DROP ALL EXISTING TABLES & TYPES (Clean Start)
-- ============================================

-- Drop tables in reverse order (child tables first)
DROP TABLE IF EXISTS product_branch_prices CASCADE;
DROP TABLE IF EXISTS product_units CASCADE;
DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS sync_logs CASCADE;
DROP TABLE IF EXISTS stock_adjustments CASCADE;
DROP TABLE IF EXISTS purchase_return_items CASCADE;
DROP TABLE IF EXISTS purchase_returns CASCADE;
DROP TABLE IF EXISTS receiving_items CASCADE;
DROP TABLE IF EXISTS receivings CASCADE;
DROP TABLE IF EXISTS purchase_items CASCADE;
DROP TABLE IF EXISTS purchases CASCADE;
DROP TABLE IF EXISTS return_items CASCADE;
DROP TABLE IF EXISTS sales_returns CASCADE;
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
DROP TABLE IF EXISTS units CASCADE;

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
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS update_product_units_timestamp() CASCADE;
DROP FUNCTION IF EXISTS update_product_branch_prices_timestamp() CASCADE;

-- Drop views
DROP VIEW IF EXISTS v_product_units_prices CASCADE;
DROP VIEW IF EXISTS v_sales_profit_analysis CASCADE;
DROP VIEW IF EXISTS v_sale_items_profit CASCADE;
DROP VIEW IF EXISTS v_sales_returns_detail CASCADE;

-- ============================================
-- CUSTOM TYPES
-- ============================================

CREATE TYPE user_role AS ENUM ('super_admin', 'admin', 'manager', 'cashier', 'supervisor', 'staff');
CREATE TYPE user_status AS ENUM ('active', 'inactive', 'suspended', 'locked');
CREATE TYPE customer_type AS ENUM ('regular', 'vip', 'wholesale', 'retail');
CREATE TYPE sale_status AS ENUM ('pending', 'completed', 'cancelled', 'refunded');
CREATE TYPE payment_method AS ENUM ('cash', 'card', 'transfer', 'qris', 'other');
CREATE TYPE purchase_status AS ENUM ('pending', 'ordered', 'partially_received', 'received', 'cancelled');
CREATE TYPE receiving_status AS ENUM ('pending', 'completed', 'cancelled');
CREATE TYPE adjustment_type AS ENUM ('stock_in', 'stock_out', 'correction', 'damage', 'lost', 'transfer');
CREATE TYPE sync_operation AS ENUM ('CREATE', 'UPDATE', 'DELETE');
CREATE TYPE sync_entity_type AS ENUM ('product', 'sale', 'purchase', 'customer', 'supplier', 'other');

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

-- Insert default branch (Head Office)
INSERT INTO branches (code, name, is_head_office, api_key) 
VALUES ('HQ', 'Head Office', true, gen_random_uuid()::text);

-- ============================================
-- SECTION 2: USER MANAGEMENT
-- ============================================

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    role user_role NOT NULL,
    status user_status DEFAULT 'active',
    default_branch_id INTEGER REFERENCES branches(id),
    last_login_at TIMESTAMP,
    last_login_ip VARCHAR(45),
    login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP,
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_status ON users(status);

-- User-Branch access mapping
CREATE TABLE user_branches (
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    branch_id INTEGER REFERENCES branches(id) ON DELETE CASCADE,
    can_access BOOLEAN DEFAULT true,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, branch_id)
);

-- Insert default admin user (password: admin123)
INSERT INTO users (username, email, password_hash, full_name, role, default_branch_id) 
VALUES (
    'admin', 
    'admin@pos.com', 
    '$2a$10$YourHashedPasswordHere', -- You should hash 'admin123'
    'System Administrator', 
    'super_admin',
    1
);

-- ============================================
-- SECTION 3: PRODUCT MANAGEMENT
-- ============================================

CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    parent_id INTEGER REFERENCES categories(id),
    icon VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

CREATE INDEX idx_categories_parent ON categories(parent_id);
CREATE INDEX idx_categories_active ON categories(is_active);

-- Units Table (Global units list - Optional, for reference)
CREATE TABLE units (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

CREATE INDEX idx_units_name ON units(name);
CREATE INDEX idx_units_active ON units(is_active);

-- Insert common units
INSERT INTO units (name, description) VALUES
('PCS', 'Pieces'),
('KG', 'Kilogram'),
('GRAM', 'Gram'),
('LITER', 'Liter'),
('ML', 'Milliliter'),
('BOX', 'Box'),
('PACK', 'Pack'),
('DUS', 'Dus/Carton'),
('LUSIN', 'Dozen'),
('METER', 'Meter');

-- Products Table
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    sku VARCHAR(50) UNIQUE NOT NULL,
    barcode VARCHAR(100),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category_id INTEGER REFERENCES categories(id),
    base_unit VARCHAR(50) DEFAULT 'PCS', -- Base unit name (PCS, BOX, KG, etc.)
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
CREATE INDEX idx_products_base_unit ON products(base_unit);

-- Product Units Table (Multi-Unit Conversion)
CREATE TABLE product_units (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    unit_name VARCHAR(50) NOT NULL,
    conversion_value DECIMAL(15, 3) NOT NULL DEFAULT 1,
    is_base_unit BOOLEAN DEFAULT FALSE,
    is_purchasable BOOLEAN DEFAULT TRUE,
    is_sellable BOOLEAN DEFAULT TRUE,
    barcode VARCHAR(100),
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    CONSTRAINT unique_product_unit UNIQUE (product_id, unit_name),
    CONSTRAINT chk_conversion_positive CHECK (conversion_value > 0)
);

CREATE INDEX idx_product_units_product ON product_units(product_id);
CREATE INDEX idx_product_units_base ON product_units(product_id, is_base_unit);
CREATE INDEX idx_product_units_barcode ON product_units(barcode) WHERE barcode IS NOT NULL;
CREATE INDEX idx_product_units_active ON product_units(deleted_at) WHERE deleted_at IS NULL;

COMMENT ON TABLE product_units IS 'Unit konversi untuk multi-satuan produk. Contoh: 1 BOX = 10 PCS';
COMMENT ON COLUMN product_units.conversion_value IS 'Nilai konversi ke unit dasar. Contoh: BOX=10 berarti 1 BOX = 10 PCS';

-- Product Branch Prices Table (Branch-Specific Pricing per Unit)
CREATE TABLE product_branch_prices (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    branch_id INTEGER NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    product_unit_id INTEGER REFERENCES product_units(id) ON DELETE CASCADE,
    
    cost_price DECIMAL(15, 2) DEFAULT 0,
    selling_price DECIMAL(15, 2) NOT NULL,
    wholesale_price DECIMAL(15, 2),
    member_price DECIMAL(15, 2),
    
    margin_percentage DECIMAL(5, 2) GENERATED ALWAYS AS (
        CASE 
            WHEN cost_price > 0 AND selling_price > cost_price 
            THEN ((selling_price - cost_price) / cost_price * 100)
            ELSE 0
        END
    ) STORED,
    
    valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    CONSTRAINT unique_product_branch_unit UNIQUE (product_id, branch_id, product_unit_id),
    CONSTRAINT chk_prices_positive CHECK (cost_price >= 0 AND selling_price >= 0)
);

CREATE INDEX idx_product_branch_prices_product ON product_branch_prices(product_id);
CREATE INDEX idx_product_branch_prices_branch ON product_branch_prices(branch_id);
CREATE INDEX idx_product_branch_prices_unit ON product_branch_prices(product_unit_id);
CREATE INDEX idx_product_branch_prices_active ON product_branch_prices(is_active, deleted_at);

COMMENT ON TABLE product_branch_prices IS 'Harga beli & jual berbeda untuk setiap branch dan unit';

-- Product Stock per Branch
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
-- SECTION 4: CUSTOMER & SUPPLIER MANAGEMENT
-- ============================================

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

CREATE TABLE suppliers (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(100),
    tax_id VARCHAR(50),
    payment_terms INTEGER DEFAULT 30,
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

-- ============================================
-- SECTION 5: SALES MANAGEMENT
-- ============================================

CREATE TABLE sales (
    id SERIAL PRIMARY KEY,
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    branch_id INTEGER NOT NULL REFERENCES branches(id),
    customer_id INTEGER REFERENCES customers(id),
    cashier_id INTEGER REFERENCES users(id),
    sale_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    subtotal DECIMAL(15, 2) NOT NULL,
    tax_amount DECIMAL(15, 2) DEFAULT 0,
    discount_amount DECIMAL(15, 2) DEFAULT 0,
    rounding_amount DECIMAL(15, 2) DEFAULT 0,
    total_amount DECIMAL(15, 2) NOT NULL,
    paid_amount DECIMAL(15, 2) DEFAULT 0,
    change_amount DECIMAL(15, 2) DEFAULT 0,
    payment_method payment_method DEFAULT 'cash',
    status sale_status DEFAULT 'completed',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

CREATE INDEX idx_sales_invoice ON sales(invoice_number);
CREATE INDEX idx_sales_branch ON sales(branch_id);
CREATE INDEX idx_sales_customer ON sales(customer_id);
CREATE INDEX idx_sales_date ON sales(sale_date);
CREATE INDEX idx_sales_status ON sales(status);

CREATE TABLE sale_items (
    id SERIAL PRIMARY KEY,
    sale_id INTEGER NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id),
    product_unit_id INTEGER REFERENCES product_units(id),
    quantity DECIMAL(15, 3) NOT NULL,
    unit_price DECIMAL(15, 2) NOT NULL,
    discount_percentage DECIMAL(5, 2) DEFAULT 0,
    discount_amount DECIMAL(15, 2) DEFAULT 0,
    tax_percentage DECIMAL(5, 2) DEFAULT 0,
    tax_amount DECIMAL(15, 2) DEFAULT 0,
    subtotal DECIMAL(15, 2) NOT NULL,
    total DECIMAL(15, 2) NOT NULL,
    cost_price DECIMAL(15, 2) DEFAULT 0,
    profit DECIMAL(15, 2) GENERATED ALWAYS AS (total - (cost_price * quantity)) STORED,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sale_items_sale ON sale_items(sale_id);
CREATE INDEX idx_sale_items_product ON sale_items(product_id);

-- Sales Returns
CREATE TABLE sales_returns (
    id SERIAL PRIMARY KEY,
    return_number VARCHAR(50) UNIQUE NOT NULL,
    sale_id INTEGER REFERENCES sales(id),
    branch_id INTEGER NOT NULL REFERENCES branches(id),
    customer_id INTEGER REFERENCES customers(id),
    return_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(15, 2) NOT NULL,
    refund_method payment_method DEFAULT 'cash',
    reason TEXT,
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

CREATE INDEX idx_sales_returns_number ON sales_returns(return_number);
CREATE INDEX idx_sales_returns_sale ON sales_returns(sale_id);

CREATE TABLE return_items (
    id SERIAL PRIMARY KEY,
    return_id INTEGER NOT NULL REFERENCES sales_returns(id) ON DELETE CASCADE,
    sale_item_id INTEGER REFERENCES sale_items(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    quantity DECIMAL(15, 3) NOT NULL,
    unit_price DECIMAL(15, 2) NOT NULL,
    total DECIMAL(15, 2) NOT NULL,
    reason TEXT
);

-- ============================================
-- SECTION 6: PURCHASE MANAGEMENT
-- ============================================

CREATE TABLE purchases (
    id SERIAL PRIMARY KEY,
    purchase_number VARCHAR(50) UNIQUE NOT NULL,
    branch_id INTEGER NOT NULL REFERENCES branches(id),
    supplier_id INTEGER REFERENCES suppliers(id),
    purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expected_delivery_date TIMESTAMP,
    subtotal DECIMAL(15, 2) NOT NULL,
    tax_amount DECIMAL(15, 2) DEFAULT 0,
    discount_amount DECIMAL(15, 2) DEFAULT 0,
    total_amount DECIMAL(15, 2) NOT NULL,
    paid_amount DECIMAL(15, 2) DEFAULT 0,
    status purchase_status DEFAULT 'pending',
    notes TEXT,
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

CREATE INDEX idx_purchases_number ON purchases(purchase_number);
CREATE INDEX idx_purchases_branch ON purchases(branch_id);
CREATE INDEX idx_purchases_supplier ON purchases(supplier_id);
CREATE INDEX idx_purchases_status ON purchases(status);

CREATE TABLE purchase_items (
    id SERIAL PRIMARY KEY,
    purchase_id INTEGER NOT NULL REFERENCES purchases(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id),
    quantity_ordered DECIMAL(15, 3) NOT NULL,
    quantity_received DECIMAL(15, 3) DEFAULT 0,
    unit_price DECIMAL(15, 2) NOT NULL,
    discount_percentage DECIMAL(5, 2) DEFAULT 0,
    discount_amount DECIMAL(15, 2) DEFAULT 0,
    tax_percentage DECIMAL(5, 2) DEFAULT 0,
    tax_amount DECIMAL(15, 2) DEFAULT 0,
    total DECIMAL(15, 2) NOT NULL,
    notes TEXT
);

CREATE INDEX idx_purchase_items_purchase ON purchase_items(purchase_id);
CREATE INDEX idx_purchase_items_product ON purchase_items(product_id);

-- Receiving (Penerimaan Barang)
CREATE TABLE receivings (
    id SERIAL PRIMARY KEY,
    receiving_number VARCHAR(50) UNIQUE NOT NULL,
    purchase_id INTEGER REFERENCES purchases(id),
    branch_id INTEGER NOT NULL REFERENCES branches(id),
    receiving_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    received_by INTEGER REFERENCES users(id),
    status receiving_status DEFAULT 'completed',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

CREATE INDEX idx_receivings_number ON receivings(receiving_number);
CREATE INDEX idx_receivings_purchase ON receivings(purchase_id);

CREATE TABLE receiving_items (
    id SERIAL PRIMARY KEY,
    receiving_id INTEGER NOT NULL REFERENCES receivings(id) ON DELETE CASCADE,
    purchase_item_id INTEGER REFERENCES purchase_items(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    quantity DECIMAL(15, 3) NOT NULL,
    unit_price DECIMAL(15, 2) NOT NULL,
    notes TEXT
);

-- Purchase Returns
CREATE TABLE purchase_returns (
    id SERIAL PRIMARY KEY,
    return_number VARCHAR(50) UNIQUE NOT NULL,
    purchase_id INTEGER REFERENCES purchases(id),
    branch_id INTEGER NOT NULL REFERENCES branches(id),
    supplier_id INTEGER REFERENCES suppliers(id),
    return_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(15, 2) NOT NULL,
    reason TEXT,
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

CREATE TABLE purchase_return_items (
    id SERIAL PRIMARY KEY,
    return_id INTEGER NOT NULL REFERENCES purchase_returns(id) ON DELETE CASCADE,
    purchase_item_id INTEGER REFERENCES purchase_items(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    quantity DECIMAL(15, 3) NOT NULL,
    unit_price DECIMAL(15, 2) NOT NULL,
    total DECIMAL(15, 2) NOT NULL,
    reason TEXT
);

-- ============================================
-- SECTION 7: STOCK MANAGEMENT
-- ============================================

CREATE TABLE stock_adjustments (
    id SERIAL PRIMARY KEY,
    adjustment_number VARCHAR(50) UNIQUE NOT NULL,
    branch_id INTEGER NOT NULL REFERENCES branches(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    adjustment_type adjustment_type NOT NULL,
    quantity_before DECIMAL(15, 3) NOT NULL,
    quantity_adjusted DECIMAL(15, 3) NOT NULL,
    quantity_after DECIMAL(15, 3) NOT NULL,
    reference_number VARCHAR(100),
    reason TEXT,
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

CREATE INDEX idx_stock_adjustments_branch ON stock_adjustments(branch_id);
CREATE INDEX idx_stock_adjustments_product ON stock_adjustments(product_id);
CREATE INDEX idx_stock_adjustments_type ON stock_adjustments(adjustment_type);

-- ============================================
-- SECTION 8: SYSTEM & AUDIT
-- ============================================

CREATE TABLE cashier_settings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    branch_id INTEGER REFERENCES branches(id),
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sync_logs (
    id SERIAL PRIMARY KEY,
    entity_type sync_entity_type NOT NULL,
    entity_id VARCHAR(100),
    operation sync_operation NOT NULL,
    branch_id INTEGER REFERENCES branches(id),
    user_id INTEGER REFERENCES users(id),
    status VARCHAR(20) DEFAULT 'pending',
    sync_data JSONB,
    error_message TEXT,
    synced_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sync_logs_entity ON sync_logs(entity_type, entity_id);
CREATE INDEX idx_sync_logs_status ON sync_logs(status);

CREATE TABLE audit_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id VARCHAR(100),
    old_values JSONB,
    new_values JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at);

-- ============================================
-- TRIGGERS & FUNCTIONS
-- ============================================

-- Generic updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
CREATE TRIGGER update_branches_updated_at BEFORE UPDATE ON branches
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_product_units_updated_at BEFORE UPDATE ON product_units
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_product_branch_prices_updated_at BEFORE UPDATE ON product_branch_prices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_product_stocks_updated_at BEFORE UPDATE ON product_stocks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_suppliers_updated_at BEFORE UPDATE ON suppliers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_sales_updated_at BEFORE UPDATE ON sales
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_purchases_updated_at BEFORE UPDATE ON purchases
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- HELPFUL VIEWS
-- ============================================

-- View: Product dengan semua units dan harga per branch
CREATE OR REPLACE VIEW v_product_units_prices AS
SELECT 
    p.id as product_id,
    p.sku,
    p.barcode as product_barcode,
    p.name as product_name,
    p.category_id,
    c.name as category_name,
    
    pu.id as unit_id,
    pu.unit_name,
    pu.conversion_value,
    pu.is_base_unit,
    pu.is_purchasable,
    pu.is_sellable,
    pu.barcode as unit_barcode,
    pu.sort_order,
    
    b.id as branch_id,
    b.code as branch_code,
    b.name as branch_name,
    
    pbp.id as price_id,
    pbp.cost_price,
    pbp.selling_price,
    pbp.wholesale_price,
    pbp.member_price,
    pbp.margin_percentage,
    pbp.is_active as price_is_active,
    
    COALESCE(ps.quantity, 0) as stock_base_unit,
    CASE 
        WHEN pu.conversion_value > 0 
        THEN COALESCE(ps.quantity, 0) / pu.conversion_value
        ELSE 0
    END as stock_in_unit,
    
    p.is_active as product_is_active
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
LEFT JOIN product_units pu ON p.id = pu.product_id AND pu.deleted_at IS NULL
LEFT JOIN product_branch_prices pbp ON p.id = pbp.product_id 
    AND pbp.product_unit_id = pu.id 
    AND pbp.deleted_at IS NULL
LEFT JOIN branches b ON pbp.branch_id = b.id AND b.deleted_at IS NULL
LEFT JOIN product_stocks ps ON p.id = ps.product_id AND ps.branch_id = b.id
WHERE p.deleted_at IS NULL
ORDER BY p.id, pu.sort_order, b.name;

-- ============================================
-- COMPLETE SCHEMA INSTALLED
-- ============================================

SELECT '✅ Complete Schema V4 Installed Successfully!' as status;
SELECT 'Includes: Multi-Unit Support + Branch-Specific Pricing' as features;
