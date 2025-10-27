-- ============================================
-- POS ENTERPRISE DATABASE SCHEMA
-- PostgreSQL 16+
-- Multi-Branch Support
-- ============================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For fuzzy text search

-- ============================================
-- 1. BRANCH MANAGEMENT
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
-- 2. USER MANAGEMENT
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

-- ============================================
-- 3. PRODUCT MANAGEMENT
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
    min_stock INTEGER DEFAULT 0,
    max_stock INTEGER DEFAULT 0,
    reorder_point INTEGER DEFAULT 0,
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

-- Product stock per branch
CREATE TABLE product_stocks (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    branch_id INTEGER NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    quantity INTEGER DEFAULT 0,
    reserved_quantity INTEGER DEFAULT 0,
    available_quantity INTEGER GENERATED ALWAYS AS (quantity - reserved_quantity) STORED,
    last_stock_count_at TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(product_id, branch_id)
);

CREATE INDEX idx_product_stocks_product ON product_stocks(product_id);
CREATE INDEX idx_product_stocks_branch ON product_stocks(branch_id);
CREATE INDEX idx_product_stocks_available ON product_stocks(available_quantity);

-- ============================================
-- 4. CUSTOMER MANAGEMENT
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
-- 5. SUPPLIER MANAGEMENT
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
-- 6. SALES TRANSACTIONS
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
    
    payment_method payment_method NOT NULL,
    payment_reference VARCHAR(100),
    
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

-- Partitioning for large scale (optional)
-- CREATE TABLE sales_2025 PARTITION OF sales FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE TABLE sale_items (
    id BIGSERIAL PRIMARY KEY,
    sale_id BIGINT NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id),
    product_name VARCHAR(255) NOT NULL,
    sku VARCHAR(50) NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(15, 2) NOT NULL,
    discount_amount DECIMAL(15, 2) DEFAULT 0,
    discount_percentage DECIMAL(5, 2) DEFAULT 0,
    tax_amount DECIMAL(15, 2) DEFAULT 0,
    subtotal DECIMAL(15, 2) NOT NULL,
    total DECIMAL(15, 2) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sale_items_sale ON sale_items(sale_id);
CREATE INDEX idx_sale_items_product ON sale_items(product_id);

-- ============================================
-- 7. PURCHASE TRANSACTIONS
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
    quantity_ordered INTEGER NOT NULL,
    quantity_received INTEGER DEFAULT 0,
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
-- 8. INVENTORY ADJUSTMENTS
-- ============================================

CREATE TYPE adjustment_type AS ENUM ('increase', 'decrease', 'transfer', 'damage', 'lost', 'found');

CREATE TABLE stock_adjustments (
    id BIGSERIAL PRIMARY KEY,
    adjustment_number VARCHAR(50) UNIQUE NOT NULL,
    branch_id INTEGER NOT NULL REFERENCES branches(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    adjustment_type adjustment_type NOT NULL,
    quantity INTEGER NOT NULL,
    previous_quantity INTEGER NOT NULL,
    new_quantity INTEGER NOT NULL,
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
-- 9. SYNC LOG (untuk tracking data sync)
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
-- 10. AUDIT LOG
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
-- FUNCTIONS & TRIGGERS
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
CREATE TRIGGER update_products_timestamp BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_customers_timestamp BEFORE UPDATE ON customers FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_suppliers_timestamp BEFORE UPDATE ON suppliers FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_sales_timestamp BEFORE UPDATE ON sales FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_purchases_timestamp BEFORE UPDATE ON purchases FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Auto-update product stock when sale is created
CREATE OR REPLACE FUNCTION update_stock_on_sale()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' THEN
        UPDATE product_stocks
        SET quantity = quantity - (
            SELECT SUM(quantity)
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
-- INITIAL DATA
-- ============================================

-- Default super admin user (password: admin123)
INSERT INTO users (username, email, password_hash, full_name, role, status)
VALUES ('admin', 'admin@pos.com', '$2a$10$rG7QVqvN8z3V.gFZ8yQrB.vH9p7zLVXQx6F7ij9jZJU9YW7KJt5.a', 'System Administrator', 'super_admin', 'active');

-- Default head office branch
INSERT INTO branches (code, name, is_head_office, api_key)
VALUES ('HQ', 'Head Office', true, uuid_generate_v4()::text);

-- Default category
INSERT INTO categories (name, description)
VALUES ('General', 'General products');

-- Success message
SELECT 'Database schema created successfully!' as message;
