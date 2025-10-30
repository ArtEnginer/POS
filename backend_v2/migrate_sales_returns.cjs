const { Pool } = require("pg");
require("dotenv").config();

const pool = new Pool({
  user: process.env.DB_USER || "postgres",
  host: process.env.DB_HOST || "localhost",
  database: process.env.DB_NAME || "pos_db",
  password: process.env.DB_PASSWORD || "postgres",
  port: process.env.DB_PORT || 5432,
});

async function migrate() {
  const client = await pool.connect();

  try {
    console.log("🚀 Starting Sales Returns migration...\n");

    await client.query("BEGIN");

    // ========================================
    // 1. CREATE TABLE: sales_returns
    // ========================================
    console.log("📋 Creating sales_returns table...");
    await client.query(`
      CREATE TABLE IF NOT EXISTS sales_returns (
        id BIGSERIAL PRIMARY KEY,
        return_number VARCHAR(50) UNIQUE NOT NULL,
        original_sale_id BIGINT NOT NULL,
        original_invoice_number VARCHAR(50) NOT NULL,
        branch_id INTEGER NOT NULL,
        return_date TIMESTAMP NOT NULL DEFAULT NOW(),
        return_reason TEXT NOT NULL,
        total_refund DECIMAL(15, 2) NOT NULL DEFAULT 0,
        refund_method VARCHAR(20) DEFAULT 'cash',
        customer_id INTEGER,
        customer_name VARCHAR(255),
        cashier_id INTEGER NOT NULL,
        cashier_name VARCHAR(255),
        processed_by_user_id INTEGER NOT NULL,
        status VARCHAR(20) DEFAULT 'pending',
        synced_at TIMESTAMP,
        sync_status VARCHAR(20) DEFAULT 'pending',
        notes TEXT,
        metadata JSONB DEFAULT '{}',
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW(),
        deleted_at TIMESTAMP,
        
        -- Foreign Keys
        CONSTRAINT fk_sales_returns_original_sale 
          FOREIGN KEY (original_sale_id) 
          REFERENCES sales(id) 
          ON DELETE RESTRICT,
        
        CONSTRAINT fk_sales_returns_branch 
          FOREIGN KEY (branch_id) 
          REFERENCES branches(id) 
          ON DELETE RESTRICT,
        
        CONSTRAINT fk_sales_returns_cashier 
          FOREIGN KEY (cashier_id) 
          REFERENCES users(id) 
          ON DELETE RESTRICT,
          
        CONSTRAINT fk_sales_returns_processed_by 
          FOREIGN KEY (processed_by_user_id) 
          REFERENCES users(id) 
          ON DELETE RESTRICT,
        
        -- Check constraints
        CONSTRAINT chk_refund_method 
          CHECK (refund_method IN ('cash', 'transfer', 'credit')),
        
        CONSTRAINT chk_status 
          CHECK (status IN ('pending', 'processed', 'completed', 'cancelled'))
      );
    `);
    console.log("✅ Table sales_returns created\n");

    // ========================================
    // 2. CREATE TABLE: return_items
    // ========================================
    console.log("📋 Creating return_items table...");
    await client.query(`
      CREATE TABLE IF NOT EXISTS return_items (
        id BIGSERIAL PRIMARY KEY,
        return_id BIGINT NOT NULL,
        product_id INTEGER NOT NULL,
        product_name VARCHAR(255) NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price DECIMAL(15, 2) NOT NULL,
        subtotal DECIMAL(15, 2) NOT NULL,
        reason TEXT,
        created_at TIMESTAMP DEFAULT NOW(),
        
        -- Foreign Keys
        CONSTRAINT fk_return_items_return 
          FOREIGN KEY (return_id) 
          REFERENCES sales_returns(id) 
          ON DELETE CASCADE,
        
        CONSTRAINT fk_return_items_product 
          FOREIGN KEY (product_id) 
          REFERENCES products(id) 
          ON DELETE RESTRICT,
        
        -- Check constraints
        CONSTRAINT chk_quantity_positive 
          CHECK (quantity > 0),
        
        CONSTRAINT chk_unit_price_non_negative 
          CHECK (unit_price >= 0)
      );
    `);
    console.log("✅ Table return_items created\n");

    // ========================================
    // 3. CREATE INDEXES
    // ========================================
    console.log("📋 Creating indexes...");

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_sales_returns_return_number 
        ON sales_returns(return_number);
    `);

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_sales_returns_original_sale 
        ON sales_returns(original_sale_id);
    `);

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_sales_returns_branch 
        ON sales_returns(branch_id);
    `);

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_sales_returns_cashier 
        ON sales_returns(cashier_id);
    `);

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_sales_returns_return_date 
        ON sales_returns(return_date);
    `);

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_sales_returns_status 
        ON sales_returns(status);
    `);

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_return_items_return_id 
        ON return_items(return_id);
    `);

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_return_items_product_id 
        ON return_items(product_id);
    `);

    console.log("✅ Indexes created\n");

    // ========================================
    // 4. CREATE TRIGGER: updated_at
    // ========================================
    console.log("📋 Creating trigger for updated_at...");

    // Create trigger function if not exists
    await client.query(`
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = NOW();
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    `);

    await client.query(`
      DROP TRIGGER IF EXISTS update_sales_returns_updated_at ON sales_returns;
    `);

    await client.query(`
      CREATE TRIGGER update_sales_returns_updated_at
        BEFORE UPDATE ON sales_returns
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();
    `);

    console.log("✅ Trigger created\n");

    // ========================================
    // 5. CREATE VIEW: v_sales_returns_detail
    // ========================================
    console.log("📋 Creating view v_sales_returns_detail...");
    await client.query(`
      CREATE OR REPLACE VIEW v_sales_returns_detail AS
      SELECT 
        sr.id,
        sr.return_number,
        sr.original_sale_id,
        sr.original_invoice_number,
        sr.branch_id,
        b.name as branch_name,
        sr.return_date,
        sr.return_reason,
        sr.total_refund,
        sr.refund_method,
        sr.customer_id,
        sr.customer_name,
        sr.cashier_id,
        sr.cashier_name,
        sr.processed_by_user_id,
        u.username as processed_by_username,
        sr.status,
        sr.notes,
        sr.created_at,
        sr.updated_at,
        -- Aggregate return items
        COUNT(ri.id) as total_items,
        SUM(ri.quantity) as total_quantity,
        json_agg(
          json_build_object(
            'id', ri.id,
            'product_id', ri.product_id,
            'product_name', ri.product_name,
            'quantity', ri.quantity,
            'unit_price', ri.unit_price,
            'subtotal', ri.subtotal,
            'reason', ri.reason
          ) ORDER BY ri.created_at
        ) as items
      FROM sales_returns sr
      LEFT JOIN branches b ON sr.branch_id = b.id
      LEFT JOIN users u ON sr.processed_by_user_id = u.id
      LEFT JOIN return_items ri ON sr.id = ri.return_id
      WHERE sr.deleted_at IS NULL
      GROUP BY 
        sr.id, sr.return_number, sr.original_sale_id, 
        sr.original_invoice_number, sr.branch_id, b.name,
        sr.return_date, sr.return_reason, sr.total_refund,
        sr.refund_method, sr.customer_id, sr.customer_name,
        sr.cashier_id, sr.cashier_name, sr.processed_by_user_id,
        u.username, sr.status, sr.notes, sr.created_at, sr.updated_at;
    `);
    console.log("✅ View created\n");

    // ========================================
    // 6. GRANT PERMISSIONS
    // ========================================
    console.log("📋 Granting permissions...");
    await client.query(`
      GRANT SELECT, INSERT, UPDATE, DELETE ON sales_returns TO PUBLIC;
      GRANT SELECT, INSERT, UPDATE, DELETE ON return_items TO PUBLIC;
      GRANT SELECT ON v_sales_returns_detail TO PUBLIC;
    `);
    console.log("✅ Permissions granted\n");

    await client.query("COMMIT");

    console.log("🎉 Migration completed successfully!\n");
    console.log("📊 Summary:");
    console.log("   ✅ Table: sales_returns");
    console.log("   ✅ Table: return_items");
    console.log("   ✅ Indexes: 8 created");
    console.log("   ✅ Trigger: updated_at");
    console.log("   ✅ View: v_sales_returns_detail");
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("❌ Migration failed:", error.message);
    console.error(error);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

migrate().catch(console.error);
