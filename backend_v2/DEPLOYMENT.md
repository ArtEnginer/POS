# 🚀 DEPLOYMENT GUIDE - POS ENTERPRISE BACKEND

## 📋 Prerequisites

### Windows Server / Desktop
- Windows 10/11 atau Windows Server 2019/2022
- Minimal 8GB RAM, 4 CPU cores
- 100GB+ storage (SSD recommended)
- Administrator access

### Software Requirements
1. **PostgreSQL 16**
2. **Redis 7**
3. **Node.js 20 LTS**
4. **PM2** (Process Manager)
5. **Nginx** (Optional, untuk production)

---

## 📦 STEP 1: Install PostgreSQL

### Download & Install
```powershell
# Download PostgreSQL 16 dari:
# https://www.postgresql.org/download/windows/

# Atau install via Chocolatey:
choco install postgresql16 --params '/Password:your_secure_password'
```

### Configuration
1. Jalankan **pgAdmin 4** atau **psql**
2. Create database:

```sql
-- Login as postgres user
CREATE DATABASE pos_enterprise;
CREATE USER pos_user WITH ENCRYPTED PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE pos_enterprise TO pos_user;
```

3. Import schema:

```powershell
cd backend_v2
psql -U postgres -d pos_enterprise -f src/database/schema.sql
```

### Optimize PostgreSQL (Edit postgresql.conf)
```conf
# Memory Settings
shared_buffers = 2GB
effective_cache_size = 6GB
maintenance_work_mem = 512MB
work_mem = 32MB

# Connection Settings
max_connections = 200

# Performance
random_page_cost = 1.1  # For SSD
effective_io_concurrency = 200
```

Restart PostgreSQL service:
```powershell
Restart-Service postgresql-x64-16
```

---

## 📦 STEP 2: Install Redis

### Download & Install
```powershell
# Download Redis for Windows dari:
# https://github.com/microsoftarchive/redis/releases

# Extract dan install sebagai Windows Service
redis-server --service-install redis.windows.conf
redis-server --service-start
```

### Test Redis
```powershell
redis-cli ping
# Should return: PONG
```

### Redis Configuration (redis.windows.conf)
```conf
# Max memory
maxmemory 1gb
maxmemory-policy allkeys-lru

# Persistence
save 900 1
save 300 10
save 60 10000

# Security (production)
# requirepass your_redis_password
```

---

## 📦 STEP 3: Install Node.js & Dependencies

### Install Node.js
```powershell
# Download Node.js 20 LTS dari:
# https://nodejs.org/

# Atau install via Chocolatey:
choco install nodejs-lts

# Verify installation
node --version  # v20.x.x
npm --version   # 10.x.x
```

### Install Backend Dependencies
```powershell
cd backend_v2
npm install

# Install PM2 globally
npm install -g pm2
npm install -g pm2-windows-service
```

---

## 🔧 STEP 4: Configuration

### Create .env file
```powershell
cp .env.example .env
```

### Edit .env file (Notepad atau VS Code)
```env
NODE_ENV=production
PORT=3001
API_VERSION=v2

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=pos_enterprise
DB_USER=pos_user
DB_PASSWORD=your_secure_password

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# JWT (Generate random secret)
JWT_SECRET=your_super_secret_jwt_key_change_this
JWT_REFRESH_SECRET=your_refresh_token_secret

# Lainnya sesuaikan dengan kebutuhan
```

### Generate JWT Secret
```powershell
# Generate random secret
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

---

## 🚀 STEP 5: Start Application

### Development Mode
```powershell
cd backend_v2
npm run dev
```

### Production Mode dengan PM2

#### Install PM2 as Windows Service
```powershell
pm2-service-install
# Follow the prompts
```

#### Start Application
```powershell
cd backend_v2
npm run cluster

# Or manually:
pm2 start ecosystem.config.cjs
```

#### PM2 Commands
```powershell
# View status
pm2 status
pm2 monit

# View logs
pm2 logs

# Restart
pm2 restart all

# Stop
pm2 stop all

# Save configuration
pm2 save

# Startup on boot
pm2 startup
```

---

## 🌐 STEP 6: Install Nginx (Optional, untuk Load Balancer)

### Download & Install
```powershell
# Download Nginx untuk Windows dari:
# https://nginx.org/en/download.html

# Extract ke C:\nginx
```

### Configuration (C:\nginx\conf\nginx.conf)
```nginx
worker_processes auto;

events {
    worker_connections 1024;
}

http {
    upstream pos_backend {
        least_conn;
        server localhost:3001;
        server localhost:3002;  # Jika ada multiple instances
    }

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

    server {
        listen 80;
        server_name localhost;

        # API proxy
        location /api/ {
            limit_req zone=api_limit burst=20 nodelay;
            
            proxy_pass http://pos_backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_cache_bypass $http_upgrade;
        }

        # Socket.IO
        location /socket.io/ {
            proxy_pass http://pos_backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
        }
    }
}
```

### Start Nginx
```powershell
cd C:\nginx
start nginx

