#!/usr/bin/env node

/**
 * Database Setup Script for POS Enterprise
 * Run this script to automatically setup the database
 */

import { exec } from "child_process";
import { promisify } from "util";
import readline from "readline";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const execAsync = promisify(exec);
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

const question = (query) =>
  new Promise((resolve) => rl.question(query, resolve));

async function main() {
  console.log("🗄️  POS Enterprise - Database Setup");
  console.log("=".repeat(50));
  console.log("");

  // Get database configuration
  const dbHost =
    (await question("PostgreSQL Host (localhost): ")) || "localhost";
  const dbPort = (await question("PostgreSQL Port (5432): ")) || "5432";
  const dbName =
    (await question("Database Name (pos_enterprise): ")) || "pos_enterprise";
  const dbUser = (await question("Database User (pos_user): ")) || "pos_user";
  const dbPassword = await question("Database Password: ");
  const pgPassword = await question("PostgreSQL Admin Password: ");

  rl.close();

  console.log("");
  console.log("⚙️  Creating database and user...");

  // Set PGPASSWORD environment variable
  process.env.PGPASSWORD = pgPassword;

  try {
    // Create database and user
    const createDbSql = `
      CREATE DATABASE ${dbName};
      CREATE USER ${dbUser} WITH ENCRYPTED PASSWORD '${dbPassword}';
      GRANT ALL PRIVILEGES ON DATABASE ${dbName} TO ${dbUser};
    `;

    await execAsync(
      `psql -U postgres -h ${dbHost} -p ${dbPort} -c "${createDbSql}"`
    );
    console.log("✓ Database and user created");

    // Import schema
    console.log("");
    console.log("📋 Importing schema...");

    const schemaPath = path.join(__dirname, "src", "database", "schema.sql");

    if (!fs.existsSync(schemaPath)) {
      throw new Error(`Schema file not found: ${schemaPath}`);
    }

    await execAsync(
      `psql -U postgres -h ${dbHost} -p ${dbPort} -d ${dbName} -f "${schemaPath}"`
    );
    console.log("✓ Schema imported successfully");

    // Update .env file
    console.log("");
    console.log("📝 Updating .env file...");

    const envPath = path.join(__dirname, ".env");
    const envExamplePath = path.join(__dirname, ".env.example");

    let envContent = "";

    if (fs.existsSync(envPath)) {
      envContent = fs.readFileSync(envPath, "utf8");
    } else if (fs.existsSync(envExamplePath)) {
      envContent = fs.readFileSync(envExamplePath, "utf8");
    } else {
      throw new Error(".env.example file not found");
    }

    // Update database configuration
    envContent = envContent
      .replace(/DB_HOST=.*/, `DB_HOST=${dbHost}`)
      .replace(/DB_PORT=.*/, `DB_PORT=${dbPort}`)
      .replace(/DB_NAME=.*/, `DB_NAME=${dbName}`)
      .replace(/DB_USER=.*/, `DB_USER=${dbUser}`)
      .replace(/DB_PASSWORD=.*/, `DB_PASSWORD=${dbPassword}`);

    fs.writeFileSync(envPath, envContent);
    console.log("✓ .env file updated");

    console.log("");
    console.log("=".repeat(50));
    console.log("✅ Database setup completed successfully!");
    console.log("");
    console.log("Next steps:");
    console.log("1. Start Redis: redis-server");
    console.log("2. Start the server: npm run dev");
    console.log("3. Test API: curl http://localhost:3001/api/v2/health");
    console.log("");
    console.log("Default login credentials:");
    console.log("  Username: admin");
    console.log("  Password: admin123");
    console.log("");
    console.log("⚠️  Remember to change the default password!");
    console.log("=".repeat(50));
  } catch (error) {
    console.error("");
    console.error("❌ Error during setup:");
    console.error(error.message);
    console.error("");
    console.error("Please make sure:");
    console.error("1. PostgreSQL is installed and running");
    console.error("2. You have the correct admin password");
    console.error("3. The schema.sql file exists");
    process.exit(1);
  }
}

main();
