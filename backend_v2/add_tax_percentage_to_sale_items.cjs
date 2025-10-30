const { Pool } = require("pg");
require("dotenv").config();

const pool = new Pool({
  host: process.env.DB_HOST || "localhost",
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || "pos_db",
  user: process.env.DB_USER || "postgres",
  password: process.env.DB_PASSWORD || "postgres",
});

async function addTaxPercentageColumn() {
  const client = await pool.connect();

  try {
    console.log("🔧 Starting migration: Add tax_percentage to sale_items...");

    await client.query("BEGIN");

    // Check if column already exists
    const checkColumn = await client.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'sale_items' 
      AND column_name = 'tax_percentage'
    `);

    if (checkColumn.rows.length === 0) {
      console.log("📝 Adding tax_percentage column...");

      // Add tax_percentage column
      await client.query(`
        ALTER TABLE sale_items 
        ADD COLUMN tax_percentage DECIMAL(5, 2) DEFAULT 0
      `);

      console.log("✅ Column tax_percentage added successfully");
    } else {
      console.log("ℹ️  Column tax_percentage already exists");
    }

    // Update existing records to calculate tax_percentage from tax_amount
    console.log("📊 Updating existing records...");

    await client.query(`
      UPDATE sale_items 
      SET tax_percentage = CASE 
        WHEN subtotal > 0 AND tax_amount > 0 
        THEN ROUND((tax_amount / subtotal * 100)::numeric, 2)
        ELSE 0 
      END
      WHERE tax_percentage IS NULL OR tax_percentage = 0
    `);

    const updateCount = await client.query(`
      SELECT COUNT(*) FROM sale_items WHERE tax_percentage > 0
    `);

    console.log(
      `✅ Updated ${updateCount.rows[0].count} records with calculated tax_percentage`
    );

    await client.query("COMMIT");
    console.log("✅ Migration completed successfully!");

    // Show sample data
    console.log("\n📊 Sample data after migration:");
    const sample = await client.query(`
      SELECT 
        product_name,
        quantity,
        unit_price,
        discount_percentage,
        discount_amount,
        tax_percentage,
        tax_amount,
        subtotal,
        total
      FROM sale_items 
      WHERE tax_amount > 0
      LIMIT 5
    `);

    console.table(sample.rows);
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("❌ Migration failed:", error.message);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

// Run migration
addTaxPercentageColumn()
  .then(() => {
    console.log("\n✅ All done! You can now use tax_percentage in sale_items.");
    process.exit(0);
  })
  .catch((error) => {
    console.error("\n❌ Migration failed:", error);
    process.exit(1);
  });
