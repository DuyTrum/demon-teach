# Demon Teach Admin Portal

Web-based admin portal for managing lesson content in the Demon Teach language learning app.

## Features

- ✅ **Authentication**: Secure login with JWT tokens
- ✅ **Lesson Management**: Full CRUD operations for lessons
- ✅ **Content Validation**: Real-time validation before saving
- ✅ **Version Control**: Track all changes with version history
- ✅ **Publish Workflow**: Draft → Validate → Publish
- ✅ **Filtering & Search**: Filter by language, difficulty, topic, status
- ✅ **Pagination**: Handle large datasets efficiently
- ✅ **Responsive Design**: Works on desktop and tablet

## Technology Stack

- **React 18** with TypeScript
- **React Router v6** for navigation
- **Axios** for API calls
- **React Toastify** for notifications
- **CSS Modules** for styling

## Prerequisites

- Node.js 18+
- npm or yarn
- Backend API running (see `demon_teach_backend/`)

## Installation

1. Navigate to admin portal directory:
```bash
cd demon_teach_admin
```

2. Install dependencies:
```bash
npm install
```

3. Configure environment:
Create `.env` file:
```env
REACT_APP_API_URL=http://localhost:3000/api
```

4. Start development server:
```bash
npm start
```

The app will open at `http://localhost:3001`

## Usage

### Login
1. Open `http://localhost:3001`
2. Login with admin credentials:
   - **Email**: `admin@demonteach.com`
   - **Password**: `admin123`

### Create Lesson
1. Click "New Lesson" button
2. Fill in metadata:
   - Title
   - Target Language (English, Chinese, Korean)
   - Difficulty (Basic, Intermediate, Advanced)
   - Topic
   - Duration (5-30 minutes)
3. Add flashcards:
   - Front text (target language)
   - Back text (translation)
   - Example usage
   - Audio URL (optional)
4. Add quiz questions:
   - Question text
   - Question type (Multiple Choice, Fill in Blank, etc.)
   - Options (for multiple choice)
   - Correct answer
   - Explanation (optional)
5. Click "Validate Content" to check for errors
6. Click "Create Lesson" to save
7. Click "Publish" to make it available to mobile app

### Edit Lesson
1. Click "Edit" button on lesson in list
2. Modify fields as needed
3. Add change description (optional but recommended)
4. Click "Validate Content"
5. Click "Update Lesson"
6. Lesson will be unpublished automatically
7. Click "Publish" to publish changes

### View Lesson Details
1. Click "View" button on lesson
2. See all content (flashcards, quiz, listening, speaking)
3. Switch to "Version History" tab to see all versions
4. Click "Edit" to modify
5. Click "Delete" to remove lesson

### Filter Lessons
Use filters at the top of lesson list:
- **Language**: Filter by target language
- **Difficulty**: Filter by difficulty level
- **Topic**: Search by topic name
- **Status**: Filter by published/draft status

### Pagination
- Use "Previous" and "Next" buttons to navigate pages
- Shows 20 lessons per page
- Displays current page and total pages

## Project Structure

```
demon_teach_admin/
├── public/
├── src/
│   ├── components/
│   │   ├── Auth/
│   │   │   ├── Login.tsx
│   │   │   ├── Login.css
│   │   │   └── PrivateRoute.tsx
│   │   ├── Layout/
│   │   │   ├── Header.tsx
│   │   │   ├── Header.css
│   │   │   ├── Layout.tsx
│   │   │   └── Layout.css
│   │   └── Lessons/
│   │       ├── LessonList.tsx
│   │       ├── LessonList.css
│   │       ├── LessonForm.tsx
│   │       ├── LessonForm.css
│   │       ├── LessonDetail.tsx
│   │       └── LessonDetail.css
│   ├── services/
│   │   ├── api.ts
│   │   ├── authService.ts
│   │   └── lessonService.ts
│   ├── types/
│   │   └── index.ts
│   ├── App.tsx
│   ├── App.css
│   └── index.tsx
├── .env
├── package.json
└── README.md
```

## API Integration

The admin portal connects to these Backend API endpoints:

### Authentication
- `POST /api/auth/login` - Login
- `POST /api/auth/logout` - Logout
- `POST /api/auth/refresh` - Refresh token
- `GET /api/auth/me` - Get current user

