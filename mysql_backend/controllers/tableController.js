const db = require("../config/database");

// Allowed tables for security
const ALLOWED_TABLES = [
  "products",
  "categories",
  "suppliers",
  "customers",
  "purchases",
  "purchase_items",
  "receivings",
  "receiving_items",
  "purchase_returns",
  "purchase_return_items",
  "transactions",
  "transaction_items",
  "pending_transactions",
  "pending_transaction_items",
  "stock_movements",
];

// Validate table name
const validateTable = (table) => {
  if (!ALLOWED_TABLES.includes(table)) {
    throw new Error(`Table '${table}' is not allowed`);
  }
};

// Convert ISO 8601 datetime to MySQL format
const convertToMySQLDateTime = (value) => {
  if (!value) return null;

  // If it's already in MySQL format (YYYY-MM-DD HH:MM:SS), return as is
  if (
    typeof value === "string" &&
    /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/.test(value)
  ) {
    return value;
  }

  // If it's ISO 8601 format (YYYY-MM-DDTHH:MM:SS.sssZ), convert it
  if (typeof value === "string" && value.includes("T")) {
    try {
      const date = new Date(value);
      if (isNaN(date.getTime())) return value; // Return original if invalid

      // Format to MySQL datetime: YYYY-MM-DD HH:MM:SS
      const year = date.getFullYear();
      const month = String(date.getMonth() + 1).padStart(2, "0");
      const day = String(date.getDate()).padStart(2, "0");
      const hours = String(date.getHours()).padStart(2, "0");
      const minutes = String(date.getMinutes()).padStart(2, "0");
      const seconds = String(date.getSeconds()).padStart(2, "0");

      return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
    } catch (e) {
      console.warn("Failed to convert datetime:", value, e);
      return value;
    }
  }

  return value;
};

// Convert datetime fields in data object
const convertDateTimeFields = (data) => {
  if (!data || typeof data !== "object") return data;

  const converted = { ...data };
  const dateTimeFields = [
    "created_at",
    "updated_at",
    "deleted_at",
    "sale_date",
    "purchase_date",
    "transaction_date",
    "saved_at",
    "date",
  ];

  for (const field of dateTimeFields) {
    if (field in converted) {
      converted[field] = convertToMySQLDateTime(converted[field]);
    }
  }

  return converted;
};

// Query data
exports.query = async (req, res, next) => {
  try {
    const { table } = req.params;
    validateTable(table);

    const { columns, where, whereArgs, orderBy, limit, offset } = req.query;

    // Build query
    let query = `SELECT ${columns || "*"} FROM ${table}`;
    const params = [];

    if (where) {
      query += ` WHERE ${where}`;
      if (whereArgs) {
        // Handle whereArgs properly - it might be a string or array
        const args =
          typeof whereArgs === "string"
            ? whereArgs.split(",").map((arg) => arg.trim())
            : Array.isArray(whereArgs)
            ? whereArgs
            : [whereArgs];
        params.push(...args);
      }
    }

    if (orderBy) {
      query += ` ORDER BY ${orderBy}`;
    }

    if (limit) {
      const limitValue = parseInt(limit);
      if (!isNaN(limitValue) && limitValue > 0) {
        query += ` LIMIT ${limitValue}`;
      }
    }

    if (offset) {
      const offsetValue = parseInt(offset);
      if (!isNaN(offsetValue) && offsetValue >= 0) {
        query += ` OFFSET ${offsetValue}`;
      }
    }

    console.log("🔍 Query:", query);
    console.log("📦 Params:", params);

    // Use query() instead of execute() when params might be empty
    const [rows] =
      params.length > 0
        ? await db.execute(query, params)
        : await db.query(query);

    res.json({
      success: true,
      data: rows,
      count: rows.length,
    });
  } catch (error) {
    next(error);
  }
};

