const db = require("../config/database");

// Execute custom query
exports.execute = async (req, res, next) => {
  try {
    const { query, params } = req.body;

    if (!query) {
      return res.status(400).json({
        error: {
          message: "Query is required",
          status: 400,
        },
      });
    }

    // Security: Only allow SELECT, INSERT, UPDATE, DELETE
    const queryType = query.trim().toUpperCase().split(" ")[0];
    const allowedTypes = ["SELECT", "INSERT", "UPDATE", "DELETE"];

    if (!allowedTypes.includes(queryType)) {
      return res.status(403).json({
        error: {
          message: "Query type not allowed",
          status: 403,
        },
      });
    }

    const [rows] = await db.execute(query, params || []);

    res.json({
      success: true,
      data: rows,
      count: Array.isArray(rows) ? rows.length : undefined,
    });
  } catch (error) {
    next(error);
  }
};
