/**
 * ============================================
 * SETUP DATABASE - COMPLETE RESET & REINSTALL
 * ============================================
 *
 * Script ini akan:
 * 1. DROP semua table lama (HATI-HATI: DATA AKAN HILANG!)
 * 2. CREATE ulang semua table dengan schema terbaru
 * 3. Setup quantity dengan DECIMAL (mendukung pecahan)
 * 4. Insert data default (admin user, branch, dll)
 *
 * Run dengan: node setup_database_complete.js
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

async function setupDatabase() {
  const client = await pool.connect();

  try {
    // Konfirmasi dari user
    console.log(
      "⚠️  WARNING: Ini akan MENGHAPUS semua data dan table yang ada!"
    );
    console.log("⚠️  Pastikan Anda sudah backup database jika diperlukan.");
    console.log("");

    // Read complete schema SQL file
    const schemaPath = path.join(
      __dirname,
      "src",
      "database",
      "migrations",
      "COMPLETE_SCHEME_V4.sql"
    );

    console.log("📖 Reading complete schema file:", schemaPath);

    if (!fs.existsSync(schemaPath)) {
      throw new Error(`Schema file not found: ${schemaPath}`);
    }

    const schemaSQL = fs.readFileSync(schemaPath, "utf8");

    console.log("✅ Schema file loaded successfully");
    console.log("");

    const startTime = Date.now();

    await client.query(schemaSQL);

    const endTime = Date.now();
    const duration = ((endTime - startTime) / 1000).toFixed(2);

    console.log("");
    console.log("✅ Database setup completed in " + duration + " seconds");
    console.log("");

    // Verify tables created
    console.log("🔍 Verifying database structure...");
    console.log("");

    const tablesQuery = `
      SELECT table_name, 
             (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name AND table_schema = 'public') as column_count
      FROM information_schema.tables t
      WHERE table_schema = 'public' 
        AND table_type = 'BASE TABLE'
      ORDER BY table_name;
    `;

    const tablesResult = await client.query(tablesQuery);

    console.log("📊 CREATED TABLES:");
    console.log("┌─────────────────────────────┬──────────┐");
    console.log("│ Table Name                  │ Columns  │");
    console.log("├─────────────────────────────┼──────────┤");

    tablesResult.rows.forEach((row) => {
      console.log(
        `│ ${row.table_name.padEnd(27)} │ ${String(row.column_count).padEnd(
          8
        )} │`
      );
    });

    console.log("└─────────────────────────────┴──────────┘");
    console.log("");

    console.log(
      "└─────────────────────────┴──────────────────────────┴───────────┴────────┘"
    );
    console.log("");

    // Show default data
    console.log("👤 DEFAULT CREDENTIALS:");
    console.log("   Username: admin");
    console.log("   Password: admin123");
    console.log("   Role: super_admin");
    console.log("");

    console.log("🏢 DEFAULT BRANCH:");
    console.log("   Code: HQ");
    console.log("   Name: Head Office");
    console.log("");

    console.log(
      "╔══════════════════════════════════════════════════════════════════╗"
    );
    console.log(
      "║                    ✅ SETUP COMPLETED!                            ║"
    );
    console.log(
      "╚══════════════════════════════════════════════════════════════════╝"
    );
  } catch (error) {
    console.error("");
    console.error("❌ DATABASE SETUP FAILED!");
    console.error("");
    console.error("Error:", error.message);

    if (error.stack) {
      console.error("");
      console.error("Stack trace:");
      console.error(error.stack);
    }

    console.error("");
    console.error("💡 TROUBLESHOOTING:");
    console.error("   1. Pastikan PostgreSQL sudah running");
    console.error(
      "   2. Check .env file (DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD)"
    );
    console.error(
      "   3. Pastikan user PostgreSQL punya permission CREATE/DROP"
    );
    console.error("   4. Database 'pos_enterprise' sudah dibuat");
    console.error("");

    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

// Run setup
console.log("");
setupDatabase().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
