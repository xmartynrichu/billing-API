/**
 * Error Handler Middleware
 * Centralizes error handling across the application
 */

const errorHandler = (err, req, res, next) => {
  const status = err.status || 500;
  const message = err.message || 'Internal Server Error';
  const timestamp = new Date().toISOString();

  console.error(`[${timestamp}] Error (${status}):`, message);
  console.error('Stack:', err.stack);

  res.status(status).json({
    success: false,
    status,
    message,
    timestamp,
    ...(process.env.NODE_ENV === 'development' && { error: err })
  });
};

module.exports = errorHandler;
