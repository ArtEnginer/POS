# ⚡ QUICK START GUIDE

Get your POS Enterprise system up and running in 15 minutes!

---

## 🎯 Prerequisites Check

Before starting, ensure you have:
- [ ] Windows 10/11 or Windows Server (or Linux/macOS)
- [ ] Administrator/sudo access
- [ ] Internet connection
- [ ] At least 8GB RAM and 100GB storage

---

## 📦 STEP 1: Install Required Software (10 minutes)

### Option A: Windows (Using Chocolatey - Recommended)

#### Install Chocolatey
```powershell
# Run as Administrator
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

#### Install All Dependencies
```powershell
# PostgreSQL
choco install postgresql16 --params '/Password:admin123'

# Redis
choco install redis-64

# Node.js
choco install nodejs-lts

# Git (if not installed)


```

### Option B: Manual Installation

1. **PostgreSQL 16**
   - Download: https://www.postgresql.org/download/windows/
   - Install with default settings
   - Remember your postgres password!

2. **Redis 7**
   - Download: https://github.com/microsoftarchive/redis/releases
   - Extract and run `redis-server.exe`

3. **Node.js 20 LTS**
   - Download: https://nodejs.org/
   - Install with default settings

---

## 🗄️ STEP 2: Setup Database (3 minutes)

### Create Database
```powershell
# Open PowerShell as Administrator

# Login to PostgreSQL
psql -U postgres

# In psql prompt:
CREATE DATABASE pos_enterprise;
CREATE USER pos_user WITH ENCRYPTED PASSWORD 'pos_password_2024';
GRANT ALL PRIVILEGES ON DATABASE pos_enterprise TO pos_user;
\q
```

### Import Schema
```powershell
# Navigate to project directory
cd backend_v2

# Import schema
psql -U postgres -d pos_enterprise -f src/database/schema.sql
```

You should see: `Database schema created successfully!`

---

## 🚀 STEP 3: Setup Backend (2 minutes)

```powershell
# In backend_v2 directory
cd backend_v2

# Install dependencies (this might take 1-2 minutes)
npm install

# Install PM2 globally
npm install -g pm2

# Copy environment file
copy .env.example .env

# Edit .env file (optional - default settings will work)
notepad .env
```

### Start Backend Server
```powershell
# Development mode (for testing)
npm run dev

# OR Production mode with PM2 (recommended)
npm run cluster
```

### Verify Backend is Running
```powershell
# Open new PowerShell window
curl http://localhost:3001/api/v2/health
```

Expected response:
```json
{
  "status": "OK",
  "services": {
    "database": "connected",
    "redis": "connected"
  }
}
```

✅ If you see this, backend is running successfully!

---

## 📱 STEP 4: Setup Flutter App (Optional - 5 minutes)

### Install Flutter (if not installed)
```powershell
# Using Chocolatey
choco install flutter

# Verify installation
flutter doctor
```

### Setup POS App
```powershell
# Navigate to project root
cd ..

# Get dependencies
flutter pub get

# Run on Windows desktop
flutter run -d windows
```

### Build Release Version
```powershell
# Build for Windows
flutter build windows --release

# Executable will be in: build\windows\runner\Release\
```

---

## ✅ STEP 5: First Login

### Default Credentials
```
Username: admin
Password: admin123
```

### Test API Login
```powershell
# Using curl
curl -X POST http://localhost:3001/api/v2/auth/login `
  -H "Content-Type: application/json" `
  -d '{\"username\":\"admin\",\"password\":\"admin123\"}'
```

You should get a response with `accessToken` and `refreshToken`.

---

## 🎉 SUCCESS! What's Next?

### Immediate Actions
1. ✅ Change default admin password
   ```powershell
   # Call change password API
   ```

2. ✅ Create your first branch
   ```powershell
   # Via API or Flutter app
   ```

3. ✅ Add products
   ```powershell
   # Via Flutter app
   ```

4. ✅ Create users for your staff
   ```powershell
   # Via Flutter app (Admin panel)
   ```

---

## 🛠️ Useful Commands

### Backend Management
```powershell
# Check status
pm2 status

# View logs
pm2 logs

# Restart
pm2 restart all

# Stop
pm2 stop all

# Monitor
pm2 monit
```

### Database Management
```powershell
# Connect to database
psql -U pos_user -d pos_enterprise

# Backup database
pg_dump -U pos_user -F c pos_enterprise > backup.dump

# Restore database
pg_restore -U pos_user -d pos_enterprise backup.dump
```

### Redis Management
```powershell
# Connect to Redis
redis-cli

# Check status
redis-cli ping  # Should return: PONG

# View all keys
redis-cli KEYS *

# Clear cache
redis-cli FLUSHDB
```

---

## 🐛 Quick Troubleshooting

### Backend won't start
```powershell
# Check if port 3001 is in use
netstat -ano | findstr :3001

# Kill process if needed
taskkill /F /PID <PID>

# Check logs
pm2 logs --err
```

### Database connection error
```powershell
# Check PostgreSQL service
Get-Service postgresql-x64-16

# Start if stopped
Start-Service postgresql-x64-16

# Test connection
psql -U postgres -d pos_enterprise
```

### Redis not responding
```powershell
# Check Redis service
Get-Service redis

# Start if stopped
Start-Service redis

# Or run manually
redis-server
```

---

## 📚 Learn More

- **[Full Documentation](ARCHITECTURE.md)** - Complete architecture guide
- **[Deployment Guide](backend_v2/DEPLOYMENT.md)** - Production deployment
- **[API Reference](backend_v2/API_DOCS.md)** - REST API documentation
- **[Flutter Migration](FLUTTER_MIGRATION.md)** - Migrate Flutter app

---

## 🎯 Performance Tips

### For Better Performance:
1. **Use SSD** for database storage
2. **Increase PostgreSQL** `shared_buffers` to 25% of RAM
3. **Enable Redis persistence** for production
4. **Use PM2 cluster mode** for multiple CPU cores
5. **Setup Nginx** as reverse proxy for load balancing

### Quick Performance Tuning
```powershell
# Edit PostgreSQL config
notepad "C:\Program Files\PostgreSQL\16\data\postgresql.conf"

# Change:
shared_buffers = 2GB              # 25% of RAM
effective_cache_size = 6GB        # 75% of RAM
maintenance_work_mem = 512MB
work_mem = 32MB
```

---

## 🆘 Need Help?

### Common Issues
- **Port conflicts**: Change PORT in .env
- **Database errors**: Check PostgreSQL logs
- **Redis errors**: Restart Redis service
- **PM2 errors**: Run `pm2 kill` and start again

### Get Support
- 📧 Email: support@yourcompany.com
- 💬 Discord: [Join community](#)
- 🐛 Issues: [GitHub Issues](#)

---

## ✨ Quick Tips

### Development Workflow
```powershell
# Watch mode for development
npm run dev

# Format code
npm run lint

# Run tests
npm test
```

### Production Workflow
```powershell
# Start with PM2
npm run cluster

# View dashboard
pm2 web

# Monitor performance
pm2 monit

# Save configuration
pm2 save
```

---

## 🎊 Congratulations!

Your POS Enterprise system is now running!

**Next Steps:**
1. Read the [Architecture Documentation](ARCHITECTURE.md)
2. Setup your first branch
3. Import your product catalog
4. Train your staff
5. Go live! 🚀

---

**Estimated Total Time: 15-20 minutes** ⏱️

Happy selling! 🛒💰
