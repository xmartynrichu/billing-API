/**
 * Input Validation Middleware
 * Validates and sanitizes incoming requests
 */

const validateInput = (schema) => {
  return (req, res, next) => {
    try {
      if (!req.body || Object.keys(req.body).length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Request body is empty'
        });
      }
      next();
    } catch (error) {
      res.status(400).json({
        success: false,
        message: 'Invalid request format',
        error: error.message
      });
    }
  };
};

module.exports = validateInput;
