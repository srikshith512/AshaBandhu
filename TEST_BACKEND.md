# Backend Testing Guide

## Step 1: Verify Backend is Running

```powershell
cd backend
npm run dev
```

Should show:
```
🚀 ASHA Bandhu Backend Server running on port 3000
🌍 Environment: development
📊 Health check: http://localhost:3000/health
```

## Step 2: Test Health Endpoint

Open browser or use curl:
```powershell
curl http://localhost:3000/health
```

Should return:
```json
{
  "status": "OK",
  "timestamp": "2025-10-03T...",
  "uptime": 123.456,
  "environment": "development"
}
```

## Step 3: Test Registration (Creates Token)

```powershell
curl -X POST http://localhost:3000/api/auth/register `
  -H "Content-Type: application/json" `
  -d '{
    "workerId": "TEST001",
    "password": "test123",
    "name": "Test User",
    "village": "Test Village",
    "role": "asha",
    "pin": "1234"
  }'
```

Should return:
```json
{
  "success": true,
  "message": "Worker registered successfully",
  "data": {
    "worker": { ... },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

## Step 4: Test Login (Gets Token)

```powershell
curl -X POST http://localhost:3000/api/auth/login `
  -H "Content-Type: application/json" `
  -d '{
    "workerId": "TEST001",
    "password": "test123"
  }'
```

Should return token in response.

## Step 5: In Flutter App

### For Password Login (Online Mode):
1. **Start backend** first
2. **Login screen** → Select "Password" mode
3. **Enter credentials** that exist in backend
4. **Should get token** and be able to sync

### For PIN Login (Offline Mode):
1. **No backend needed**
2. **Login screen** → Select "PIN (Offline)" mode  
3. **Enter Worker ID + PIN**
4. **Works offline** but cannot sync with server

## Troubleshooting

### "Access denied. No token provided"
- **Cause**: Using PIN login OR password login failed to get token
- **Fix**: 
  1. Ensure backend is running
  2. Use **Password** login (not PIN)
  3. Check backend logs for errors

### "Connection refused"
- **Cause**: Backend not running or wrong URL
- **Fix**:
  1. Start backend: `cd backend && npm run dev`
  2. Verify URL in `lib/services/api_service.dart`:
     - Emulator: `http://10.0.2.2:3000`
     - Physical device: `http://YOUR_PC_IP:3000`

### Patients not syncing
- **Cause**: No auth token (PIN login) or backend error
- **Fix**:
  1. Logout
  2. Login with **Password** (not PIN)
  3. Tap "Pending Sync" in drawer
  4. Check console for sync logs

## Expected Console Output

### Successful Password Login:
```
✅ Auth token stored: eyJhbGciOiJIUzI1NiI...
✅ Loaded 5 patients (3 from API)
```

### PIN Login (Offline):
```
📴 Offline mode (PIN login) - using local data only
✅ Loaded 5 patients (0 from API)
```

### Successful Sync:
```
🔄 Fetching all patients from server after sync...
📥 Received 10 patients from server
✅ Sync complete: 2 uploaded, 10 total from server, 10 in local DB
```
