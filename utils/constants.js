/**
 * Database Connection Constants
 */

const DB_CONFIG = {
  MAX_RETRIES: 3,
  RETRY_DELAY: 1000,
  QUERY_TIMEOUT: 30000,
  POOL_SIZE: 20
};

/**
 * API Constants
 */
const API_ROUTES = {
  USERS: '/users',
  EMPLOYEES: '/employee',
  EXPENSES: '/expenseentry',
  REVENUE: '/revenue',
  FISH: '/fish',
  MASTER: '/labelmaster',
  DASHBOARD: '/dashboard',
  PROFIT: '/profit'
};

/**
 * Error Messages
 */
const ERROR_MESSAGES = {
  NOT_FOUND: 'Resource not found',
  INVALID_REQUEST: 'Invalid request data',
  UNAUTHORIZED: 'Unauthorized access',
  SERVER_ERROR: 'Internal server error',
  DB_ERROR: 'Database operation failed',
  VALIDATION_ERROR: 'Validation failed'
};

/**
 * Success Messages
 */
const SUCCESS_MESSAGES = {
  CREATED: 'Resource created successfully',
  UPDATED: 'Resource updated successfully',
  DELETED: 'Resource deleted successfully',
  FETCHED: 'Data fetched successfully',
  OPERATION_SUCCESS: 'Operation completed successfully'
};

module.exports = {
  DB_CONFIG,
  API_ROUTES,
  ERROR_MESSAGES,
  SUCCESS_MESSAGES
};