### Lessons (CMS)
- `GET /api/cms/lessons` - Get all lessons (with filters)
- `POST /api/cms/lessons` - Create new lesson
- `GET /api/cms/lessons/:id` - Get single lesson
- `PUT /api/cms/lessons/:id` - Update lesson
- `DELETE /api/cms/lessons/:id` - Delete lesson
- `POST /api/cms/lessons/:id/publish` - Publish lesson
- `GET /api/cms/lessons/:id/versions` - Get version history
- `POST /api/cms/lessons/validate` - Validate content

## Content Validation

The portal validates lesson content before saving:

### Required Fields
- **Flashcards**: At least 1 flashcard with:
  - Front text (target language)
  - Back text (translation)
  - Example usage
- **Quiz**: At least 1 question with:
  - Question text
  - Correct answer
  - Options (for multiple choice)

### Optional Fields
- Listening exercise
- Speaking exercise
- Audio URLs

### Validation Errors
If validation fails, you'll see:
- Specific field names with errors
- Descriptive error messages
- Suggestions for fixing

Example errors:
```
flashcards[0]: missing required field 'frontText'
quiz.questions array cannot be empty
flashcards[1]: audioUrl is not a valid URL
```

## Development

### Run Development Server
```bash
npm start
```

### Build for Production
```bash
npm run build
```

### Run Tests
```bash
npm test
```

## Deployment

### Build Production Bundle
```bash
npm run build
```

This creates optimized files in `build/` directory.

### Deploy to Vercel
```bash
npm install -g vercel
vercel deploy
```

### Deploy to Netlify
1. Build the app: `npm run build`
2. Drag & drop `build/` folder to Netlify

### Deploy to AWS S3
```bash
aws s3 sync build/ s3://your-bucket-name --delete
```

### Environment Variables (Production)
```env
REACT_APP_API_URL=https://your-api-domain.com/api
```

## Troubleshooting

### Issue: "Network Error"
**Solution**: Ensure backend API is running on `http://localhost:3000`

### Issue: "401 Unauthorized"
**Solution**: Login again to refresh token

### Issue: "CORS Error"
**Solution**: Add `http://localhost:3001` to `CORS_ORIGIN` in backend `.env`

### Issue: "Validation Failed"
**Solution**: Check error messages and fix content according to validation rules

### Issue: "Cannot publish lesson"
**Solution**: Ensure content is valid before publishing

## Features in Detail

### Authentication
- JWT-based authentication
- Automatic token refresh
- Secure token storage in localStorage
- Protected routes (admin only)
- Auto-redirect to login if unauthorized

### Lesson List
- Paginated view (20 items per page)
- Multiple filters (language, difficulty, topic, status)
- Quick actions (View, Edit, Publish, Delete)
- Status badges (Published/Draft)
- Difficulty color coding
- Language badges

### Lesson Form
- Dynamic form with add/remove items
- Real-time validation
- Change description for version tracking
- Support for multiple flashcards
- Support for multiple quiz questions
- Optional listening and speaking exercises
- Audio URL validation

### Lesson Detail
- Tabbed interface (Content / Version History)
- Full content display
- Flashcard cards with all fields
- Quiz questions with correct answers highlighted
- Version history with timestamps
- Quick actions (Edit, Publish, Delete)

### Version Control
- Automatic version increment on update
- Change description tracking
- View all versions with metadata
- Timestamp for each version
- Created by user tracking

## Best Practices

### Creating Lessons
1. Start with clear, descriptive title
2. Choose appropriate difficulty level
3. Add at least 3-5 flashcards
4. Add at least 3-5 quiz questions
5. Include audio URLs when available
6. Write clear explanations for quiz answers
7. Validate before saving
8. Add change description when editing

### Content Quality
- Use native speaker audio when possible
- Provide clear, concise translations
- Include realistic example usage
- Write helpful explanations
- Test content before publishing
- Review version history regularly

### Workflow
1. Create lesson (Draft status)
2. Validate content
3. Review and test
4. Publish when ready
5. Monitor usage
6. Update based on feedback
7. Track changes with descriptions

## Support

For issues or questions:
- Backend API docs: `demon_teach_backend/README.md`
- Backend setup: `demon_teach_backend/SETUP_GUIDE.md`
- Task summary: `demon_teach_backend/TASK_4.2_CMS_BACKEND_SUMMARY.md`

---

**Version**: 1.0.0  
**Status**: ✅ Complete  
**Last Updated**: December 2024  
**Author**: Kiro AI Assistant
