# Demon Teach Backend API

Backend API server for the Demon Teach language learning mobile application. Provides content management system (CMS) for admins and content delivery for mobile app users.

## Features

- ✅ **RESTful API** - Clean REST endpoints for content management
- ✅ **Content Management System** - Full CRUD operations for lesson content
- ✅ **Content Validation** - Server-side validation with detailed error messages
- ✅ **Version Control** - Track content changes with version history
- ✅ **Authentication** - JWT-based authentication with role-based access control
- ✅ **PostgreSQL Database** - Robust data storage with Sequelize ORM
- ✅ **Content Delivery** - Optimized endpoints for mobile app content sync

## Technology Stack

- **Runtime**: Node.js 18+
- **Framework**: Express.js 5.x
- **Database**: PostgreSQL 14+
- **ORM**: Sequelize 6.x
- **Authentication**: JWT (jsonwebtoken)
- **Password Hashing**: bcryptjs
- **Validation**: express-validator + custom ContentValidator

## Prerequisites

- Node.js 18+ installed
- PostgreSQL 14+ installed and running
- npm or yarn package manager

## Installation

### 1. Clone and Install Dependencies

```bash
cd demon_teach_backend
npm install
```

### 2. Database Setup

Create a PostgreSQL database:

```sql
CREATE DATABASE demon_teach;
```

### 3. Environment Configuration

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

Edit `.env` with your configuration:

```env
# Server
PORT=3000
NODE_ENV=development

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=demon_teach
DB_USER=postgres
DB_PASSWORD=your_password

# JWT
JWT_SECRET=your_secret_key_here
JWT_EXPIRES_IN=7d
JWT_REFRESH_EXPIRES_IN=30d

# CORS
CORS_ORIGIN=http://localhost:3000,http://localhost:8080
```

### 4. Start Server

**Development mode** (with auto-reload):
```bash
npm run dev
```

**Production mode**:
```bash
npm start
```

The server will start on `http://localhost:3000`

## API Documentation

### Base URL

```
http://localhost:3000/api
```

### Authentication

All protected endpoints require a JWT token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

---

## Endpoints

### Authentication (`/api/auth`)

#### Register User
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "role": "user"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Registration successful",
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "role": "user"
    },
    "accessToken": "jwt_token",
    "refreshToken": "refresh_token"
  }
}
```

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

#### Refresh Token
```http
POST /api/auth/refresh
Content-Type: application/json

