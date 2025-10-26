/**
 * Initialize database with seed data
 * Run this script after creating the schema
 */

import bcrypt from "bcryptjs";
import crypto from "crypto";
import db from "../config/database.js";
import logger from "../utils/logger.js";

async function seedDatabase() {
  try {
    logger.info("Starting database seeding...");

    // 1. Create default branches
    logger.info("Creating default branches...");

    const headOfficeApiKey = crypto.randomBytes(32).toString("hex");
    const branch1ApiKey = crypto.randomBytes(32).toString("hex");

    // Insert head office
    const headOfficeResult = await db.query(
      `INSERT INTO branches (code, name, address, city, phone, email, is_active, is_head_office, api_key, timezone)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
       ON CONFLICT (code) DO UPDATE SET api_key = EXCLUDED.api_key
       RETURNING id, code, name, api_key`,
      [
        "HO001",
        "Head Office",
        "Jl. Contoh No. 123",
        "Jakarta",
        "021-12345678",
        "headoffice@pos.com",
        true,
        true,
        headOfficeApiKey,
        "Asia/Jakarta",
      ]
    );

    const headOffice = headOfficeResult.rows[0];
    logger.info(`✓ Created Head Office (${headOffice.code})`);
    logger.info(`  API Key: ${headOffice.api_key}`);

    // Insert branch 1
    const branch1Result = await db.query(
      `INSERT INTO branches (code, name, address, city, phone, email, is_active, is_head_office, api_key, timezone)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
       ON CONFLICT (code) DO UPDATE SET api_key = EXCLUDED.api_key
       RETURNING id, code, name, api_key`,
      [
        "BR001",
        "Branch 1",
        "Jl. Branch 1 No. 456",
        "Bandung",
        "022-87654321",
        "branch1@pos.com",
        true,
        false,
        branch1ApiKey,
        "Asia/Jakarta",
      ]
    );

    const branch1 = branch1Result.rows[0];
    logger.info(`✓ Created Branch 1 (${branch1.code})`);
    logger.info(`  API Key: ${branch1.api_key}`);

    // 2. Create default users
    logger.info("\nCreating default users...");

    // Hash passwords
    const adminPassword = await bcrypt.hash("admin123", 10);
    const cashierPassword = await bcrypt.hash("cashier123", 10);

    // Insert super admin
    const adminResult = await db.query(
      `INSERT INTO users (username, email, password_hash, full_name, role, status)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (username) DO UPDATE SET password_hash = EXCLUDED.password_hash
       RETURNING id, username, email, role`,
      [
        "admin",
        "admin@pos.com",
        adminPassword,
        "Super Administrator",
        "super_admin",
        "active",
      ]
    );

    const admin = adminResult.rows[0];
    logger.info(`✓ Created admin user`);
    logger.info(`  Username: ${admin.username}`);
    logger.info(`  Password: admin123`);
    logger.info(`  Role: ${admin.role}`);

    // Insert cashier
    const cashierResult = await db.query(
      `INSERT INTO users (username, email, password_hash, full_name, role, status)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (username) DO UPDATE SET password_hash = EXCLUDED.password_hash
       RETURNING id, username, email, role`,
      [
        "cashier1",
        "cashier1@pos.com",
        cashierPassword,
        "Cashier One",
        "cashier",
        "active",
      ]
    );

    const cashier = cashierResult.rows[0];
    logger.info(`✓ Created cashier user`);
    logger.info(`  Username: ${cashier.username}`);
    logger.info(`  Password: cashier123`);
    logger.info(`  Role: ${cashier.role}`);

    // 3. Assign users to branches
    logger.info("\nAssigning users to branches...");

    // Assign admin to head office (default)
    await db.query(
      `INSERT INTO user_branches (user_id, branch_id, is_default)
       VALUES ($1, $2, $3)
       ON CONFLICT (user_id, branch_id) DO UPDATE SET is_default = EXCLUDED.is_default`,
      [admin.id, headOffice.id, true]
    );

    // Assign admin to branch 1
    await db.query(
      `INSERT INTO user_branches (user_id, branch_id, is_default)
       VALUES ($1, $2, $3)
       ON CONFLICT (user_id, branch_id) DO NOTHING`,
      [admin.id, branch1.id, false]
    );

    logger.info(`✓ Assigned admin to all branches`);

    // Assign cashier to branch 1 (default)
    await db.query(
      `INSERT INTO user_branches (user_id, branch_id, is_default)
       VALUES ($1, $2, $3)
       ON CONFLICT (user_id, branch_id) DO UPDATE SET is_default = EXCLUDED.is_default`,
      [cashier.id, branch1.id, true]
    );

    logger.info(`✓ Assigned cashier1 to Branch 1`);

    // 4. Create sample categories
    logger.info("\nCreating sample categories...");

    const categories = [
      ["Elektronik", "Produk elektronik dan gadget", 1],
      ["Makanan & Minuman", "Produk makanan dan minuman", 2],
      ["Pakaian", "Produk pakaian dan fashion", 3],
      ["Kesehatan", "Produk kesehatan dan kecantikan", 4],
      ["Alat Tulis", "Produk alat tulis dan kantor", 5],
    ];

    for (const [name, description, sortOrder] of categories) {
      await db.query(
        `INSERT INTO categories (name, description, sort_order, is_active)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT DO NOTHING`,
        [name, description, sortOrder, true]
      );
    }

    logger.info(`✓ Created ${categories.length} categories`);

    // 5. Summary
    logger.info("\n" + "=".repeat(60));
    logger.info("DATABASE SEEDING COMPLETED SUCCESSFULLY!");
    logger.info("=".repeat(60));
    logger.info("\n📊 SUMMARY:");
    logger.info("\nBranches:");
    logger.info(`  • ${headOffice.name} (${headOffice.code})`);
    logger.info(`    API Key: ${headOffice.api_key}`);
    logger.info(`  • ${branch1.name} (${branch1.code})`);
    logger.info(`    API Key: ${branch1.api_key}`);
    logger.info("\nUsers:");
    logger.info(`  • admin / admin123 (super_admin)`);
    logger.info(`  • cashier1 / cashier123 (cashier)`);
    logger.info("\n💡 Save these credentials for testing!");
    logger.info("=".repeat(60) + "\n");

    process.exit(0);
  } catch (error) {
    logger.error("Error seeding database:", error);
    process.exit(1);
  }
}

// Run seeding
seedDatabase();
