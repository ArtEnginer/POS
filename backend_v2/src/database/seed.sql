-- ============================================
-- SEED DATA FOR POS SYSTEM
-- Run this after schema.sql to populate initial data
-- ============================================

-- ============================================
-- 1. INSERT DEFAULT BRANCH
-- ============================================

-- Insert main branch (head office)
INSERT INTO branches (code, name, address, city, phone, email, is_active, is_head_office, api_key, timezone)
VALUES (
    'HO001',
    'Head Office',
    'Jl. Contoh No. 123',
    'Jakarta',
    '021-12345678',
    'headoffice@pos.com',
    true,
    true,
    encode(gen_random_bytes(32), 'hex'), -- Generate random API key
    'Asia/Jakarta'
)
ON CONFLICT (code) DO NOTHING;

-- Insert branch 1
INSERT INTO branches (code, name, address, city, phone, email, is_active, is_head_office, api_key, timezone)
VALUES (
    'BR001',
    'Branch 1',
    'Jl. Branch 1 No. 456',
    'Bandung',
    '022-87654321',
    'branch1@pos.com',
    true,
    false,
    encode(gen_random_bytes(32), 'hex'),
    'Asia/Jakarta'
)
ON CONFLICT (code) DO NOTHING;

-- ============================================
-- 2. INSERT DEFAULT USERS
-- ============================================

-- Insert super admin (password: admin123)
INSERT INTO users (username, email, password_hash, full_name, role, status)
VALUES (
    'admin',
    'admin@pos.com',
    '$2a$10$YourHashedPasswordHere', -- bcrypt hash for 'admin123'
    'Super Administrator',
    'super_admin',
    'active'
)
ON CONFLICT (username) DO NOTHING;

-- Insert cashier user (password: cashier123)
INSERT INTO users (username, email, password_hash, full_name, role, status)
VALUES (
    'cashier1',
    'cashier1@pos.com',
    '$2a$10$YourHashedPasswordHere', -- bcrypt hash for 'cashier123'
    'Cashier One',
    'cashier',
    'active'
)
ON CONFLICT (username) DO NOTHING;

-- ============================================
-- 3. ASSIGN USERS TO BRANCHES
-- ============================================

-- Assign admin to all branches
INSERT INTO user_branches (user_id, branch_id, is_default)
SELECT u.id, b.id, (b.is_head_office = true) as is_default
FROM users u
CROSS JOIN branches b
WHERE u.username = 'admin'
ON CONFLICT (user_id, branch_id) DO NOTHING;

-- Assign cashier to branch 1
INSERT INTO user_branches (user_id, branch_id, is_default)
SELECT u.id, b.id, true
FROM users u
CROSS JOIN branches b
WHERE u.username = 'cashier1' AND b.code = 'BR001'
ON CONFLICT (user_id, branch_id) DO NOTHING;

-- ============================================
-- 4. INSERT SAMPLE CATEGORIES
-- ============================================

INSERT INTO categories (name, description, sort_order, is_active)
VALUES 
    ('Elektronik', 'Produk elektronik dan gadget', 1, true),
    ('Makanan & Minuman', 'Produk makanan dan minuman', 2, true),
    ('Pakaian', 'Produk pakaian dan fashion', 3, true),
    ('Kesehatan', 'Produk kesehatan dan kecantikan', 4, true),
    ('Alat Tulis', 'Produk alat tulis dan kantor', 5, true)
ON CONFLICT DO NOTHING;

-- ============================================
-- 5. DISPLAY CREATED API KEYS
-- ============================================

-- Show branch API keys for reference
SELECT 
    code as branch_code,
    name as branch_name,
    api_key,
    'Use this API key for branch authentication' as note
FROM branches
WHERE deleted_at IS NULL
ORDER BY is_head_office DESC, code;

-- Show created users
SELECT 
    username,
    email,
    role,
    'Password needs to be set manually' as note
FROM users
WHERE deleted_at IS NULL
ORDER BY role, username;

COMMIT;
