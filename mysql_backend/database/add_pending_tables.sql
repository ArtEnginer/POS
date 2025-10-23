-- Add pending transactions tables for POS system
-- Execute this SQL script in your MySQL database

-- Pending Transactions Table
CREATE TABLE IF NOT EXISTS pending_transactions (
  id VARCHAR(36) PRIMARY KEY,
  pending_number VARCHAR(50) UNIQUE NOT NULL,
  customer_id VARCHAR(36),
  customer_name VARCHAR(255),
  saved_at DATETIME NOT NULL,
  saved_by VARCHAR(100) NOT NULL,
  notes TEXT,
  subtotal DECIMAL(15,2) NOT NULL,
  tax DECIMAL(15,2) NOT NULL DEFAULT 0,
  discount DECIMAL(15,2) NOT NULL DEFAULT 0,
  total DECIMAL(15,2) NOT NULL,
  INDEX idx_pending_number (pending_number),
  INDEX idx_saved_at (saved_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Pending Transaction Items Table
CREATE TABLE IF NOT EXISTS pending_transaction_items (
  id VARCHAR(36) PRIMARY KEY,
  pending_id VARCHAR(36) NOT NULL,
  product_id VARCHAR(36) NOT NULL,
  product_name VARCHAR(255) NOT NULL,
  quantity INT NOT NULL,
  price DECIMAL(15,2) NOT NULL,
  discount DECIMAL(15,2) NOT NULL DEFAULT 0,
  subtotal DECIMAL(15,2) NOT NULL,
  created_at DATETIME NOT NULL,
  FOREIGN KEY (pending_id) REFERENCES pending_transactions(id) ON DELETE CASCADE,
  INDEX idx_pending_id (pending_id),
  INDEX idx_product_id (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
