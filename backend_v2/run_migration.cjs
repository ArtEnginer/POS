// Script to run SQL migration for cost price and profit tracking
// Run: node run_migration.cjs

const { Pool } = require("pg");
const fs = require("fs");
const path = require("path");
require("dotenv").config();

const pool = new Pool({
  host: process.env.DB_HOST || "localhost",
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || "pos_enterprise",
  user: process.env.DB_USER || "postgres",
  password: process.env.DB_PASSWORD || "postgres",
});

async function runMigration() {
  const client = await pool.connect();

  try {
    console.log(
      "🚀 Starting migration: Add cost price and profit tracking...\n"
    );

    // Read migration file
    const migrationPath = path.join(
      __dirname,
      "src",
      "database",
      "migrations",
      "add_cost_profit_columns.sql"
    );
    const migrationSQL = fs.readFileSync(migrationPath, "utf8");

    // Execute migration
    await client.query("BEGIN");

    console.log("📝 Executing migration SQL...");
    await client.query(migrationSQL);

    await client.query("COMMIT");

    console.log("✅ Migration completed successfully!\n");

    // Verify changes
    console.log("🔍 Verifying new columns...\n");
    const result = await client.query(`
      SELECT 
        table_name,
        column_name, 
        data_type,
        is_nullable
      FROM information_schema.columns 
      WHERE table_name IN ('sales', 'sale_items')
      AND column_name IN ('cost_price', 'total_cost', 'gross_profit', 'profit_margin', 'cashier_location', 'device_info', 'item_profit')
      ORDER BY table_name, column_name;
    `);

    console.table(result.rows);

    console.log("\n✅ All done!");
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

runMigration();
