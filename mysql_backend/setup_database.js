// =====================================================
// Setup Database Script - Run SQL using Node.js
// =====================================================

require("dotenv").config();
const mysql = require("mysql2/promise");
const fs = require("fs").promises;
const path = require("path");

async function setupDatabase() {
  console.log("========================================");
  console.log("   POS MySQL Database Setup");
  console.log("========================================\n");

  const config = {
    host: process.env.DB_HOST || "localhost",
    port: parseInt(process.env.DB_PORT) || 3306,
    user: process.env.DB_USER || "root",
    password: process.env.DB_PASSWORD || "",
  };

  console.log("Database Configuration:");
  console.log(`  Host: ${config.host}`);
  console.log(`  Port: ${config.port}`);
  console.log(`  User: ${config.user}`);
  console.log(`  Database: ${process.env.DB_NAME || "pos_db"}\n`);

  let connection;

  try {
    // Connect to MySQL (without database)
    console.log("Connecting to MySQL server...");
    connection = await mysql.createConnection(config);
    console.log("✓ Connected to MySQL server\n");

    // Create database if not exists
    const dbName = process.env.DB_NAME || "pos_db";
    console.log(`Creating database '${dbName}' if not exists...`);
    await connection.query(
      `CREATE DATABASE IF NOT EXISTS ${dbName} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`
    );
    console.log(`✓ Database '${dbName}' ready\n`);

    // Switch to database
    await connection.query(`USE ${dbName}`);

    // Read SQL file
    const sqlFile = path.join(__dirname, "database", "create_tables.sql");
    console.log("Reading SQL file...");
    const sql = await fs.readFile(sqlFile, "utf8");

    // Remove comments and split by semicolon
    const cleanSql = sql
      .split("\n")
      .filter((line) => !line.trim().startsWith("--"))
      .join("\n");

    // Split into statements (but not inside parentheses)
    const statements = [];
    let currentStatement = "";
    let parenCount = 0;

    for (let i = 0; i < cleanSql.length; i++) {
      const char = cleanSql[i];
      currentStatement += char;

      if (char === "(") parenCount++;
      if (char === ")") parenCount--;

      if (char === ";" && parenCount === 0) {
        const stmt = currentStatement.trim();
        if (stmt.length > 0 && !stmt.startsWith("USE")) {
          statements.push(stmt);
        }
        currentStatement = "";
      }
    }

    console.log(`✓ Found ${statements.length} SQL statements\n`);
    console.log("Executing SQL statements...\n");

    // Execute each statement
    let executedCount = 0;
    let tableCount = 0;
    for (const statement of statements) {
      try {
        await connection.query(statement);
        executedCount++;

        // Show progress for CREATE TABLE
        if (statement.toUpperCase().includes("CREATE TABLE")) {
          const match = statement.match(
            /CREATE TABLE (?:IF NOT EXISTS )?`?(\w+)`?/i
          );
          if (match) {
            tableCount++;
            console.log(`  ✓ Created table: ${match[1]}`);
          }
        } else if (statement.toUpperCase().includes("INSERT INTO")) {
          const match = statement.match(/INSERT INTO `?(\w+)`?/i);
          if (match) {
            console.log(`  ✓ Inserted default data into: ${match[1]}`);
          }
        }
      } catch (error) {
        // Ignore "table already exists" errors
        if (error.code === "ER_TABLE_EXISTS_ERROR") {
          console.log(`  ⚠ Table already exists (skipped)`);
        } else {
          console.error(`  ✗ Error: ${error.message}`);
        }
      }
    }

    console.log(`\n✓ Executed ${executedCount} statements successfully`);
    console.log(`✓ Created ${tableCount} tables\n`);

    // Show created tables
    console.log("Database Tables:");
    const [tables] = await connection.query("SHOW TABLES");
    tables.forEach((row, index) => {
      const tableName = Object.values(row)[0];
      console.log(`  ${index + 1}. ${tableName}`);
    });

    console.log(`\n✓ Total tables: ${tables.length}\n`);

    // Show table stats
    console.log("Table Statistics:");
    for (const row of tables) {
      const tableName = Object.values(row)[0];
      const [stats] = await connection.query(
        `SELECT COUNT(*) as count FROM ${tableName}`
      );
      console.log(`  ${tableName}: ${stats[0].count} rows`);
    }

    console.log("\n========================================");
    console.log("   Database Setup Complete!");
    console.log("========================================\n");
    console.log("Next steps:");
    console.log("  1. Start the backend server: npm start");
    console.log("  2. Run the Flutter application");
    console.log("  3. Configure MySQL settings in the app");
    console.log("  4. Test synchronization\n");
  } catch (error) {
    console.error("\n✗ Error:", error.message);
    console.error("\nPlease ensure:");
    console.error("  1. MySQL server is running");
    console.error("  2. Credentials in .env are correct");
    console.error("  3. MySQL user has necessary permissions\n");
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

// Run setup
setupDatabase().catch(console.error);
