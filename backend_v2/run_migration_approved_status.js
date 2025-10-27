/**
 * Migration Script: Add 'approved' status to purchase_status enum
 *
 * This script adds the 'approved' status to the purchase_status enum type
 * to support the PO approval workflow before receiving.
 *
 * Run with: node run_migration_approved_status.js
 */

import pg from "pg";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import dotenv from "dotenv";

dotenv.config();

const { Pool } = pg;
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Database configuration
const pool = new Pool({
  host: process.env.DB_HOST || "localhost",
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || "pos_enterprise",
  user: process.env.DB_USER || "postgres",
  password: process.env.DB_PASSWORD || "admin123",
});

async function runMigration() {
  const client = await pool.connect();

  try {
    console.log(
      "🚀 Starting migration: Add approved status to purchase_status enum...\n"
    );

    // Read migration file
    const migrationPath = path.join(
      __dirname,
      "src",
      "database",
      "migrations",
      "004_add_approved_status_to_purchase.sql"
    );
    const migrationSQL = fs.readFileSync(migrationPath, "utf8");

    console.log("📖 Migration file loaded:", migrationPath);
    console.log("\n--- Migration SQL ---");
    console.log(migrationSQL);
    console.log("--- End of SQL ---\n");

    // Execute migration
    await client.query(migrationSQL);

    console.log("✅ Migration completed successfully!\n");

    // Verify the change
    const result = await client.query(`
      SELECT enumlabel 
      FROM pg_enum 
      WHERE enumtypid = 'purchase_status'::regtype 
      ORDER BY enumsortorder;
    `);

    console.log("📊 Current purchase_status enum values:");
    result.rows.forEach((row) => {
      console.log(`  - ${row.enumlabel}`);
    });

    console.log("\n✨ Migration verification passed!");
  } catch (error) {
    console.error("❌ Migration failed:", error.message);
    console.error("\nFull error:", error);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

// Run migration
runMigration().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