{
  "refreshToken": "your_refresh_token"
}
```

#### Get Current User
```http
GET /api/auth/me
Authorization: Bearer <token>
```

---

### CMS - Content Management (`/api/cms`) 🔒 Admin Only

#### Get All Lessons
```http
GET /api/cms/lessons?page=1&limit=20&targetLanguage=en&difficulty=basic
Authorization: Bearer <admin_token>
```

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20)
- `targetLanguage` (optional): Filter by language (en, zh, ko)
- `difficulty` (optional): Filter by difficulty (basic, intermediate, advanced)
- `topic` (optional): Filter by topic (partial match)
- `isPublished` (optional): Filter by published status (true/false)

#### Create Lesson
```http
POST /api/cms/lessons
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "title": "Greetings and Introductions",
  "difficulty": "basic",
  "topic": "conversation",
  "targetLanguage": "en",
  "durationEstimate": 10,
  "content": {
    "flashcards": [
      {
        "id": "fc1",
        "lessonId": "lesson1",
        "frontText": "Hello",
        "backText": "Xin chào",
        "exampleUsage": "Hello, how are you?",
        "audioUrl": "https://cdn.example.com/audio/hello.mp3"
      }
    ],
    "quiz": {
      "id": "quiz1",
      "lessonId": "lesson1",
      "title": "Greetings Quiz",
      "questions": [
        {
          "id": "q1",
          "type": "multipleChoice",
          "questionText": "What is 'Hello' in Vietnamese?",
          "options": ["Xin chào", "Tạm biệt", "Cảm ơn", "Xin lỗi"],
          "correctAnswer": "Xin chào",
          "explanation": "Xin chào means Hello in Vietnamese"
        }
      ]
    }
  }
}
```

#### Update Lesson
```http
PUT /api/cms/lessons/:lessonId
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "title": "Updated Title",
  "changeDescription": "Updated lesson title and added new flashcards"
}
```

#### Delete Lesson
```http
DELETE /api/cms/lessons/:lessonId
Authorization: Bearer <admin_token>
```

#### Publish Lesson
```http
POST /api/cms/lessons/:lessonId/publish
Authorization: Bearer <admin_token>
```

#### Get Lesson Versions
```http
GET /api/cms/lessons/:lessonId/versions
Authorization: Bearer <admin_token>
```

#### Validate Content
```http
POST /api/cms/lessons/validate
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "content": {
    "flashcards": [...],
    "quiz": {...}
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "isValid": false,
    "errors": [
      "flashcards[0]: missing required field 'frontText'",
      "quiz.questions array cannot be empty"
    ]
  }
}
```

---

### Content Delivery (`/api/content`) 🔒 User Auth Required

#### Check for Updates
```http
GET /api/content/check-updates?language=en&lastSync=2024-01-15T10:00:00Z
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "hasUpdates": true,
    "updatedLessons": [
      {
        "id": "lesson1",
        "version": 2,
        "updatedAt": "2024-01-16T10:00:00Z"
      }
    ],
    "serverTime": "2024-01-16T12:00:00Z"
  }
}
```

#### Get Lessons
```http
GET /api/content/lessons?language=en&difficulty=basic&limit=50
Authorization: Bearer <token>
```

#### Get Single Lesson
```http
GET /api/content/lessons/:lessonId
Authorization: Bearer <token>
```

#### Get Lessons by Difficulty
```http
GET /api/content/lessons-by-difficulty?language=en&difficulty=intermediate&limit=20
Authorization: Bearer <token>
```

#### Get Random Lessons (for offline download)
```http
GET /api/content/random-lessons?language=en&difficulty=basic&count=3
Authorization: Bearer <token>
```

---

## Content Validation

The backend uses `ContentValidator` to validate lesson content structure. All content must pass validation before being saved or published.

### Validation Rules

**Required Fields:**
- `flashcards` (array, non-empty)
- `quiz` (object with questions array)

**Optional Fields:**
- `listeningExercise` (object)
- `speakingExercise` (object)

**Flashcard Validation:**
- `id`, `lessonId`, `frontText`, `backText`, `exampleUsage` (required)
- `audioUrl` (optional, must be valid URL if provided)

**Quiz Validation:**
- `id`, `lessonId`, `title`, `questions` (required)
- Questions must have: `id`, `type`, `questionText`, `correctAnswer`
- Valid question types: `multipleChoice`, `fillInBlank`, `matching`, `trueFalse`
- Multiple choice questions must have `options` array (min 2 options)

**Listening Exercise Validation:**
- `id`, `lessonId`, `audioUrl`, `durationSeconds`, `questions` (required)
- Duration must be 10-60 seconds
- Must have 3-5 comprehension questions

**Speaking Exercise Validation:**
- `id`, `lessonId`, `phrase`, `modelAudioUrl` (required)
- URLs must be valid HTTP/HTTPS URLs

### Validation Example

```javascript
const ContentValidator = require('./validators/contentValidator');

const validation = ContentValidator.validate(content);

