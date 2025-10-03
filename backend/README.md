# ASHA Bandhu Backend Server

A Node.js + Express + PostgreSQL backend server for the ASHA Bandhu mobile application.

## Features

- **RESTful API** for ASHA workers and PHC staff
- **PostgreSQL Database** with proper schema design
- **JWT Authentication** for secure access
- **Data Synchronization** between mobile and server
- **Role-based Access Control** (ASHA vs PHC)
- **Rate Limiting** and security middleware
- **Comprehensive Logging** and error handling

## Quick Start

### Prerequisites

- Node.js (v16 or higher)
- PostgreSQL (v12 or higher)
- npm or yarn

### Installation

1. **Clone and navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Set up environment variables:**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` file with your database credentials:
   ```env
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=asha_bandhu
   DB_USER=your_username
   DB_PASSWORD=your_password
   JWT_SECRET=your_super_secret_key
   ```

4. **Create PostgreSQL database:**
   ```sql
   CREATE DATABASE asha_bandhu;
   ```

5. **Run database migrations:**
   ```bash
   npm run migrate
   ```

6. **Start the server:**
   ```bash
   # Development mode
   npm run dev
   
   # Production mode
   npm start
   ```

The server will start on `http://localhost:3000`

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new worker
- `POST /api/auth/login` - Worker login
- `POST /api/auth/verify-pin` - Verify worker PIN

### Workers
- `GET /api/workers/profile` - Get worker profile
- `PUT /api/workers/profile` - Update worker profile
- `GET /api/workers` - Get all workers (PHC only)

### Patients
- `GET /api/patients` - Get patients (with filtering)
- `GET /api/patients/:id` - Get single patient
- `POST /api/patients` - Create new patient
- `PUT /api/patients/:id` - Update patient
- `DELETE /api/patients/:id` - Delete patient

### Sync
- `POST /api/sync/patients` - Sync patients from mobile
- `GET /api/sync/patients` - Get updates for mobile
- `GET /api/sync/status` - Get sync status

### Health Check
- `GET /health` - Server health status

## Database Schema

### Tables
- **workers** - ASHA workers and PHC staff
- **worker_auth** - Authentication credentials
- **patients** - Patient records
- **patient_visits** - Visit history
- **sync_logs** - Synchronization tracking

## Security Features

- JWT token-based authentication
- Password hashing with bcrypt
- Rate limiting (100 requests per 15 minutes)
- CORS protection
- Input validation and sanitization
- SQL injection prevention

## Development

### Scripts
- `npm run dev` - Start with nodemon (auto-restart)
- `npm run migrate` - Run database migrations
- `npm run seed` - Seed database with sample data
- `npm start` - Start production server

### Project Structure
```
backend/
├── config/
│   └── database.js          # Database configuration
├── middleware/
│   └── auth.js              # Authentication middleware
├── routes/
│   ├── auth.js              # Authentication routes
│   ├── workers.js           # Worker management
│   ├── patients.js          # Patient management
│   └── sync.js              # Data synchronization
├── scripts/
│   ├── migrate.js           # Database migrations
│   └── seed.js              # Sample data seeding
├── server.js                # Main server file
├── package.json
└── README.md
```

## Deployment

### Environment Variables (Production)
```env
NODE_ENV=production
PORT=3000
DB_HOST=your_production_db_host
DB_NAME=asha_bandhu_prod
JWT_SECRET=your_production_secret
CORS_ORIGIN=https://your-frontend-domain.com
```

### Docker Deployment (Optional)
```dockerfile
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

## API Usage Examples

### Register Worker
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "workerId": "ASHA001",
    "password": "password123",
    "name": "Priya Sharma",
    "village": "Rampur",
    "role": "asha",
    "pin": "1234"
  }'
```

### Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "workerId": "ASHA001",
    "password": "password123"
  }'
```

### Create Patient (with auth token)
```bash
curl -X POST http://localhost:3000/api/patients \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "name": "Rajesh Kumar",
    "age": 45,
    "gender": "male",
    "phone": "9876543210",
    "village": "Rampur",
    "assignedWorker": "ASHA001"
  }'
```

## Support

For technical support or questions, please contact the development team or create an issue in the repository.
