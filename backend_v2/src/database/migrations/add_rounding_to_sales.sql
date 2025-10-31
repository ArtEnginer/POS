-- Migration: Add rounding and grand_total to sales table
-- Date: 2025-10-31
-- Description: Menambahkan field pembulatan untuk mendukung pembulatan Rupiah Indonesia

-- Add rounding column (nilai pembulatan, bisa + atau -)
ALTER TABLE sales 
ADD COLUMN IF NOT EXISTS rounding DECIMAL(15, 2) DEFAULT 0;

-- Add grand_total column (total setelah pembulatan)
ALTER TABLE sales 
ADD COLUMN IF NOT EXISTS grand_total DECIMAL(15, 2);

-- Update existing records: set grand_total = total_amount for old data
UPDATE sales 
SET grand_total = total_amount 
WHERE grand_total IS NULL;

-- Make grand_total NOT NULL after setting values
ALTER TABLE sales 
ALTER COLUMN grand_total SET NOT NULL;

-- Add comment untuk dokumentasi
COMMENT ON COLUMN sales.rounding IS 'Nilai pembulatan (positif = naik, negatif = turun)';
COMMENT ON COLUMN sales.grand_total IS 'Total setelah pembulatan (total_amount + rounding)';

-- Index untuk performa query
CREATE INDEX IF NOT EXISTS idx_sales_grand_total ON sales(grand_total);
