# Backend Setup Guide

Complete guide to set up the Demon Teach Backend API from scratch.

## Prerequisites

Before starting, ensure you have:
- ✅ Node.js 18+ installed
- ✅ PostgreSQL 14+ installed
- ✅ npm or yarn package manager
- ✅ Git (optional)

---

## Step 1: Install PostgreSQL

### Windows

1. Download PostgreSQL installer from: https://www.postgresql.org/download/windows/
2. Run the installer and follow the setup wizard
3. Remember the password you set for the `postgres` user
4. Default port is `5432` (keep it unless you have conflicts)

### macOS

Using Homebrew:
```bash
brew install postgresql@14
brew services start postgresql@14
```

### Linux (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

---

## Step 2: Create Database

### Option A: Using psql Command Line

1. Open terminal/command prompt
2. Connect to PostgreSQL:

**Windows:**
```bash
psql -U postgres
```

**macOS/Linux:**
```bash
sudo -u postgres psql
```

3. Create database:
```sql
CREATE DATABASE demon_teach;
```

4. Verify database was created:
```sql
\l
```

5. Exit psql:
```sql
\q
```

### Option B: Using pgAdmin (GUI)

1. Open pgAdmin (installed with PostgreSQL)
2. Connect to your PostgreSQL server
3. Right-click on "Databases" → "Create" → "Database"
4. Enter database name: `demon_teach`
5. Click "Save"

---

## Step 3: Install Backend Dependencies

1. Navigate to backend directory:
```bash
cd demon_teach_backend
```

2. Install npm packages:
```bash
npm install
```

This will install:
- express (web framework)
- sequelize (ORM)
- pg (PostgreSQL driver)
- jsonwebtoken (JWT authentication)
- bcryptjs (password hashing)
- cors (CORS middleware)
- dotenv (environment variables)
- express-validator (validation)
- nodemon (dev auto-reload)

---

## Step 4: Configure Environment

1. Copy `.env.example` to `.env`:

**Windows:**
```bash
copy .env.example .env
```

**macOS/Linux:**
```bash
cp .env.example .env
```

2. Edit `.env` file with your configuration:

```env
# Server Configuration
PORT=3000
NODE_ENV=development

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=demon_teach
DB_USER=postgres
DB_PASSWORD=your_postgres_password_here  # ⚠️ CHANGE THIS

# JWT Configuration
JWT_SECRET=your_secret_key_here_change_in_production  # ⚠️ CHANGE THIS
JWT_EXPIRES_IN=7d
JWT_REFRESH_EXPIRES_IN=30d

# CORS Configuration
CORS_ORIGIN=http://localhost:3000,http://localhost:8080
```

**Important:**
- Replace `your_postgres_password_here` with your actual PostgreSQL password
- Replace `JWT_SECRET` with a strong random string (32+ characters)

---

## Step 5: Seed Database

Run the seed script to create tables and sample data:

```bash
npm run seed
```

This will:
- ✅ Create database tables (users, lessons, lesson_versions)
- ✅ Create admin user: `admin@demonteach.com` / `admin123`
- ✅ Create regular user: `user@demonteach.com` / `user123`
- ✅ Create 3 sample lessons

**Expected Output:**
```
🌱 Starting database seeding...
✅ Database connection established successfully.
✅ Database synchronized successfully.
👤 Creating admin user...
✅ Admin user created: admin@demonteach.com / admin123
👤 Creating regular user...
✅ Regular user created: user@demonteach.com / user123
📚 Creating sample lessons...
✅ Created lesson: Greetings and Introductions
✅ Created lesson: Numbers 1-10
✅ Created lesson: Family Members

✨ Database seeding completed successfully!

📋 Summary:
   - Admin: admin@demonteach.com / admin123
   - User: user@demonteach.com / user123
   - Lessons: 3 sample lessons created

🚀 You can now start the server with: npm run dev
```

---

## Step 6: Start Server

### Development Mode (with auto-reload)

```bash
npm run dev
```

### Production Mode

```bash
npm start
```

