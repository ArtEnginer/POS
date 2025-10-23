// Simple authentication middleware
// For production, use proper JWT or OAuth

const authMiddleware = (req, res, next) => {
  // Skip auth for health check
  if (req.path === "/health") {
    return next();
  }

  const authHeader = req.headers["x-auth-username"];
  const authPassword = req.headers["x-auth-password"];
  const authDatabase = req.headers["x-auth-database"];

  // Check from body (for POST requests)
  const bodyAuth = req.body?.auth;

  const username = authHeader || bodyAuth?.username;
  const password = authPassword || bodyAuth?.password;
  const database = authDatabase || bodyAuth?.database;

  if (!username || !database) {
    return res.status(401).json({
      error: {
        message:
          "Authentication required - username and database must be provided",
        status: 401,
      },
    });
  }

  // Verify credentials (in production, use proper authentication)
  // Allow empty password for development
  const dbPassword = process.env.DB_PASSWORD || "";
  const providedPassword = password || "";

  if (
    username !== process.env.DB_USER ||
    providedPassword !== dbPassword ||
    database !== process.env.DB_NAME
  ) {
    console.log("Auth failed:", {
      providedUsername: username,
      expectedUsername: process.env.DB_USER,
      providedDatabase: database,
      expectedDatabase: process.env.DB_NAME,
      passwordMatch: providedPassword === dbPassword,
    });
    return res.status(401).json({
      error: {
        message: "Invalid credentials - check username, password, and database",
        status: 401,
      },
    });
  }

  next();
};

module.exports = authMiddleware;
