-- ============================================
-- MIGRATION SCRIPT: Products Table V5
-- ============================================
-- Changes:
-- 1. Remove cost_price and selling_price from products table
-- 2. Change base_unit from ID (INTEGER) to STRING (VARCHAR)
-- 3. Drop foreign key constraint for base_unit_id
-- 
-- IMPORTANT: Backup your database before running this!
-- ============================================

BEGIN;

-- Step 1: Add new base_unit column (STRING)
ALTER TABLE products ADD COLUMN IF NOT EXISTS base_unit VARCHAR(50) DEFAULT 'PCS';

-- Step 2: Populate base_unit from existing unit column (if exists)
UPDATE products 
SET base_unit = COALESCE(unit, 'PCS')
WHERE base_unit IS NULL OR base_unit = '';

-- Step 3: Drop old columns
ALTER TABLE products DROP COLUMN IF EXISTS unit;
ALTER TABLE products DROP COLUMN IF EXISTS cost_price;
ALTER TABLE products DROP COLUMN IF EXISTS selling_price;

-- Step 4: Drop old base_unit_id and its constraint if exists
ALTER TABLE products DROP CONSTRAINT IF EXISTS fk_products_base_unit;
ALTER TABLE products DROP COLUMN IF EXISTS base_unit_id;

-- Step 5: Update index
DROP INDEX IF EXISTS idx_products_base_unit;
CREATE INDEX idx_products_base_unit ON products(base_unit);

COMMIT;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================
-- Run these to verify the migration:

-- Check table structure
-- SELECT column_name, data_type, character_maximum_length, is_nullable, column_default
-- FROM information_schema.columns 
-- WHERE table_name = 'products' 
-- ORDER BY ordinal_position;

-- Check sample data
-- SELECT id, sku, name, base_unit, min_stock, max_stock 
-- FROM products 
-- LIMIT 10;

-- Check if any products have NULL base_unit
-- SELECT COUNT(*) as null_base_units 
-- FROM products 
-- WHERE base_unit IS NULL;
