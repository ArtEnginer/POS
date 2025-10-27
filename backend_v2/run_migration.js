import pg from "pg";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import dotenv from "dotenv";

// Load environment variables
dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const client = new pg.Client({
  host: process.env.DB_HOST || "localhost",
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || "pos_enterprise",
  user: process.env.DB_USER || "pos_user",
  password: process.env.DB_PASSWORD || "admin123",
});

async function runMigration() {
  try {
    await client.connect();
    console.log("Connected to database");

    const migrationPath = path.join(
      __dirname,
      "src/database/migrations/add_receivings.sql"
    );
    const sql = fs.readFileSync(migrationPath, "utf8");

    console.log("Running migration...");
    await client.query(sql);

    console.log("✅ Migration completed successfully!");
  } catch (error) {
    console.error("❌ Migration failed:", error.message);
    if (error.detail) console.error("Detail:", error.detail);
  } finally {
    await client.end();
  }
}

runMigration();
