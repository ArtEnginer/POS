/**
 * Migration Runner - Add Rounding to Sales
 * Usage: node run_migration.js
 */

import pkg from "pg";
const { Client } = pkg;
import dotenv from "dotenv";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config();

// Database configuration
const dbConfig = {
  host: process.env.DB_HOST || "localhost",
  port: parseInt(process.env.DB_PORT) || 5432,
  database: process.env.DB_NAME || "pos_enterprise",
  user: process.env.DB_USER || "postgres",
  password: process.env.DB_PASSWORD,
};

async function runMigration() {
  const client = new Client(dbConfig);

  try {
    console.log("🔌 Connecting to database...");
    console.log(`   Host: ${dbConfig.host}:${dbConfig.port}`);
    console.log(`   Database: ${dbConfig.database}`);
    console.log(`   User: ${dbConfig.user}`);

    await client.connect();
    console.log("✅ Connected to database successfully!\n");

    // Read migration file
    const migrationPath = path.join(
      __dirname,
      "src",
      "database",
      "migrations",
      "add_rounding_to_sales.sql"
    );

    console.log("📄 Reading migration file...");
    console.log(`   Path: ${migrationPath}\n`);

    const migrationSQL = fs.readFileSync(migrationPath, "utf8");

    console.log(
      "🚀 Running migration: Add rounding and grand_total to sales table"
    );
    console.log(
      "═══════════════════════════════════════════════════════════\n"
    );

    // Execute migration
    await client.query(migrationSQL);

    console.log("\n✅ Migration completed successfully!");
    console.log(
      "═══════════════════════════════════════════════════════════\n"
    );

    // Verify the changes
    console.log("🔍 Verifying migration...");
    const verifyResult = await client.query(`
      SELECT column_name, data_type, column_default, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'sales' AND column_name IN ('rounding', 'grand_total')
      ORDER BY column_name;
    `);

    if (verifyResult.rows.length === 2) {
      console.log("✅ Columns added successfully:\n");
      verifyResult.rows.forEach((col) => {
        console.log(`   - ${col.column_name}`);
        console.log(`     Type: ${col.data_type}`);
        console.log(`     Default: ${col.column_default || "NULL"}`);
        console.log(`     Nullable: ${col.is_nullable}`);
        console.log("");
      });
    } else {
      console.log(
        "⚠️  Warning: Expected 2 columns, found",
        verifyResult.rows.length
      );
    }

    // Check if index was created
    const indexResult = await client.query(`
      SELECT indexname
      FROM pg_indexes
      WHERE tablename = 'sales' AND indexname = 'idx_sales_grand_total';
    `);

    if (indexResult.rows.length > 0) {
      console.log("✅ Index created: idx_sales_grand_total\n");
    }

    // Show sample data
    console.log("📊 Sample data from sales table:");
    const sampleResult = await client.query(`
      SELECT 
        id, 
        sale_number, 
        total_amount, 
        rounding, 
        grand_total,
        paid_amount,
        change_amount
      FROM sales
      ORDER BY id DESC
      LIMIT 5;
    `);

    if (sampleResult.rows.length > 0) {
      console.log("   Found", sampleResult.rows.length, "recent sales:");
      sampleResult.rows.forEach((row) => {
        console.log(
          `   - ${row.sale_number}: Total=${row.total_amount}, Rounding=${row.rounding}, GrandTotal=${row.grand_total}`
        );
      });
    } else {
      console.log("   No sales data yet (table is empty)");
    }

    console.log(
      "\n🎉 All done! Your database is ready to store rounding data."
    );
  } catch (error) {
    console.error("\n❌ Migration failed!");
    console.error(
      "═══════════════════════════════════════════════════════════"
    );
    console.error("Error:", error.message);
    console.error("\nStack trace:");
    console.error(error.stack);
    console.error(
      "═══════════════════════════════════════════════════════════\n"
    );
    process.exit(1);
  } finally {
    await client.end();
    console.log("\n🔌 Database connection closed.");
  }
}

// Run migration
console.log("\n╔═══════════════════════════════════════════════════════════╗");
console.log("║     POS Enterprise - Database Migration Runner          ║");
console.log("║     Migration: Add Rounding to Sales                     ║");
console.log("╚═══════════════════════════════════════════════════════════╝\n");

runMigration();
