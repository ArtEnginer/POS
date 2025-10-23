-- =====================================================
-- POS Database Tables Creation Script
-- Database: pos_db
-- =====================================================

USE pos_db;

-- =====================================================
-- 1. PRODUCTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS products (
  id VARCHAR(36) PRIMARY KEY,
  plu VARCHAR(50) UNIQUE,
  barcode VARCHAR(100) UNIQUE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  category_id VARCHAR(36),
  unit VARCHAR(50),
  purchase_price DECIMAL(15,2) NOT NULL,
  selling_price DECIMAL(15,2) NOT NULL,
  stock INT NOT NULL DEFAULT 0,
  min_stock INT DEFAULT 0,
  image_url TEXT,
  is_active TINYINT(1) DEFAULT 1,
  sync_status VARCHAR(20) DEFAULT 'SYNCED',
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  deleted_at DATETIME DEFAULT NULL,
  INDEX idx_products_plu (plu),
  INDEX idx_products_barcode (barcode),
  INDEX idx_products_category (category_id),
  INDEX idx_products_sync (sync_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 2. CATEGORIES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS categories (
  id VARCHAR(36) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  parent_id VARCHAR(36),
  icon VARCHAR(100),
  is_active TINYINT(1) DEFAULT 1,
  sync_status VARCHAR(20) DEFAULT 'SYNCED',
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  deleted_at DATETIME DEFAULT NULL,
  INDEX idx_categories_parent (parent_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 3. SUPPLIERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS suppliers (
  id VARCHAR(36) PRIMARY KEY,
  code VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  contact_person VARCHAR(255),
  phone VARCHAR(50),
  email VARCHAR(100),
  address TEXT,
  city VARCHAR(100),
  postal_code VARCHAR(20),
  tax_number VARCHAR(100),
  payment_terms INT DEFAULT 0,
  is_active TINYINT(1) DEFAULT 1,
  sync_status VARCHAR(20) DEFAULT 'SYNCED',
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  deleted_at DATETIME DEFAULT NULL,
  INDEX idx_suppliers_code (code),
  INDEX idx_suppliers_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 4. PURCHASES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS purchases (
  id VARCHAR(36) PRIMARY KEY,
  purchase_number VARCHAR(50) UNIQUE NOT NULL,
  supplier_id VARCHAR(36),
  supplier_name VARCHAR(255),
  purchase_date DATETIME NOT NULL,
  subtotal DECIMAL(15,2) NOT NULL,
  tax DECIMAL(15,2) NOT NULL DEFAULT 0,
  discount DECIMAL(15,2) NOT NULL DEFAULT 0,
  total DECIMAL(15,2) NOT NULL,
  payment_method VARCHAR(50) NOT NULL,
  paid_amount DECIMAL(15,2) NOT NULL,
  status VARCHAR(50) NOT NULL,
  notes TEXT,
  sync_status VARCHAR(20) DEFAULT 'PENDING',
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  INDEX idx_purchases_number (purchase_number),
  INDEX idx_purchases_date (purchase_date),
  INDEX idx_purchases_status (status),
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 5. PURCHASE ITEMS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS purchase_items (
  id VARCHAR(36) PRIMARY KEY,
  purchase_id VARCHAR(36) NOT NULL,
  product_id VARCHAR(36) NOT NULL,
  product_name VARCHAR(255) NOT NULL,
  quantity INT NOT NULL,
  price DECIMAL(15,2) NOT NULL,
  subtotal DECIMAL(15,2) NOT NULL,
  sync_status VARCHAR(20) DEFAULT 'SYNCED',
  created_at DATETIME NOT NULL,
  INDEX idx_purchase_items_purchase (purchase_id),
  INDEX idx_purchase_items_product (product_id),
  FOREIGN KEY (purchase_id) REFERENCES purchases(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 6. TRANSACTIONS TABLE (SALES)
-- =====================================================
CREATE TABLE IF NOT EXISTS transactions (
  id VARCHAR(36) PRIMARY KEY,
  transaction_number VARCHAR(50) UNIQUE NOT NULL,
  customer_id VARCHAR(36),
  cashier_id VARCHAR(36) NOT NULL,
  cashier_name VARCHAR(255) NOT NULL,
  subtotal DECIMAL(15,2) NOT NULL,
  tax DECIMAL(15,2) NOT NULL DEFAULT 0,
  discount DECIMAL(15,2) NOT NULL DEFAULT 0,
  total DECIMAL(15,2) NOT NULL,
  payment_method VARCHAR(50) NOT NULL,
  payment_amount DECIMAL(15,2) NOT NULL,
  change_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
  status VARCHAR(50) NOT NULL,
  notes TEXT,
  sync_status VARCHAR(20) DEFAULT 'PENDING',
  transaction_date DATETIME NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  INDEX idx_transactions_number (transaction_number),
  INDEX idx_transactions_date (transaction_date),
  INDEX idx_transactions_status (status),
  INDEX idx_transactions_sync (sync_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 7. TRANSACTION ITEMS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS transaction_items (
  id VARCHAR(36) PRIMARY KEY,
  transaction_id VARCHAR(36) NOT NULL,
  product_id VARCHAR(36) NOT NULL,
  product_name VARCHAR(255) NOT NULL,
  quantity INT NOT NULL,
  price DECIMAL(15,2) NOT NULL,
  discount DECIMAL(15,2) NOT NULL DEFAULT 0,
  subtotal DECIMAL(15,2) NOT NULL,
  sync_status VARCHAR(20) DEFAULT 'PENDING',
  created_at DATETIME NOT NULL,
  INDEX idx_transaction_items_transaction (transaction_id),
  INDEX idx_transaction_items_product (product_id),
  FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 8. CUSTOMERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS customers (
  id VARCHAR(36) PRIMARY KEY,
  code VARCHAR(50) UNIQUE,
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(50),
  email VARCHAR(100),
  address TEXT,
  city VARCHAR(100),
  postal_code VARCHAR(20),
  points INT DEFAULT 0,
  is_active TINYINT(1) DEFAULT 1,
  sync_status VARCHAR(20) DEFAULT 'SYNCED',
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  deleted_at DATETIME DEFAULT NULL,
  INDEX idx_customers_code (code),
  INDEX idx_customers_phone (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 9. USERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS users (
  id VARCHAR(36) PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(100) UNIQUE,
  phone VARCHAR(50),
  role VARCHAR(50) NOT NULL,
  is_active TINYINT(1) DEFAULT 1,
  last_login DATETIME,
  sync_status VARCHAR(20) DEFAULT 'SYNCED',
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  INDEX idx_users_username (username),
  INDEX idx_users_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 10. STOCK MOVEMENTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS stock_movements (
  id VARCHAR(36) PRIMARY KEY,
  product_id VARCHAR(36) NOT NULL,
  type VARCHAR(50) NOT NULL,
  quantity INT NOT NULL,
  reference_id VARCHAR(36),
  reference_type VARCHAR(50),
  notes TEXT,
  user_id VARCHAR(36) NOT NULL,
  sync_status VARCHAR(20) DEFAULT 'PENDING',
  created_at DATETIME NOT NULL,
  INDEX idx_stock_movements_product (product_id),
  INDEX idx_stock_movements_date (created_at),
  INDEX idx_stock_movements_type (type),
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 11. RECEIVINGS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS receivings (
  id VARCHAR(36) PRIMARY KEY,
  receiving_number VARCHAR(50) UNIQUE NOT NULL,
  purchase_id VARCHAR(36) NOT NULL,
  purchase_number VARCHAR(50) NOT NULL,
  supplier_id VARCHAR(36),
  supplier_name VARCHAR(255),
  receiving_date DATETIME NOT NULL,
  invoice_number VARCHAR(100),
  delivery_order_number VARCHAR(100),
  vehicle_number VARCHAR(50),
  driver_name VARCHAR(255),
  subtotal DECIMAL(15,2) NOT NULL,
  item_discount DECIMAL(15,2) NOT NULL DEFAULT 0,
  item_tax DECIMAL(15,2) NOT NULL DEFAULT 0,
  total_discount DECIMAL(15,2) NOT NULL DEFAULT 0,
  total_tax DECIMAL(15,2) NOT NULL DEFAULT 0,
  total DECIMAL(15,2) NOT NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'COMPLETED',
  notes TEXT,
  received_by VARCHAR(255),
  sync_status VARCHAR(20) DEFAULT 'PENDING',
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  INDEX idx_receivings_number (receiving_number),
  INDEX idx_receivings_purchase (purchase_id),
  INDEX idx_receivings_date (receiving_date),
  INDEX idx_receivings_status (status),
  FOREIGN KEY (purchase_id) REFERENCES purchases(id) ON DELETE RESTRICT,
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 12. RECEIVING ITEMS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS receiving_items (
  id VARCHAR(36) PRIMARY KEY,
  receiving_id VARCHAR(36) NOT NULL,
  purchase_item_id VARCHAR(36),
  product_id VARCHAR(36) NOT NULL,
  product_name VARCHAR(255) NOT NULL,
  po_quantity INT NOT NULL,
  po_price DECIMAL(15,2) NOT NULL,
  received_quantity INT NOT NULL,
  received_price DECIMAL(15,2) NOT NULL,
  discount DECIMAL(15,2) NOT NULL DEFAULT 0,
  discount_type VARCHAR(20) DEFAULT 'AMOUNT',
  tax DECIMAL(15,2) NOT NULL DEFAULT 0,
  tax_type VARCHAR(20) DEFAULT 'AMOUNT',
  subtotal DECIMAL(15,2) NOT NULL,
  total DECIMAL(15,2) NOT NULL,
  notes TEXT,
  sync_status VARCHAR(20) DEFAULT 'SYNCED',
  created_at DATETIME NOT NULL,
  INDEX idx_receiving_items_receiving (receiving_id),
  INDEX idx_receiving_items_product (product_id),
  FOREIGN KEY (receiving_id) REFERENCES receivings(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 13. PURCHASE RETURNS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS purchase_returns (
  id VARCHAR(36) PRIMARY KEY,
  return_number VARCHAR(50) UNIQUE NOT NULL,
  receiving_id VARCHAR(36) NOT NULL,
  receiving_number VARCHAR(50) NOT NULL,
  purchase_id VARCHAR(36) NOT NULL,
  purchase_number VARCHAR(50) NOT NULL,
  supplier_id VARCHAR(36),
  supplier_name VARCHAR(255),
  return_date DATETIME NOT NULL,
  subtotal DECIMAL(15,2) NOT NULL,
  item_discount DECIMAL(15,2) NOT NULL DEFAULT 0,
  item_tax DECIMAL(15,2) NOT NULL DEFAULT 0,
  total_discount DECIMAL(15,2) NOT NULL DEFAULT 0,
  total_tax DECIMAL(15,2) NOT NULL DEFAULT 0,
  total DECIMAL(15,2) NOT NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'DRAFT',
  reason TEXT,
  notes TEXT,
  processed_by VARCHAR(255),
  sync_status VARCHAR(20) DEFAULT 'PENDING',
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  INDEX idx_purchase_returns_number (return_number),
  INDEX idx_purchase_returns_receiving (receiving_id),
  INDEX idx_purchase_returns_purchase (purchase_id),
  INDEX idx_purchase_returns_date (return_date),
  INDEX idx_purchase_returns_status (status),
  FOREIGN KEY (receiving_id) REFERENCES receivings(id) ON DELETE RESTRICT,
  FOREIGN KEY (purchase_id) REFERENCES purchases(id) ON DELETE RESTRICT,
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 14. PURCHASE RETURN ITEMS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS purchase_return_items (
  id VARCHAR(36) PRIMARY KEY,
  return_id VARCHAR(36) NOT NULL,
  receiving_item_id VARCHAR(36) NOT NULL,
  product_id VARCHAR(36) NOT NULL,
  product_name VARCHAR(255) NOT NULL,
  received_quantity INT NOT NULL,
  return_quantity INT NOT NULL,
  price DECIMAL(15,2) NOT NULL,
  discount DECIMAL(15,2) NOT NULL DEFAULT 0,
  discount_type VARCHAR(20) DEFAULT 'AMOUNT',
  tax DECIMAL(15,2) NOT NULL DEFAULT 0,
  tax_type VARCHAR(20) DEFAULT 'AMOUNT',
  subtotal DECIMAL(15,2) NOT NULL,
  total DECIMAL(15,2) NOT NULL,
  reason TEXT,
  notes TEXT,
  sync_status VARCHAR(20) DEFAULT 'SYNCED',
  created_at DATETIME NOT NULL,
  INDEX idx_purchase_return_items_return (return_id),
  INDEX idx_purchase_return_items_product (product_id),
  FOREIGN KEY (return_id) REFERENCES purchase_returns(id) ON DELETE CASCADE,
  FOREIGN KEY (receiving_item_id) REFERENCES receiving_items(id) ON DELETE RESTRICT,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 15. SYNC QUEUE TABLE (Optional - for tracking)
-- =====================================================
CREATE TABLE IF NOT EXISTS sync_queue (
  id INT AUTO_INCREMENT PRIMARY KEY,
  table_name VARCHAR(100) NOT NULL,
  record_id VARCHAR(36) NOT NULL,
  operation VARCHAR(20) NOT NULL,
  data JSON,
  status VARCHAR(20) DEFAULT 'PENDING',
  retry_count INT DEFAULT 0,
  error_message TEXT,
  created_at DATETIME NOT NULL,
  synced_at DATETIME,
  INDEX idx_sync_queue_status (status),
  INDEX idx_sync_queue_table (table_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 16. SETTINGS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS settings (
  setting_key VARCHAR(100) PRIMARY KEY,
  setting_value TEXT NOT NULL,
  updated_at DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- INSERT DEFAULT SETTINGS
-- =====================================================
INSERT INTO settings (setting_key, setting_value, updated_at) 
VALUES 
  ('tax_rate', '0.11', NOW()),
  ('last_sync', NOW(), NOW())
ON DUPLICATE KEY UPDATE 
  setting_value = VALUES(setting_value),
  updated_at = NOW();

-- =====================================================
-- VERIFY TABLES
-- =====================================================
SELECT 
  TABLE_NAME,
  TABLE_ROWS,
  CREATE_TIME
FROM 
  information_schema.TABLES
WHERE 
  TABLE_SCHEMA = 'pos_db'
ORDER BY 
  TABLE_NAME;
