-- ============================================
-- RECEIVING (PENERIMAAN BARANG) TABLES
-- ============================================

-- Receiving Status Enum
CREATE TYPE receiving_status AS ENUM ('completed', 'partial', 'cancelled');

-- Main Receivings Table
CREATE TABLE IF NOT EXISTS receivings (
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

-- Receiving Items Table
CREATE TABLE IF NOT EXISTS receiving_items (
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

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_receivings_number ON receivings(receiving_number);
CREATE INDEX IF NOT EXISTS idx_receivings_purchase ON receivings(purchase_id);
CREATE INDEX IF NOT EXISTS idx_receivings_supplier ON receivings(supplier_id);
CREATE INDEX IF NOT EXISTS idx_receivings_date ON receivings(receiving_date);
CREATE INDEX IF NOT EXISTS idx_receivings_status ON receivings(status);

CREATE INDEX IF NOT EXISTS idx_receiving_items_receiving ON receiving_items(receiving_id);
CREATE INDEX IF NOT EXISTS idx_receiving_items_product ON receiving_items(product_id);

-- Trigger for updated_at
CREATE TRIGGER update_receivings_timestamp 
BEFORE UPDATE ON receivings 
FOR EACH ROW 
EXECUTE FUNCTION update_updated_at();

-- Success message
SELECT 'Receiving tables created successfully!' as message;