// Insert single record
exports.insert = async (req, res, next) => {
  try {
    const { table } = req.params;
    validateTable(table);

    let data = req.body.data;

    if (!data || typeof data !== "object") {
      return res.status(400).json({
        error: {
          message: "Invalid data format",
          status: 400,
        },
      });
    }

    // Convert datetime fields
    data = convertDateTimeFields(data);

    const columns = Object.keys(data);
    const values = Object.values(data);
    const placeholders = columns.map(() => "?").join(",");

    const query = `INSERT INTO ${table} (${columns.join(
      ","
    )}) VALUES (${placeholders})`;

    const [result] = await db.execute(query, values);

    res.json({
      success: true,
      insertId: result.insertId,
      affectedRows: result.affectedRows,
    });
  } catch (error) {
    next(error);
  }
};

// Batch insert multiple records
exports.batchInsert = async (req, res, next) => {
  const connection = await db.getConnection();

  try {
    const { table } = req.params;
    validateTable(table);

    let dataList = req.body.data;

    if (!Array.isArray(dataList) || dataList.length === 0) {
      return res.status(400).json({
        error: {
          message: "Invalid data format, expected array",
          status: 400,
        },
      });
    }

    await connection.beginTransaction();

    let insertCount = 0;

    for (let data of dataList) {
      // Convert datetime fields
      data = convertDateTimeFields(data);

      const columns = Object.keys(data);
      const values = Object.values(data);
      const placeholders = columns.map(() => "?").join(",");

      // Build UPDATE clause for ON DUPLICATE KEY UPDATE
      // Exclude primary key (id) from update
      const updateClauses = columns
        .filter((col) => col !== "id")
        .map((col) => `${col} = VALUES(${col})`)
        .join(", ");

      // Use INSERT ... ON DUPLICATE KEY UPDATE to handle conflicts safely
      // This updates existing records instead of deleting and re-inserting
      const query = `INSERT INTO ${table} (${columns.join(
        ","
      )}) VALUES (${placeholders}) ON DUPLICATE KEY UPDATE ${updateClauses}`;

      await connection.execute(query, values);
      insertCount++;
    }

    await connection.commit();

    res.json({
      success: true,
      insertCount,
      message: `Successfully inserted ${insertCount} records`,
    });
  } catch (error) {
    await connection.rollback();
    next(error);
  } finally {
    connection.release();
  }
};

// Update records
exports.update = async (req, res, next) => {
  try {
    const { table } = req.params;
    validateTable(table);

    let { data, where, whereArgs } = req.body;

    if (!data || typeof data !== "object") {
      return res.status(400).json({
        error: {
          message: "Invalid data format",
          status: 400,
        },
      });
    }

    if (!where) {
      return res.status(400).json({
        error: {
          message: "WHERE clause is required for UPDATE",
          status: 400,
        },
      });
    }

    // Convert datetime fields
    data = convertDateTimeFields(data);

    const setClauses = Object.keys(data)
      .map((key) => `${key} = ?`)
      .join(",");
    const values = [...Object.values(data), ...(whereArgs || [])];

    const query = `UPDATE ${table} SET ${setClauses} WHERE ${where}`;

    console.log("🔄 Update Query:", query);
    console.log("📦 Update Values:", values);

    const [result] = await db.execute(query, values);

    res.json({
      success: true,
      affectedRows: result.affectedRows,
    });
  } catch (error) {
    next(error);
  }
};

// Delete records
exports.delete = async (req, res, next) => {
  try {
    const { table } = req.params;
    validateTable(table);

    const { where, whereArgs } = req.body;

    if (!where) {
      return res.status(400).json({
        error: {
          message: "WHERE clause is required for DELETE",
          status: 400,
        },
      });
    }

    const query = `DELETE FROM ${table} WHERE ${where}`;

    const [result] = await db.execute(query, whereArgs || []);

    res.json({
      success: true,
      affectedRows: result.affectedRows,
    });
  } catch (error) {
    next(error);
  }
};
