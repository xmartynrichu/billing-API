# Billing System Backend API

A RESTful API backend for the billing and inventory management system, built with Express.js and PostgreSQL.

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- npm 9+
- PostgreSQL 12+

### Installation

```bash
# Install dependencies
npm install

# Create .env file (copy from .env.example)
cp .env.example .env

# Update .env with your database credentials
# Start development server
npm run dev

# Start production server
npm start
```

The API will be available at `http://localhost:3000`

## 📚 API Documentation

### Base URL
```
http://localhost:3000
```

### Response Format

All endpoints return JSON responses:

**Success Response:**
```json
{
  "success": true,
  "statusCode": 200,
  "message": "Operation successful",
  "data": {},
  "timestamp": "2024-03-23T10:30:00.000Z"
}
```

**Error Response:**
```json
{
  "success": false,
  "statusCode": 400,
  "message": "Error message",
  "details": {},
  "timestamp": "2024-03-23T10:30:00.000Z"
}
```

### Endpoints

#### Health Check
```
GET /health
```
Verify API is running.

#### Users
```
GET /users                    # Get all users
POST /users                   # Create new user
DELETE /users/:id             # Delete user by ID
```

#### Employees
```
GET /employee                 # Get all employees
POST /employee                # Create new employee
DELETE /employee/:id          # Delete employee by ID
```

#### Fish Master
```
GET /fish                     # Get all fish
POST /fish                    # Create new fish
DELETE /fish/:id              # Delete fish by ID
```

#### Revenue
```
GET /revenue                  # Get all revenue records
POST /revenue                 # Create revenue entry
DELETE /revenue/:id           # Delete revenue record
```

#### Expenses
```
GET /expenseentry             # Get all expenses
POST /expenseentry            # Create expense entry
DELETE /expenseentry/:id      # Delete expense record
```

#### Master Data
```
GET /labelmaster              # Get all expense labels
POST /labelmaster             # Create expense label
DELETE /labelmaster/:id       # Delete label
```

#### Dashboard
```
GET /dashboard                # Get dashboard statistics
GET /dashboard/profit         # Get profit report
```

## 🏗️ Project Structure

```
backend/
├── app.js                 # Main application file
├── package.json           # Dependencies
├── .env.example          # Environment variables template
├── DB/
│   └── db.js             # Database connection
├── middleware/            # Express middleware
│   ├── errorHandler.js   # Global error handling
│   ├── requestLogger.js  # Request logging
│   └── validateInput.js  # Input validation
├── utils/                # Utility functions
│   ├── constants.js      # Constants and config
│   ├── apiResponse.js    # Response formatters
│   └── asyncHandler.js   # Async error wrapper
├── routes/               # API route definitions
├── controllers/          # Business logic
└── models/              # Database models
```

## 🔧 Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_HOST` | localhost | Database host |
| `DB_PORT` | 5432 | Database port |
| `DB_USER` | postgres | Database user |
| `DB_PASSWORD` | - | Database password |
| `DB_NAME` | billing_db | Database name |
| `PORT` | 3000 | Server port |
| `NODE_ENV` | development | Environment mode |
| `CLIENT_URL` | http://localhost:4201 | Frontend URL for CORS |

## 📝 Middleware

### Error Handler
Global middleware for catching and formatting errors.

### Request Logger
Logs all incoming requests for debugging and monitoring.

### Input Validation
Validates request body format and content.

## 🗄️ Database

### Connection Pool
- Maximum connections: 20
- Idle timeout: 30 seconds
- Connection timeout: 2 seconds

### Connection Test
The application tests database connectivity on startup.

## 🐛 Debugging

### Enable Debug Logging
```bash
DEBUG=* npm run dev
```

### View Request Logs
All requests are logged to the console with timestamp and status.

## 🔒 Security Features

1. **CORS Configuration** - Restricted to frontend URL
2. **Request Validation** - Input validation middleware
3. **Error Handling** - No sensitive data in error messages
4. **Environment Variables** - Sensitive data protected via .env
5. **SQL Injection Prevention** - Using parameterized queries

## 📦 Dependencies

- `express` - Web framework
- `postgresql` (pg) - Database driver
- `cors` - Cross-origin resource sharing
- `dotenv` - Environment variables
- `exceljs` - Excel file generation
- `nodemon` - Development server (dev)

## 🚀 Deployment

### Production Build
```bash
npm install --production
npm start
```

### Environment for Production
Update `.env` file with production database credentials and set:
```
NODE_ENV=production
CLIENT_URL=https://yourdomain.com
```

## 🆘 Troubleshooting

### Database Connection Failed
- Check database is running
- Verify credentials in .env
- Check database name exists
- Ensure PostgreSQL is accessible

### Port Already in Use
change PORT in .env file or use:
```bash
PORT=3001 npm start
```

### CORS Issues
- Verify CLIENT_URL in .env matches frontend URL
- Check CORS configuration in app.js

## 📞 Support

For issues:
1. Check error logs in console
2. Verify .env configuration
3. Test database connection
4. Review API documentation

## 🤝 Contributing

1. Follow code structure
2. Add proper error handling
3. Test endpoints thoroughly
4. Update documentation

## 📄 License

ISC License
