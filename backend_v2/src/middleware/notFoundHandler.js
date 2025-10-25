/**
 * 404 Not Found handler middleware
 */
export const notFoundHandler = (req, res, next) => {
  res.status(404).json({
    error: {
      message: `Cannot ${req.method} ${req.path}`,
      status: 404,
      availableEndpoints: {
        health: `/api/${process.env.API_VERSION || "v2"}/health`,
        products: `/api/${process.env.API_VERSION || "v2"}/products`,
        sales: `/api/${process.env.API_VERSION || "v2"}/sales`,
        purchases: `/api/${process.env.API_VERSION || "v2"}/purchases`,
        customers: `/api/${process.env.API_VERSION || "v2"}/customers`,
        suppliers: `/api/${process.env.API_VERSION || "v2"}/suppliers`,
        branches: `/api/${process.env.API_VERSION || "v2"}/branches`,
      },
    },
  });
};
