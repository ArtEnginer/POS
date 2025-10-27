-- ============================================
-- Migration: Add 'approved' status to purchase_status enum
-- Date: 2025-10-27
-- Purpose: Allow PO approval workflow before receiving
-- ============================================

-- Step 1: Add 'approved' to purchase_status enum
-- Note: PostgreSQL doesn't allow direct ALTER TYPE for enums with existing data
-- We need to:
-- 1. Drop default constraint temporarily
-- 2. Create a new type with the additional value
-- 3. Alter the column to use the new type
-- 4. Drop the old type
-- 5. Restore default constraint

-- Drop default constraint temporarily
ALTER TABLE purchases ALTER COLUMN status DROP DEFAULT;

-- Create new enum type with 'approved' status
CREATE TYPE purchase_status_new AS ENUM (
    'draft', 
    'ordered', 
    'approved',     -- NEW: Status for approved PO ready for receiving
    'partial', 
    'received', 
    'cancelled'
);

-- Convert existing column to new type
ALTER TABLE purchases 
    ALTER COLUMN status TYPE purchase_status_new 
    USING status::text::purchase_status_new;

-- Drop old type and rename new type
DROP TYPE purchase_status;
ALTER TYPE purchase_status_new RENAME TO purchase_status;

-- Restore default constraint
ALTER TABLE purchases ALTER COLUMN status SET DEFAULT 'draft'::purchase_status;

-- Add comment explaining the workflow
COMMENT ON TYPE purchase_status IS 
'Purchase Order Status Flow:
- draft: PO sedang dibuat, belum disubmit
- ordered: PO sudah dikirim ke supplier
- approved: PO sudah disetujui, siap untuk receiving
- partial: Sebagian barang sudah diterima
- received: Semua barang sudah diterima
- cancelled: PO dibatalkan';

-- Add index for approved status queries (if not exists)
-- This helps when filtering POs ready for receiving
CREATE INDEX IF NOT EXISTS idx_purchases_approved_status 
ON purchases(status) WHERE status = 'approved';

COMMIT;
