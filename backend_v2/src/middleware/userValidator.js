import { body, validationResult, query } from "express-validator";

// Validation middleware
export const validateRequest = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: "Validation error",
      errors: errors.array(),
    });
  }
  next();
};

// Create user validation
export const validateCreateUser = [
  body("username")
    .trim()
    .isLength({ min: 3, max: 50 })
    .withMessage("Username must be between 3 and 50 characters"),
  body("email").trim().isEmail().withMessage("Invalid email address"),
  body("password")
    .isLength({ min: 6 })
    .withMessage("Password must be at least 6 characters")
    .matches(/[A-Z]/)
    .withMessage("Password must contain at least one uppercase letter")
    .matches(/[0-9]/)
    .withMessage("Password must contain at least one number"),
  body("full_name")
    .trim()
    .isLength({ min: 2 })
    .withMessage("Full name must be at least 2 characters"),
  body("role")
    .optional()
    .isIn(["super_admin", "admin", "manager", "cashier", "staff"])
    .withMessage("Invalid role"),
  body("phone")
    .optional()
    .trim()
    .matches(/^[\d\+\-\(\)\s]+$/)
    .withMessage("Invalid phone number"),
  body("branch_ids")
    .optional()
    .isArray()
    .withMessage("branch_ids must be an array"),
  validateRequest,
];

// Update user validation
export const validateUpdateUser = [
  body("email")
    .optional()
    .trim()
    .isEmail()
    .withMessage("Invalid email address"),
  body("full_name")
    .optional()
    .trim()
    .isLength({ min: 2 })
    .withMessage("Full name must be at least 2 characters"),
  body("role")
    .optional()
    .isIn(["super_admin", "admin", "manager", "cashier", "staff"])
    .withMessage("Invalid role"),
  body("status")
    .optional()
    .isIn(["active", "inactive", "suspended"])
    .withMessage("Invalid status"),
  body("phone")
    .optional()
    .trim()
    .matches(/^[\d\+\-\(\)\s]+$/)
    .withMessage("Invalid phone number"),
  body("branch_ids")
    .optional()
    .isArray()
    .withMessage("branch_ids must be an array"),
  validateRequest,
];

// Change password validation
export const validateChangePassword = [
  body("currentPassword")
    .notEmpty()
    .withMessage("Current password is required"),
  body("newPassword")
    .isLength({ min: 6 })
    .withMessage("New password must be at least 6 characters")
    .matches(/[A-Z]/)
    .withMessage("Password must contain at least one uppercase letter")
    .matches(/[0-9]/)
    .withMessage("Password must contain at least one number"),
  validateRequest,
];

// Reset password validation
export const validateResetPassword = [
  body("newPassword")
    .isLength({ min: 6 })
    .withMessage("New password must be at least 6 characters")
    .matches(/[A-Z]/)
    .withMessage("Password must contain at least one uppercase letter")
    .matches(/[0-9]/)
    .withMessage("Password must contain at least one number"),
  validateRequest,
];

// Assign branches validation
export const validateAssignBranches = [
  body("branch_ids")
    .isArray({ min: 1 })
    .withMessage("branch_ids must be a non-empty array"),
  body("default_branch_id")
    .optional()
    .isInt()
    .withMessage("default_branch_id must be an integer"),
  validateRequest,
];

// Query validation for list users
export const validateListUsers = [
  query("limit")
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage("Limit must be between 1 and 100"),
  query("offset")
    .optional()
    .isInt({ min: 0 })
    .withMessage("Offset must be a non-negative integer"),
  query("role")
    .optional()
    .isIn(["super_admin", "admin", "manager", "cashier", "staff"])
    .withMessage("Invalid role"),
  query("status")
    .optional()
    .isIn(["active", "inactive", "suspended"])
    .withMessage("Invalid status"),
  query("search")
    .optional()
    .trim()
    .isLength({ min: 1 })
    .withMessage("Search term cannot be empty"),
  validateRequest,
];
