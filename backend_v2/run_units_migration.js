/**
 * Migration Runner - Create Units Table
 * Usage: node run_units_migration.js
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
      "create_units_table.sql"
    );

    console.log("📄 Reading migration file...");
    console.log(`   Path: ${migrationPath}\n`);

    const migrationSQL = fs.readFileSync(migrationPath, "utf8");

    console.log("🚀 Running migration: Create units table");
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
      WHERE table_name = 'units'
      ORDER BY ordinal_position;
    `);

    if (verifyResult.rows.length > 0) {
      console.log("✅ Table created successfully with columns:\n");
      verifyResult.rows.forEach((col) => {
        console.log(`   - ${col.column_name}`);
        console.log(`     Type: ${col.data_type}`);
        console.log(`     Default: ${col.column_default || "NULL"}`);
        console.log(`     Nullable: ${col.is_nullable}`);
        console.log("");
      });
    } else {
      console.log("⚠️  Warning: Table not created");
    }

    // Show sample data
    console.log("📊 Units data:");
    const sampleResult = await client.query(`
      SELECT 
        id, 
        name, 
        description,
        is_active
      FROM units
      ORDER BY name;
    `);

    if (sampleResult.rows.length > 0) {
      console.log(`   Found ${sampleResult.rows.length} units:`);
      sampleResult.rows.forEach((row) => {
        console.log(
          `   - ${row.name}: ${row.description || "(no description)"}`
        );
      });
    } else {
      console.log("   No units data yet (table is empty)");
    }

    console.log("\n🎉 All done! Your database now has units table.");
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
console.log("║     Migration: Create Units Table                        ║");
console.log("╚═══════════════════════════════════════════════════════════╝\n");

runMigration();
