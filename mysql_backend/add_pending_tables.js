const mysql = require("mysql2/promise");
const fs = require("fs");
const path = require("path");

// Database configuration - update these values to match your setup
const dbConfig = {
  host: process.env.DB_HOST || "localhost",
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD || "",
  database: process.env.DB_NAME || "pos_db",
  port: process.env.DB_PORT || 3306,
};

async function addPendingTables() {
  let connection;

  try {
    console.log("🔌 Connecting to MySQL database...");

    // Create connection
    connection = await mysql.createConnection({
      host: dbConfig.host,
      user: dbConfig.user,
      password: dbConfig.password,
      database: dbConfig.database,
      port: dbConfig.port || 3306,
    });

    console.log("✅ Connected to database:", dbConfig.database);

    // Read SQL file
    const sqlFile = path.join(__dirname, "database", "add_pending_tables.sql");
    const sql = fs.readFileSync(sqlFile, "utf8");

    // Split SQL statements by semicolon and filter out empty statements
    const statements = sql
      .split(";")
      .map((stmt) => stmt.trim())
      .filter((stmt) => stmt.length > 0);

    console.log(`\n📝 Executing ${statements.length} SQL statements...\n`);

    // Execute each statement
    for (let i = 0; i < statements.length; i++) {
      const statement = statements[i];
      console.log(`[${i + 1}/${statements.length}] Executing...`);
      console.log(statement.substring(0, 100) + "...\n");

      await connection.query(statement);
      console.log("✅ Success!\n");
    }

    console.log("🎉 All pending tables created successfully!");
    console.log("\n📋 Tables created:");
    console.log("   - pending_transactions");
    console.log("   - pending_transaction_items");
  } catch (error) {
    console.error("❌ Error:", error.message);
    console.error("\nStack trace:", error.stack);
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
      console.log("\n👋 Database connection closed");
    }
  }
}

// Run the script
addPendingTables();
