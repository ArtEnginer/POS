const { Client } = require("pg");

const client = new Client({
  host: "localhost",
  port: 5432,
  database: "pos_enterprise",
  user: "postgres",
  password: "admin123",
});

async function addStatusColumn() {
  try {
    await client.connect();
    console.log("Connected to database");

    // Add status column
    await client.query(`
      ALTER TABLE purchase_returns 
      ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'DRAFT'
    `);

    console.log("✓ Added status column to purchase_returns table");

    // Update existing records to have DRAFT status
    const updateResult = await client.query(`
      UPDATE purchase_returns 
      SET status = 'DRAFT' 
      WHERE status IS NULL
    `);

    console.log(
      `✓ Updated ${updateResult.rowCount} existing records to DRAFT status`
    );

    await client.end();
    console.log("Migration completed successfully!");
  } catch (error) {
    console.error("Error:", error.message);
    process.exit(1);
  }
}

addStatusColumn();
