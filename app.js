/**
 * Main Application Entry Point
 * Express server configuration and setup
 */

require('dotenv').config();

const express = require('express');
const cors = require('cors');

// Middleware
const errorHandler = require('./middleware/errorHandler');
const requestLogger = require('./middleware/requestLogger');

// Routes
const userRouter = require('./routes/userRoutes');
const masterRouter = require('./routes/masterRoutes');
const expenseRouter = require('./routes/expenseRoutes');
const revenueRouter = require('./routes/revenueRoutes');
const fishRouter = require('./routes/fishRoutes');
const employeeRouter = require('./routes/employeeRoutes');
const dashboardRouter = require('./routes/dashboardRoutes');
const profitRouter = require('./routes/profitRoutes');

// Constants
const { API_ROUTES } = require('./utils/constants');

const app = express();

/**
 * Body Parser Middleware
 */
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

/**
 * CORS Configuration
 * Allow requests from frontend - Must be before routes
 */
const allowedOrigins = [
  'http://localhost:4200',
  'http://localhost:4201',
  'http://127.0.0.1:4200',
  'http://127.0.0.1:4201',
  'https://billing-ui-21kx.onrender.com',
  process.env.CLIENT_URL
].filter(Boolean);

app.use(cors({
  origin: function (origin, callback) {
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);
    
    if (allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  credentials: true,
  optionsSuccessStatus: 200,
  maxAge: 86400 // 24 hours
}));

/**
 * Request Logging Middleware
 */
app.use(requestLogger);

/**
 * Health Check Endpoint
 */
app.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'API is running 🚀',
    timestamp: new Date().toISOString()
  });
});

/**
 * API Routes Registration
 */
app.use(API_ROUTES.USERS, userRouter);
app.use(API_ROUTES.MASTER, masterRouter);
app.use(API_ROUTES.EXPENSES, expenseRouter);
app.use(API_ROUTES.REVENUE, revenueRouter);
app.use(API_ROUTES.FISH, fishRouter);
app.use(API_ROUTES.EMPLOYEES, employeeRouter);
app.use(API_ROUTES.DASHBOARD, dashboardRouter);
app.use(API_ROUTES.PROFIT, profitRouter);

/**
 * 404 Not Found Handler
 */
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Endpoint not found',
    path: req.originalUrl
  });
});

/**
 * Error Handling Middleware
 */
app.use(errorHandler);

/**
 * Start Server
 */
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`
  🚀 Server running successfully
  📍 Port: ${PORT}
  🌍 Environment: ${process.env.NODE_ENV || 'development'}
  📅 Started at: ${new Date().toISOString()}
  `);
});

module.exports = app;

