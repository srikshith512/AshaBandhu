# ASHA Bandhu Deployment Guide

## 🚀 Backend Deployment (Vercel)

### Prerequisites
- Vercel account (free tier works)
- PostgreSQL database (use Vercel Postgres, Supabase, or Neon)
- GitHub repository

### Step 1: Set Up PostgreSQL Database

**Option A: Vercel Postgres (Recommended)**
1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Click "Storage" → "Create Database" → "Postgres"
3. Note down the connection details

**Option B: Supabase (Free)**
1. Go to [Supabase](https://supabase.com)
2. Create new project
3. Get connection string from Settings → Database

**Option C: Neon (Free)**
1. Go to [Neon](https://neon.tech)
2. Create new project
3. Get connection string

### Step 2: Deploy Backend to Vercel

#### Via Vercel CLI (Recommended)

```bash
# Install Vercel CLI
npm install -g vercel

# Navigate to backend folder
cd backend

# Login to Vercel
vercel login

# Deploy
vercel

# Follow prompts:
# - Link to existing project? No
# - Project name: asha-bandhu-backend
# - Directory: ./
# - Override settings? No
```

#### Via Vercel Dashboard

1. Go to [Vercel Dashboard](https://vercel.com/new)
2. Import your GitHub repository
3. Configure:
   - **Framework Preset**: Other
   - **Root Directory**: `backend`
   - **Build Command**: (leave empty)
   - **Output Directory**: (leave empty)
   - **Install Command**: `npm install`

### Step 3: Configure Environment Variables

In Vercel Dashboard → Settings → Environment Variables, add:

```
DB_HOST=your-postgres-host
DB_PORT=5432
DB_NAME=asha_bandhu
DB_USER=your-db-user
DB_PASSWORD=your-db-password
PORT=3000
NODE_ENV=production
JWT_SECRET=your-super-secret-jwt-key-change-this
JWT_EXPIRES_IN=24h
CORS_ORIGIN=*
```

**Important**: Generate a secure JWT_SECRET:
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### Step 4: Run Database Migration

After deployment, run migration:

```bash
# Option 1: Via Vercel CLI
vercel env pull .env.production
node scripts/migrate.js

# Option 2: Connect to your database directly
# Use pgAdmin or psql to run the migration SQL
```

### Step 5: Update Flutter App

Update `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'https://your-app.vercel.app';
```

Replace `your-app` with your actual Vercel deployment URL.

---

## 📱 Flutter App Deployment

### Android APK

```bash
# Build release APK
flutter build apk --release

# APK location:
# build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (for Play Store)

```bash
# Build app bundle
flutter build appbundle --release

# Bundle location:
# build/app/outputs/bundle/release/app-release.aab
```

### iOS (requires macOS)

```bash
# Build iOS app
flutter build ios --release

# Then use Xcode to archive and upload to App Store
```

---

## 🌐 Alternative Backend Hosting Options

### Railway.app (Recommended for PostgreSQL + Node.js)

1. Go to [Railway.app](https://railway.app)
2. Create new project
3. Add PostgreSQL database
4. Deploy from GitHub
5. Set environment variables
6. Railway provides database + backend in one place

### Render.com (Free tier available)

1. Go to [Render.com](https://render.com)
2. Create new Web Service
3. Connect GitHub repo
4. Root directory: `backend`
5. Build command: `npm install`
6. Start command: `npm start`
7. Add PostgreSQL database
8. Set environment variables

### Heroku (Paid)

```bash
# Install Heroku CLI
npm install -g heroku

# Login
heroku login

# Create app
heroku create asha-bandhu-backend

# Add PostgreSQL
heroku addons:create heroku-postgresql:mini

# Deploy
git subtree push --prefix backend heroku main

# Run migration
heroku run node scripts/migrate.js
```

---

## 🔒 Security Checklist

- [ ] Change JWT_SECRET to a strong random value
- [ ] Use environment variables for all secrets
- [ ] Enable HTTPS only
- [ ] Set proper CORS_ORIGIN (not *)
- [ ] Use strong database password
- [ ] Enable rate limiting
- [ ] Keep dependencies updated
- [ ] Don't commit .env files

---

## 📊 Monitoring & Logs

### Vercel Logs
```bash
vercel logs
```

### Check Deployment Status
```bash
vercel ls
```

### View Environment Variables
```bash
vercel env ls
```

---

## 🧪 Testing Deployment

```bash
# Test health endpoint
curl https://your-app.vercel.app/health

# Test registration
curl -X POST https://your-app.vercel.app/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"workerId":"TEST001","password":"test123","name":"Test","village":"Test","role":"asha","pin":"1234"}'
```

---

## 🔄 CI/CD (Automatic Deployment)

Vercel automatically deploys when you push to GitHub:

1. Push to `main` branch → Production deployment
2. Push to other branches → Preview deployment

Configure in `vercel.json`:
```json
{
  "github": {
    "enabled": true,
    "autoAlias": true
  }
}
```

---

## 📱 Update Flutter App After Deployment

1. Update API URL in `lib/services/api_service.dart`
2. Rebuild app: `flutter build apk --release`
3. Test thoroughly before distributing
4. Consider using environment-specific configs:

```dart
// lib/config/environment.dart
class Environment {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://your-app.vercel.app',
  );
}

// Build with custom URL:
// flutter build apk --release --dart-define=API_URL=https://your-app.vercel.app
```

---

## 🆘 Troubleshooting

### Database Connection Issues
- Check environment variables are set correctly
- Verify database is accessible from Vercel
- Check PostgreSQL connection limits

### CORS Errors
- Update CORS_ORIGIN in environment variables
- Restart deployment after changing env vars

### Migration Fails
- Connect to database directly
- Run migration SQL manually
- Check database permissions

### App Can't Connect
- Verify API URL in Flutter app
- Check Vercel deployment logs
- Test API endpoints with curl

---

## 📞 Support

For deployment issues:
- Vercel Docs: https://vercel.com/docs
- Railway Docs: https://docs.railway.app
- Render Docs: https://render.com/docs

---

**Deployment Status**: Ready for production ✅
