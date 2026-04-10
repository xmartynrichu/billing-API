/**
 * Request Logger Middleware
 * Logs all incoming requests for debugging and monitoring
 */

const requestLogger = (req, res, next) => {
  const timestamp = new Date().toISOString();
  const { method, url, body } = req;

  console.log(`[${timestamp}] ${method} ${url}`);
  if (body && Object.keys(body).length > 0) {
    console.log('Body:', JSON.stringify(body, null, 2));
  }

  res.on('finish', () => {
    console.log(`[${timestamp}] Response Status: ${res.statusCode}`);
  });

  next();
};

module.exports = requestLogger;
