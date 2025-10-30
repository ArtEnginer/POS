// Migration script untuk menambahkan fitur Cost & Profit Tracking + Cashier Settings
// Untuk database yang sudah ada (bukan fresh install)

const { Pool } = require("pg");
require("dotenv").config();

const pool = new Pool({
  host: process.env.DB_HOST || "localhost",
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER || "postgres",
  password: process.env.DB_PASSWORD || "postgres",
  database: process.env.DB_NAME || "pos_enterprise",
});

async function runMigration() {
  const client = await pool.connect();

  try {
    console.log("🚀 Starting migration: Cost & Profit + Cashier Settings...\n");

    await client.query("BEGIN");

    // 1. Add cashier_settings table
    console.log("📝 Creating cashier_settings table...");
    await client.query(`
      CREATE TABLE IF NOT EXISTS cashier_settings (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        branch_id INTEGER NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
        
        -- Device Information
        device_name VARCHAR(100) NOT NULL DEFAULT 'Kasir-1',
        device_type VARCHAR(50) DEFAULT 'windows',
        device_identifier VARCHAR(255),
        
        -- Location Information
        cashier_location VARCHAR(255),
        counter_number VARCHAR(20),
        floor_level VARCHAR(20),
        
        -- Display & UI Settings
        receipt_printer VARCHAR(255),
        cash_drawer_port VARCHAR(50),
        display_type VARCHAR(50) DEFAULT 'standard',
        theme_preference VARCHAR(50) DEFAULT 'light',
        
        -- Operational Settings
        is_active BOOLEAN DEFAULT true,
        allow_offline_mode BOOLEAN DEFAULT true,
        auto_print_receipt BOOLEAN DEFAULT true,
        require_customer_display BOOLEAN DEFAULT false,
        
        -- Additional Settings (JSON for flexibility)
        settings JSONB DEFAULT '{}',
        
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        
        UNIQUE(user_id, branch_id)
      );
    `);

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_cashier_settings_user ON cashier_settings(user_id);
    `);
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_cashier_settings_branch ON cashier_settings(branch_id);
    `);
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_cashier_settings_active ON cashier_settings(is_active);
    `);

    // 2. Add columns to sales table
    console.log("📝 Adding cost/profit columns to sales table...");
    await client.query(`
      ALTER TABLE sales 
      ADD COLUMN IF NOT EXISTS total_cost DECIMAL(15, 2) DEFAULT 0,
      ADD COLUMN IF NOT EXISTS gross_profit DECIMAL(15, 2) DEFAULT 0,
      ADD COLUMN IF NOT EXISTS profit_margin DECIMAL(5, 2) DEFAULT 0,
      ADD COLUMN IF NOT EXISTS cashier_location VARCHAR(255),
      ADD COLUMN IF NOT EXISTS device_info JSONB;
    `);

    // 3. Add columns to sale_items table
    console.log("📝 Adding cost/profit columns to sale_items table...");

    // Check if columns already exist
    const checkColumns = await client.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'sale_items' 
      AND column_name IN ('branch_id', 'cost_price', 'total_cost', 'item_profit')
    `);

    const existingColumns = checkColumns.rows.map((r) => r.column_name);

    if (!existingColumns.includes("branch_id")) {
      await client.query(`
        ALTER TABLE sale_items 
        ADD COLUMN branch_id INTEGER REFERENCES branches(id);
      `);

      // Populate branch_id from sales table
      await client.query(`
        UPDATE sale_items si
        SET branch_id = s.branch_id
        FROM sales s
        WHERE si.sale_id = s.id AND si.branch_id IS NULL;
      `);

      // Make it NOT NULL after populating
      await client.query(`
        ALTER TABLE sale_items 
        ALTER COLUMN branch_id SET NOT NULL;
      `);

      await client.query(`
        CREATE INDEX idx_sale_items_branch ON sale_items(branch_id);
      `);
    }

    if (!existingColumns.includes("cost_price")) {
      await client.query(`
        ALTER TABLE sale_items 
        ADD COLUMN cost_price DECIMAL(15, 2);
      `);
    }

    // Drop computed columns if they exist (can't add GENERATED ALWAYS to existing column)
    if (existingColumns.includes("total_cost")) {
      await client.query(
        `ALTER TABLE sale_items DROP COLUMN IF EXISTS total_cost CASCADE;`
      );
    }
    if (existingColumns.includes("item_profit")) {
      await client.query(
        `ALTER TABLE sale_items DROP COLUMN IF EXISTS item_profit CASCADE;`
      );
    }

    // Add computed columns
    await client.query(`
      ALTER TABLE sale_items 
      ADD COLUMN total_cost DECIMAL(15, 2) GENERATED ALWAYS AS (cost_price * quantity) STORED;
    `);

    await client.query(`
      ALTER TABLE sale_items 
      ADD COLUMN item_profit DECIMAL(15, 2) GENERATED ALWAYS AS (total - (cost_price * quantity)) STORED;
    `);

    // 4. Create trigger function for auto-calculate profit
    console.log("📝 Creating trigger function for profit calculation...");
    await client.query(`
      CREATE OR REPLACE FUNCTION calculate_sale_totals()
      RETURNS TRIGGER AS $$
      DECLARE
        v_total_cost DECIMAL(15, 2);
        v_total_amount DECIMAL(15, 2);
        v_gross_profit DECIMAL(15, 2);
        v_profit_margin DECIMAL(5, 2);
      BEGIN
        -- Calculate totals from sale_items
        SELECT 
          COALESCE(SUM(total_cost), 0),
          COALESCE(SUM(total), 0)
        INTO v_total_cost, v_total_amount
        FROM sale_items
        WHERE sale_id = NEW.sale_id;
        
        -- Calculate profit
        v_gross_profit := v_total_amount - v_total_cost;
        
        -- Calculate profit margin (avoid division by zero)
        IF v_total_amount > 0 THEN
          v_profit_margin := (v_gross_profit / v_total_amount) * 100;
        ELSE
          v_profit_margin := 0;
        END IF;
        
        -- Update sales table
        UPDATE sales
        SET 
          total_cost = v_total_cost,
          gross_profit = v_gross_profit,
          profit_margin = v_profit_margin
        WHERE id = NEW.sale_id;
        
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    `);

    // Drop trigger if exists
    await client.query(
      `DROP TRIGGER IF EXISTS trigger_calculate_sale_totals ON sale_items;`
    );

    // Create trigger
    await client.query(`
      CREATE TRIGGER trigger_calculate_sale_totals
      AFTER INSERT OR UPDATE ON sale_items
      FOR EACH ROW
      EXECUTE FUNCTION calculate_sale_totals();
    `);

    // 5. Create trigger for cashier_settings updated_at
    console.log("📝 Creating trigger for cashier_settings...");
    await client.query(
      `DROP TRIGGER IF EXISTS update_cashier_settings_timestamp ON cashier_settings;`
    );
    await client.query(`
      CREATE TRIGGER update_cashier_settings_timestamp 
      BEFORE UPDATE ON cashier_settings 
      FOR EACH ROW 
      EXECUTE FUNCTION update_updated_at();
    `);

    // 6. Create views for profit analysis
    console.log("📝 Creating profit analysis views...");

    // Drop existing views first
    await client.query(`DROP VIEW IF EXISTS v_sales_profit_analysis CASCADE;`);
    await client.query(`DROP VIEW IF EXISTS v_sale_items_profit CASCADE;`);

    await client.query(`
      CREATE VIEW v_sales_profit_analysis AS
      SELECT 
        s.id,
        s.sale_number,
        s.sale_date,
        b.name as branch_name,
        u.full_name as cashier_name,
        c.name as customer_name,
        s.subtotal,
        s.discount_amount,
        s.tax_amount,
        s.total_amount,
        s.total_cost,
        s.gross_profit,
        s.profit_margin,
        s.cashier_location,
        s.device_info,
        s.payment_method,
        s.status,
        COUNT(si.id) as total_items,
        SUM(si.quantity) as total_quantity
      FROM sales s
      LEFT JOIN branches b ON s.branch_id = b.id
      LEFT JOIN users u ON s.cashier_id = u.id
      LEFT JOIN customers c ON s.customer_id = c.id
      LEFT JOIN sale_items si ON s.id = si.sale_id
      GROUP BY s.id, b.name, u.full_name, c.name;
    `);

    await client.query(`
      CREATE VIEW v_sale_items_profit AS
      SELECT 
        si.id,
        si.sale_id,
        s.sale_number,
        s.sale_date,
        b.name as branch_name,
        si.product_id,
        si.product_name,
        si.sku,
        si.quantity,
        si.unit_price,
        si.cost_price,
        si.total_cost,
        si.total,
        si.item_profit,
        CASE 
          WHEN si.total > 0 THEN ((si.item_profit / si.total) * 100)
          ELSE 0
        END as item_profit_margin
      FROM sale_items si
      JOIN sales s ON si.sale_id = s.id
      JOIN branches b ON si.branch_id = b.id;
    `);

    await client.query("COMMIT");

    console.log("\n✅ Migration completed successfully!\n");

    // Verify results
    console.log("🔍 Verifying migration...\n");

    const tableCheck = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name = 'cashier_settings'
    `);

    const columnsCheck = await client.query(`
      SELECT table_name, column_name, data_type, is_nullable
      FROM information_schema.columns 
      WHERE table_name IN ('sales', 'sale_items') 
      AND column_name IN ('total_cost', 'gross_profit', 'profit_margin', 'cashier_location', 'device_info', 'branch_id', 'cost_price', 'item_profit')
      ORDER BY table_name, column_name
    `);

    console.table(columnsCheck.rows);

    const viewsCheck = await client.query(`
      SELECT table_name 
      FROM information_schema.views 
      WHERE table_schema = 'public' 
      AND table_name LIKE 'v_%profit%'
    `);

    console.log("\n📊 Views created:");
    console.table(viewsCheck.rows);

    console.log("\n✅ All done!");
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("❌ Migration failed:", error);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

runMigration().catch(console.error);
