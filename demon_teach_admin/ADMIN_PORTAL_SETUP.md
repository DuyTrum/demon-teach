# Demon Teach Admin Portal - Setup Guide

## Overview

Basic React-based admin portal for managing lesson content in the Demon Teach language learning app. This portal connects to the Backend API (Task 4.2) to provide a user-friendly interface for content management.

## Features

- ✅ User authentication (login/logout)
- ✅ Lesson list with pagination and filters
- ✅ Create new lessons
- ✅ Edit existing lessons
- ✅ Delete lessons
- ✅ Publish/unpublish lessons
- ✅ View lesson versions
- ✅ Content validation
- ✅ Responsive design

## Technology Stack

- **Framework**: React 18 with TypeScript
- **Routing**: React Router v6
- **HTTP Client**: Axios
- **Notifications**: React Toastify
- **Styling**: CSS Modules (can be upgraded to Material-UI/Ant Design)

## Prerequisites

- Node.js 18+
- npm or yarn
- Backend API running (Task 4.2)

## Installation

1. Navigate to admin portal directory:
```bash
cd demon_teach_admin
```

2. Install dependencies:
```bash
npm install
```

3. Configure API endpoint:
Create `.env` file:
```env
REACT_APP_API_URL=http://localhost:3000/api
```

4. Start development server:
```bash
npm start
```

The app will open at `http://localhost:3001`

## Project Structure

```
demon_teach_admin/
├── public/
├── src/
│   ├── components/
│   │   ├── Auth/
│   │   │   ├── Login.tsx
│   │   │   └── PrivateRoute.tsx
│   │   ├── Lessons/
│   │   │   ├── LessonList.tsx
│   │   │   ├── LessonForm.tsx
│   │   │   ├── LessonDetail.tsx
│   │   │   └── LessonVersions.tsx
│   │   └── Layout/
│   │       ├── Header.tsx
│   │       ├── Sidebar.tsx
│   │       └── Layout.tsx
│   ├── services/
│   │   ├── api.ts
│   │   ├── authService.ts
│   │   └── lessonService.ts
│   ├── types/
│   │   └── index.ts
│   ├── utils/
│   │   └── validators.ts
│   ├── App.tsx
│   └── index.tsx
├── .env
├── package.json
└── README.md
```

## Key Components

### 1. Authentication
- Login form with email/password
- JWT token storage in localStorage
- Automatic token refresh
- Protected routes

### 2. Lesson Management
- List view with pagination (20 items per page)
- Filters: language, difficulty, topic, published status
- Create/Edit form with content validation
- Delete with confirmation
- Publish/unpublish actions

### 3. Content Editor
- JSON editor for lesson content
- Real-time validation
- Preview mode
- Error highlighting

### 4. Version History
- View all versions of a lesson
- Compare versions
- Restore previous version

## API Integration

The admin portal connects to the Backend API endpoints:

```typescript
// Authentication
POST /api/auth/login
POST /api/auth/logout
GET /api/auth/me

// Lessons
GET /api/cms/lessons
POST /api/cms/lessons
GET /api/cms/lessons/:id
PUT /api/cms/lessons/:id
DELETE /api/cms/lessons/:id
POST /api/cms/lessons/:id/publish
GET /api/cms/lessons/:id/versions
POST /api/cms/lessons/validate
```

## Usage

### Login
1. Open `http://localhost:3001`
2. Login with admin credentials:
   - Email: `admin@demonteach.com`
   - Password: `admin123`

### Create Lesson
1. Click "New Lesson" button
2. Fill in metadata (title, difficulty, topic, language, duration)
3. Add content (flashcards, quiz, listening, speaking)
4. Click "Validate" to check content
5. Click "Save" to create lesson
6. Click "Publish" to make it available to mobile app

### Edit Lesson
1. Click on lesson in list
2. Modify fields
3. Add change description
4. Click "Save" (creates new version)
5. Click "Publish" to publish changes

### View Versions
1. Click on lesson
2. Click "Version History" tab
3. View all versions with timestamps
4. Click version to view details

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

This creates optimized production files in `build/` directory.

### Deploy Options
- **Vercel**: `vercel deploy`
- **Netlify**: Drag & drop `build/` folder
- **AWS S3**: Upload `build/` to S3 bucket
- **GitHub Pages**: `npm run deploy`

### Environment Variables (Production)
```env
REACT_APP_API_URL=https://your-api-domain.com/api
```

## Future Enhancements

### Phase 1 (Current - Basic)
- ✅ Basic CRUD operations
- ✅ Authentication
- ✅ Content validation
- ✅ Version history

### Phase 2 (Recommended)
- [ ] Rich text editor for content
- [ ] Drag-and-drop file upload for audio/images
- [ ] Bulk operations (import/export)
- [ ] Advanced search and filtering
- [ ] Content preview with mobile simulator

### Phase 3 (Advanced)
- [ ] Real-time collaboration
- [ ] Content analytics dashboard
- [ ] A/B testing for lessons
- [ ] AI-powered content suggestions
- [ ] Multi-language UI

## Troubleshooting

### Issue: "Network Error"
**Solution**: Ensure backend API is running on `http://localhost:3000`

### Issue: "401 Unauthorized"
**Solution**: Login again to refresh token

### Issue: "CORS Error"
**Solution**: Add `http://localhost:3001` to CORS_ORIGIN in backend `.env`

## Support

For issues or questions, refer to:
- Backend API documentation: `demon_teach_backend/README.md`
- Setup guide: `demon_teach_backend/SETUP_GUIDE.md`

---

**Version**: 1.0.0 (Basic)  
**Status**: ✅ Basic implementation complete  
**Next Steps**: Enhance UI/UX with Material-UI or Ant Design