# Test configuration
nginx -t

# Reload configuration
nginx -s reload

# Stop
nginx -s stop
```

---

## ✅ STEP 7: Verification

### Test API
```powershell
# Health check
curl http://localhost:3001/api/v2/health

# Expected response:
{
  "status": "OK",
  "services": {
    "database": "connected",
    "redis": "connected",
    "socketio": "idle"
  }
}
```

### Test Socket.IO
```javascript
// test-socket.js
const io = require('socket.io-client');

const socket = io('http://localhost:3001', {
  auth: {
    branchId: 1,
    userId: 1
  }
});

socket.on('connect', () => {
  console.log('Connected:', socket.id);
  socket.emit('ping');
});

socket.on('pong', (data) => {
  console.log('Pong received:', data);
});
```

Run test:
```powershell
node test-socket.js
```

---

## 🔒 STEP 8: Security (Production)

### 1. Firewall Rules
```powershell
# Allow PostgreSQL (local only)
netsh advfirewall firewall add rule name="PostgreSQL" dir=in action=allow protocol=TCP localport=5432 remoteip=127.0.0.1

# Allow Redis (local only)
netsh advfirewall firewall add rule name="Redis" dir=in action=allow protocol=TCP localport=6379 remoteip=127.0.0.1

# Allow Nginx/API (from network)
netsh advfirewall firewall add rule name="API Server" dir=in action=allow protocol=TCP localport=80,443
```

### 2. SSL/TLS (Production)
```powershell
# Generate self-signed certificate (for testing)
# Or use Let's Encrypt / Commercial Certificate

# Update Nginx config untuk HTTPS
```

### 3. Database Security
```sql
-- Revoke public access
REVOKE ALL ON DATABASE pos_enterprise FROM PUBLIC;

-- Limit connections
ALTER ROLE pos_user CONNECTION LIMIT 50;

-- Set password expiry
ALTER ROLE pos_user VALID UNTIL '2026-12-31';
```

---

## 📊 STEP 9: Monitoring

### PM2 Monitoring
```powershell
pm2 monit       # Real-time monitoring
pm2 logs        # View logs
pm2 status      # Check status
```

### PostgreSQL Monitoring
```sql
-- Active connections
SELECT count(*) FROM pg_stat_activity;

-- Slow queries
SELECT * FROM pg_stat_statements 
ORDER BY mean_exec_time DESC 
LIMIT 10;

-- Database size
SELECT pg_size_pretty(pg_database_size('pos_enterprise'));
```

### Redis Monitoring
```powershell
redis-cli info stats
redis-cli info memory
```

---

## 🔄 STEP 10: Backup & Maintenance

### Database Backup
```powershell
# Manual backup
pg_dump -U pos_user -F c pos_enterprise > backup_$(Get-Date -Format "yyyyMMdd_HHmmss").dump

# Automated backup (Task Scheduler)
# Create backup script: backup.ps1
```

**backup.ps1**:
```powershell
$date = Get-Date -Format "yyyyMMdd_HHmmss"
$backupPath = "D:\Backups\POS"
$filename = "pos_backup_$date.dump"

pg_dump -U pos_user -F c pos_enterprise > "$backupPath\$filename"

# Keep only last 30 days
Get-ChildItem $backupPath -Filter "*.dump" | 
    Where-Object {$_.CreationTime -lt (Get-Date).AddDays(-30)} | 
    Remove-Item
```

Schedule with Task Scheduler:
```powershell
# Run daily at 2 AM
schtasks /create /tn "POS_Backup" /tr "powershell.exe -File D:\Scripts\backup.ps1" /sc daily /st 02:00
```

### Redis Backup
Redis akan auto-save berdasarkan config. Copy file `dump.rdb` untuk backup.

---

## 🚨 Troubleshooting

### PostgreSQL Connection Error
```powershell
# Check service status
Get-Service postgresql-x64-16

# Check logs
type "C:\Program Files\PostgreSQL\16\data\log\postgresql-*.log"
```

### Redis Connection Error
```powershell
# Check service status
Get-Service redis

# Test connection
redis-cli ping
```

### PM2 Not Starting
```powershell
# Check PM2 logs
pm2 logs --err

# Restart PM2
pm2 kill
pm2 resurrect
```

### Port Already in Use
```powershell
# Find process using port
netstat -ano | findstr :3001

# Kill process
taskkill /F /PID <PID>
```

---

## 📚 Next Steps

1. ✅ Setup database
2. ✅ Start backend server
3. ⏭️ Configure Flutter app untuk connect ke backend
4. ⏭️ Setup cabang (branches)
5. ⏭️ Import master data
6. ⏭️ Training user

---

## 📞 Support

Jika ada error atau pertanyaan, check:
- Application logs: `backend_v2/logs/`
- PM2 logs: `pm2 logs`
- PostgreSQL logs: `C:\Program Files\PostgreSQL\16\data\log\`

---

**Deployment checklist completed! ✅**
