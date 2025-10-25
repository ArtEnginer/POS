import pkg from "pg";
const { Pool } = pkg;
import dotenv from "dotenv";

dotenv.config();

// PostgreSQL Connection Pool Configuration
const poolConfig = {
  host: process.env.DB_HOST || "localhost",
  port: parseInt(process.env.DB_PORT) || 5432,
  database: process.env.DB_NAME || "pos_enterprise",
  user: process.env.DB_USER || "postgres",
  password: process.env.DB_PASSWORD,
  min: parseInt(process.env.DB_POOL_MIN) || 2,
  max: parseInt(process.env.DB_POOL_MAX) || 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: parseInt(process.env.DB_CONNECTION_TIMEOUT) || 30000,

  // Advanced configuration
  application_name: "pos_enterprise_api",
  statement_timeout: 60000, // 60 seconds
  query_timeout: 60000,

  // SSL untuk production (optional)
  ssl:
    process.env.NODE_ENV === "production"
      ? {
          rejectUnauthorized: false,
        }
      : false,
};

// Create connection pool
const pool = new Pool(poolConfig);

// Pool error handler
pool.on("error", (err, client) => {
  console.error("Unexpected error on idle PostgreSQL client", err);
  process.exit(-1);
});

// Pool connection handler
pool.on("connect", (client) => {
  console.log("New PostgreSQL client connected");
});

// Pool remove handler
pool.on("remove", (client) => {
  console.log("PostgreSQL client removed from pool");
});

/**
 * Execute a query with automatic error handling
 * @param {string} text - SQL query
 * @param {Array} params - Query parameters
 * @returns {Promise} Query result
 */
export const query = async (text, params) => {
  const start = Date.now();
  try {
    const result = await pool.query(text, params);
    const duration = Date.now() - start;

    if (duration > 1000) {
      console.warn(`Slow query detected (${duration}ms):`, text);
    }

    return result;
  } catch (error) {
    console.error("Database query error:", error);
    throw error;
  }
};

/**
 * Get a client from the pool for transactions
 * @returns {Promise} PostgreSQL client
 */
export const getClient = async () => {
  return await pool.connect();
};

/**
 * Execute multiple queries in a transaction
 * @param {Function} callback - Transaction callback
 * @returns {Promise} Transaction result
 */
export const transaction = async (callback) => {
  const client = await pool.connect();

  try {
    await client.query("BEGIN");
    const result = await callback(client);
    await client.query("COMMIT");
    return result;
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
};

/**
 * Check database connection health
 * @returns {Promise<boolean>}
 */
export const healthCheck = async () => {
  try {
    const result = await pool.query(
      "SELECT NOW() as time, version() as version"
    );
    console.log("Database health check:", result.rows[0]);
    return true;
  } catch (error) {
    console.error("Database health check failed:", error);
    return false;
  }
};

/**
 * Get pool statistics
 * @returns {Object} Pool stats
 */
export const getPoolStats = () => {
  return {
    total: pool.totalCount,
    idle: pool.idleCount,
    waiting: pool.waitingCount,
  };
};

/**
 * Close all connections in the pool
 * @returns {Promise<void>}
 */
export const closePool = async () => {
  await pool.end();
  console.log("PostgreSQL pool closed");
};

export default {
  query,
  getClient,
  transaction,
  healthCheck,
  getPoolStats,
  closePool,
  pool,
};