**Expected Output:**
```
🚀 Starting Demon Teach Backend API...
📍 Environment: development
✅ Database connection established successfully.
✅ Database synchronized successfully.
✅ Server is running on port 3000
🌐 API URL: http://localhost:3000
📚 Health check: http://localhost:3000/health

📋 Available endpoints:
   - POST   /api/auth/login
   - POST   /api/auth/register
   - POST   /api/auth/refresh
   - GET    /api/auth/me
   - GET    /api/cms/lessons
   - POST   /api/cms/lessons
   - PUT    /api/cms/lessons/:id
   - DELETE /api/cms/lessons/:id
   - POST   /api/cms/lessons/:id/publish
   - GET    /api/content/check-updates
   - GET    /api/content/lessons
   - GET    /api/content/lessons/:id

✨ Ready to accept requests!
```

---

## Step 7: Test API

### Test Health Check

Open browser or use curl:
```bash
curl http://localhost:3000/health
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Demon Teach Backend API is running",
  "timestamp": "2024-01-15T10:00:00.000Z",
  "environment": "development"
}
```

### Test Login

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"admin@demonteach.com\",\"password\":\"admin123\"}"
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": "uuid-here",
      "email": "admin@demonteach.com",
      "role": "admin"
    },
    "accessToken": "jwt_token_here",
    "refreshToken": "refresh_token_here"
  }
}
```

### Test Get Lessons (CMS)

Replace `YOUR_TOKEN` with the accessToken from login response:

```bash
curl -X GET http://localhost:3000/api/cms/lessons \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "lessons": [
      {
        "id": "uuid",
        "title": "Greetings and Introductions",
        "difficulty": "basic",
        "topic": "conversation",
        "targetLanguage": "en",
        "durationEstimate": 10,
        "version": 1,
        "isPublished": true,
        "publishedAt": "2024-01-15T10:00:00.000Z",
        "createdAt": "2024-01-15T10:00:00.000Z",
        "updatedAt": "2024-01-15T10:00:00.000Z"
      }
    ],
    "pagination": {
      "total": 3,
      "page": 1,
      "limit": 20,
      "totalPages": 1
    }
  }
}
```

---

## Troubleshooting

### Issue: "Unable to connect to the database"

**Solution:**
1. Check PostgreSQL is running:
   - Windows: Check Services → PostgreSQL
   - macOS: `brew services list`
   - Linux: `sudo systemctl status postgresql`

2. Verify database credentials in `.env`:
   - DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD

3. Test PostgreSQL connection:
   ```bash
   psql -U postgres -d demon_teach
   ```

### Issue: "Port 3000 is already in use"

**Solution:**
1. Change PORT in `.env` to another port (e.g., 3001)
2. Or kill the process using port 3000:
   - Windows: `netstat -ano | findstr :3000` then `taskkill /PID <PID> /F`
   - macOS/Linux: `lsof -ti:3000 | xargs kill`

### Issue: "JWT_SECRET is not defined"

**Solution:**
1. Make sure `.env` file exists in `demon_teach_backend/` directory
2. Verify `JWT_SECRET` is set in `.env`
3. Restart the server after changing `.env`

### Issue: "Sequelize validation error"

**Solution:**
1. Check your request body matches the required schema
2. Review validation errors in the response
3. Refer to API documentation in README.md

### Issue: "Cannot find module"

**Solution:**
1. Delete `node_modules` folder
2. Delete `package-lock.json`
3. Run `npm install` again

---

## Next Steps

1. ✅ **Test all endpoints** using Postman or curl
2. ✅ **Create more lessons** via CMS API
3. ✅ **Integrate with Flutter app** (see README.md)
4. ✅ **Set up production environment** (see Deployment section in README.md)

---

## Useful Commands

```bash
# Start development server
npm run dev

# Start production server
npm start

# Seed database
npm run seed

# Check PostgreSQL status
# Windows: Services → PostgreSQL
# macOS: brew services list
# Linux: sudo systemctl status postgresql

# Connect to database
psql -U postgres -d demon_teach

# View database tables
psql -U postgres -d demon_teach -c "\dt"

# View users
psql -U postgres -d demon_teach -c "SELECT * FROM users;"

# View lessons
psql -U postgres -d demon_teach -c "SELECT id, title, difficulty, \"targetLanguage\", \"isPublished\" FROM lessons;"
```

---

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review README.md for API documentation
3. Check server logs for error messages
4. Contact the development team

---

**Version**: 1.0.0  
**Last Updated**: December 2024
