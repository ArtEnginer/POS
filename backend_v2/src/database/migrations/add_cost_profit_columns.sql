-- Migration: Add cost price and profit tracking to sales
-- Date: 2025-10-30
-- Description: Menambahkan kolom cost_price di sale_items dan profit tracking di sales

-- ============================================
-- 1. UPDATE SALE_ITEMS TABLE
-- ============================================

-- Tambah kolom cost_price (harga beli saat transaksi)
ALTER TABLE sale_items 
ADD COLUMN IF NOT EXISTS cost_price DECIMAL(15, 2) DEFAULT 0;

-- Tambah kolom total_cost per item
ALTER TABLE sale_items 
ADD COLUMN IF NOT EXISTS total_cost DECIMAL(15, 2) GENERATED ALWAYS AS (cost_price * quantity) STORED;

-- Tambah kolom profit per item  
ALTER TABLE sale_items 
ADD COLUMN IF NOT EXISTS item_profit DECIMAL(15, 2) GENERATED ALWAYS AS (total - (cost_price * quantity)) STORED;

-- Update existing records dengan cost_price dari products table
UPDATE sale_items si
SET cost_price = COALESCE(p.cost_price, 0)
FROM products p
WHERE si.product_id = p.id 
AND si.cost_price = 0;

-- Add comments
COMMENT ON COLUMN sale_items.cost_price IS 'Harga beli produk pada saat transaksi (snapshot)';
COMMENT ON COLUMN sale_items.total_cost IS 'Total cost = cost_price × quantity';
COMMENT ON COLUMN sale_items.item_profit IS 'Profit per item = total - total_cost';

-- ============================================
-- 2. UPDATE SALES TABLE
-- ============================================

-- Tambah kolom total cost (total harga beli semua items)
ALTER TABLE sales 
ADD COLUMN IF NOT EXISTS total_cost DECIMAL(15, 2) DEFAULT 0;

-- Tambah kolom gross profit (laba kotor)
ALTER TABLE sales 
ADD COLUMN IF NOT EXISTS gross_profit DECIMAL(15, 2) DEFAULT 0;

-- Tambah kolom profit margin (%)
ALTER TABLE sales 
ADD COLUMN IF NOT EXISTS profit_margin DECIMAL(5, 2) DEFAULT 0;

-- Tambah kolom cashier location
ALTER TABLE sales 
ADD COLUMN IF NOT EXISTS cashier_location VARCHAR(255);

-- Tambah kolom device info
ALTER TABLE sales 
ADD COLUMN IF NOT EXISTS device_info JSONB DEFAULT '{}';

-- Add comments
COMMENT ON COLUMN sales.total_cost IS 'Total harga beli semua items';
COMMENT ON COLUMN sales.gross_profit IS 'Laba kotor = total_amount - total_cost';
COMMENT ON COLUMN sales.profit_margin IS 'Margin keuntungan dalam persen';
COMMENT ON COLUMN sales.cashier_location IS 'Lokasi kasir saat transaksi';
COMMENT ON COLUMN sales.device_info IS 'Metadata device kasir (OS, version, IP, dll)';

-- ============================================
-- 3. CREATE FUNCTION TO AUTO-CALCULATE PROFIT
-- ============================================

-- Function untuk calculate total_cost dari sale_items
CREATE OR REPLACE FUNCTION calculate_sale_totals()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate total_cost dari semua items
    UPDATE sales 
    SET total_cost = (
        SELECT COALESCE(SUM(cost_price * quantity), 0)
        FROM sale_items 
        WHERE sale_id = NEW.sale_id
    ),
    updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.sale_id;
    
    -- Calculate gross_profit dan profit_margin
    UPDATE sales 
    SET 
        gross_profit = total_amount - total_cost,
        profit_margin = CASE 
            WHEN total_amount > 0 THEN ((total_amount - total_cost) / total_amount * 100)
            ELSE 0 
        END,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.sale_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger untuk auto-calculate saat insert/update sale_items
DROP TRIGGER IF EXISTS trigger_calculate_sale_totals ON sale_items;
CREATE TRIGGER trigger_calculate_sale_totals
    AFTER INSERT OR UPDATE ON sale_items
    FOR EACH ROW
    EXECUTE FUNCTION calculate_sale_totals();

-- ============================================
-- 4. UPDATE EXISTING SALES DATA
-- ============================================

-- Update total_cost untuk existing sales
UPDATE sales s
SET total_cost = (
    SELECT COALESCE(SUM(si.cost_price * si.quantity), 0)
    FROM sale_items si
    WHERE si.sale_id = s.id
);

-- Update gross_profit dan profit_margin
UPDATE sales
SET 
    gross_profit = total_amount - total_cost,
    profit_margin = CASE 
        WHEN total_amount > 0 THEN ((total_amount - total_cost) / total_amount * 100)
        ELSE 0 
    END;

-- ============================================
-- 5. CREATE INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_sales_profit_margin ON sales(profit_margin);
CREATE INDEX IF NOT EXISTS idx_sales_gross_profit ON sales(gross_profit);
CREATE INDEX IF NOT EXISTS idx_sale_items_cost_price ON sale_items(cost_price);

-- ============================================
-- 6. CREATE VIEW FOR SALES ANALYSIS
-- ============================================

CREATE OR REPLACE VIEW v_sales_profit_analysis AS
SELECT 
    s.id,
    s.sale_number,
    s.sale_date,
    b.name as branch_name,
    u.full_name as cashier_name,
    c.name as customer_name,
    s.total_amount,
    s.total_cost,
    s.gross_profit,
    s.profit_margin,
    s.cashier_location,
    s.payment_method,
    COUNT(si.id) as total_items,
    SUM(si.quantity) as total_quantity
FROM sales s
LEFT JOIN branches b ON s.branch_id = b.id
LEFT JOIN users u ON s.cashier_id = u.id
LEFT JOIN customers c ON s.customer_id = c.id
LEFT JOIN sale_items si ON s.id = si.sale_id
WHERE s.deleted_at IS NULL
GROUP BY s.id, b.name, u.full_name, c.name;

COMMENT ON VIEW v_sales_profit_analysis IS 'View untuk analisis profit per transaksi';

-- ============================================
-- VERIFICATION QUERY
-- ============================================

-- Uncomment untuk verify migration
/*
SELECT 
    column_name, 
    data_type, 
    column_default,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('sales', 'sale_items')
AND column_name IN ('cost_price', 'total_cost', 'gross_profit', 'profit_margin', 'cashier_location', 'device_info', 'item_profit')
ORDER BY table_name, ordinal_position;
*/

COMMIT;