if (!validation.isValid) {
  console.log('Validation errors:', validation.errors);
  // [
  //   "flashcards[0]: missing required field 'frontText'",
  //   "quiz.questions array cannot be empty"
  // ]
}
```

---

## Database Schema

### Users Table
```sql
- id (UUID, PK)
- email (STRING, UNIQUE)
- password (STRING, hashed)
- role (ENUM: 'user', 'admin')
- isActive (BOOLEAN)
- createdAt, updatedAt (TIMESTAMP)
```

### Lessons Table
```sql
- id (UUID, PK)
- title (STRING)
- difficulty (ENUM: 'basic', 'intermediate', 'advanced')
- topic (STRING)
- targetLanguage (ENUM: 'en', 'zh', 'ko')
- durationEstimate (INTEGER, minutes)
- version (INTEGER)
- content (JSONB)
- isPublished (BOOLEAN)
- publishedAt (TIMESTAMP)
- createdBy, updatedBy (UUID, FK to users)
- createdAt, updatedAt (TIMESTAMP)
```

### LessonVersions Table
```sql
- id (UUID, PK)
- lessonId (UUID, FK to lessons)
- version (INTEGER)
- title, difficulty, topic, targetLanguage, durationEstimate
- content (JSONB)
- changeDescription (TEXT)
- createdBy (UUID, FK to users)
- createdAt (TIMESTAMP)
```

---

## Error Handling

All errors follow a consistent format:

```json
{
  "success": false,
  "message": "Error description",
  "errors": ["Detailed error 1", "Detailed error 2"]
}
```

**HTTP Status Codes:**
- `200` - Success
- `201` - Created
- `400` - Bad Request (validation error)
- `401` - Unauthorized (authentication required)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `409` - Conflict (duplicate resource)
- `500` - Internal Server Error

---

## Development

### Project Structure

```
demon_teach_backend/
├── src/
│   ├── config/
│   │   └── database.js          # Database configuration
│   ├── controllers/
│   │   ├── authController.js    # Authentication logic
│   │   ├── cmsController.js     # CMS operations
│   │   └── contentController.js # Content delivery
│   ├── middleware/
│   │   ├── auth.js              # JWT authentication
│   │   └── errorHandler.js      # Error handling
│   ├── models/
│   │   ├── User.js              # User model
│   │   ├── Lesson.js            # Lesson model
│   │   ├── LessonVersion.js     # Version model
│   │   └── index.js             # Model associations
│   ├── routes/
│   │   ├── auth.js              # Auth routes
│   │   ├── cms.js               # CMS routes
│   │   └── content.js           # Content routes
│   ├── validators/
│   │   └── contentValidator.js  # Content validation
│   ├── app.js                   # Express app setup
│   └── server.js                # Server entry point
├── .env.example                 # Environment template
├── .gitignore
├── package.json
└── README.md
```

### Adding New Endpoints

1. Create controller function in `src/controllers/`
2. Add route in `src/routes/`
3. Apply middleware (auth, validation) as needed
4. Update this README with endpoint documentation

### Database Migrations

To reset database (⚠️ WARNING: Data loss):

```javascript
// In src/server.js, change:
await syncDatabase(true); // force: true drops all tables
```

---

## Testing

### Manual Testing with cURL

**Register Admin:**
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123","role":"admin"}'
```

**Login:**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}'
```

**Create Lesson:**
```bash
curl -X POST http://localhost:3000/api/cms/lessons \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d @lesson_example.json
```

### Testing with Postman

1. Import the API endpoints into Postman
2. Set up environment variables for `baseUrl` and `token`
3. Test authentication flow first
4. Test CMS operations with admin token
5. Test content delivery with user token

---

## Deployment

### Production Checklist

- [ ] Set `NODE_ENV=production`
- [ ] Use strong `JWT_SECRET` (32+ characters)
- [ ] Configure PostgreSQL with SSL
- [ ] Set up proper CORS origins
- [ ] Enable HTTPS
- [ ] Set up logging (Winston, Morgan)
- [ ] Configure rate limiting
- [ ] Set up monitoring (PM2, New Relic)
- [ ] Configure backup strategy
- [ ] Set up CI/CD pipeline

### Environment Variables (Production)

```env
NODE_ENV=production
PORT=3000
DB_HOST=your-db-host
DB_PORT=5432
DB_NAME=demon_teach_prod
DB_USER=prod_user
DB_PASSWORD=strong_password
JWT_SECRET=very_strong_secret_key_32_chars_min
JWT_EXPIRES_IN=7d
CORS_ORIGIN=https://yourdomain.com
```

---

## Integration with Flutter App

The Flutter app should:

1. **Authentication**: Store JWT tokens securely using `flutter_secure_storage`
2. **Content Sync**: Check for updates on app start and periodically
3. **Offline Mode**: Download lessons using `/api/content/random-lessons`
4. **Content Parsing**: Use `ContentParser` (from Task 4.1) to parse lesson content
5. **Error Handling**: Handle 401 (refresh token), 403 (permissions), 404 (not found)

### Example Flutter Integration

```dart
// API Service
class ApiService {
  final String baseUrl = 'http://localhost:3000/api';
  final Dio dio = Dio();

  Future<List<Lesson>> checkForUpdates(String language, DateTime lastSync) async {
    final response = await dio.get(
      '$baseUrl/content/check-updates',
      queryParameters: {
        'language': language,
        'lastSync': lastSync.toIso8601String(),
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    
    if (response.data['data']['hasUpdates']) {
      return fetchUpdatedLessons(language);
    }
    return [];
  }
}
```

---

## License

ISC

## Support

For issues or questions, please contact the development team.

---

**Version**: 1.0.0  
**Last Updated**: December 2024  
**Author**: Kiro AI Assistant
