/**
 * API Response Formatter
 * Standardizes all API responses
 */

const success = (data, message = 'Success', statusCode = 200) => {
  return {
    success: true,
    statusCode,
    message,
    data,
    timestamp: new Date().toISOString()
  };
};

const error = (message = 'Error', statusCode = 500, errorDetails = null) => {
  return {
    success: false,
    statusCode,
    message,
    ...(errorDetails && { details: errorDetails }),
    timestamp: new Date().toISOString()
  };
};

module.exports = {
  success,
  error
};
