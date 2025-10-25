# 🚀 POS Enterprise Backend v2.0

Enterprise-grade backend untuk sistem POS multi-cabang dengan PostgreSQL, Redis, dan Socket.IO.

---

## 🎯 Features

- ✅ **RESTful API** - 40+ endpoints
- ✅ **Real-time Sync** - Socket.IO untuk live updates
- ✅ **Multi-Branch** - Support unlimited branches
- ✅ **JWT Authentication** - Secure token-based auth
- ✅ **Redis Caching** - High performance caching
- ✅ **Connection Pooling** - Optimized database connections
- ✅ **Rate Limiting** - API protection
- ✅ **Cluster Mode** - Multi-core support
- ✅ **Auto Restart** - PM2 process management
- ✅ **Comprehensive Logging** - Winston logger

---

## 📋 Prerequisites

- **Node.js** 20.x LTS or higher
- **PostgreSQL** 16.x
- **Redis** 7.x
- **PM2** (for production)

---

## 🚀 Quick Start

### 1. Install Dependencies
```bash
npm install
```

### 2. Setup Database
```bash
# Automated setup (recommended)
npm run setup

# Manual setup
cp .env.example .env
# Edit .env with your configuration
psql -U postgres -d pos_enterprise -f src/database/schema.sql
```

### 3. Start Server

**Development:**
```bash
npm run dev
```

**Production:**
```bash
npm run cluster
```

### 4. Verify
```bash
curl http://localhost:3001/api/v2/health
```

---

## 📁 Project Structure

```
backend_v2/
├── src/
│   ├── config/               # Configuration files
│   │   ├── database.js       # PostgreSQL connection
│   │   └── redis.js          # Redis client
│   ├── controllers/          # Business logic
│   │   ├── productController.js
│   │   └── saleController.js
│   ├── middleware/           # Express middleware
│   │   ├── auth.js           # Authentication
│   │   ├── errorHandler.js   # Error handling
│   │   └── notFoundHandler.js
│   ├── routes/               # API routes
│   │   ├── index.js          # Main router
│   │   ├── authRoutes.js
│   │   ├── productRoutes.js
│   │   └── ...
│   ├── socket/               # Socket.IO handlers
│   │   └── index.js
│   ├── utils/                # Utilities
│   │   └── logger.js         # Winston logger
│   ├── database/             # Database files
│   │   └── schema.sql        # Database schema
│   └── server.js             # Main entry point
├── logs/                     # Log files
├── .env                      # Environment variables
├── .env.example              # Environment template
├── ecosystem.config.cjs      # PM2 configuration
├── package.json
├── DEPLOYMENT.md             # Deployment guide
└── TESTING.md                # Testing guide
```

---

## 🔧 Configuration

### Environment Variables

Copy `.env.example` to `.env` and configure:

```env
# Server
NODE_ENV=production
PORT=3001
API_VERSION=v2

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=pos_enterprise
DB_USER=pos_user
DB_PASSWORD=your_password

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT
JWT_SECRET=your_secret_key
JWT_REFRESH_SECRET=your_refresh_secret
JWT_ACCESS_EXPIRATION=15m
JWT_REFRESH_EXPIRATION=7d
```

---

## 📡 API Endpoints

### Authentication
- `POST /api/v2/auth/login` - Login
- `POST /api/v2/auth/refresh` - Refresh token
- `POST /api/v2/auth/logout` - Logout

### Products
- `GET /api/v2/products` - Get all products
- `GET /api/v2/products/:id` - Get product by ID
- `GET /api/v2/products/search` - Search products
- `GET /api/v2/products/low-stock` - Get low stock items
- `POST /api/v2/products` - Create product
- `PUT /api/v2/products/:id` - Update product
- `DELETE /api/v2/products/:id` - Delete product

### Sales
- `GET /api/v2/sales` - Get all sales
- `GET /api/v2/sales/today` - Get today's sales
- `GET /api/v2/sales/summary` - Get sales summary
- `POST /api/v2/sales` - Create sale
- `PUT /api/v2/sales/:id` - Update sale
- `DELETE /api/v2/sales/:id` - Cancel sale

### Branches
- `GET /api/v2/branches` - Get all branches
- `POST /api/v2/branches` - Create branch
- `PUT /api/v2/branches/:id` - Update branch

### Sync
- `POST /api/v2/sync/push` - Push sync data
- `GET /api/v2/sync/pull` - Pull sync data
- `GET /api/v2/sync/status` - Get sync status

### Health Check
- `GET /api/v2/health` - Server health status

**See [TESTING.md](TESTING.md) for detailed API testing examples.**

---

## 🔌 Socket.IO Events

### Client → Server
- `ping` - Health check
- `product:update` - Product updated
- `stock:update` - Stock updated
- `sale:completed` - Sale completed
- `sync:request` - Request sync

### Server → Client
- `connected` - Connection confirmed
- `pong` - Ping response
- `product:updated` - Product updated notification
- `stock:updated` - Stock updated notification
- `sale:new` - New sale notification
- `sync:response` - Sync response

---

## 🛠️ NPM Scripts

```bash
# Development
npm run dev              # Start with nodemon (auto-reload)

# Production
npm run cluster          # Start with PM2 cluster mode
npm run start            # Start single instance
npm run stop             # Stop PM2
npm run restart          # Restart PM2
npm run reload           # Reload PM2 (zero-downtime)
npm run delete           # Delete PM2 process

# Monitoring
npm run status           # Check PM2 status
npm run logs             # View logs
npm run monit            # Real-time monitoring

# Database
npm run setup            # Automated database setup
npm run db:backup        # Backup database

# Testing
npm test                 # Run tests
npm run test:watch       # Watch mode
npm run lint             # Lint code
```

---

## 🔒 Security

### Implemented
- ✅ JWT authentication with refresh tokens
- ✅ Role-based access control (RBAC)
- ✅ Rate limiting (100 req/15min)
- ✅ Helmet.js security headers
- ✅ CORS configuration
- ✅ SQL injection prevention
- ✅ XSS protection
- ✅ Password hashing (bcrypt)
- ✅ Token blacklisting
- ✅ API key authentication

### Best Practices
1. Change default admin password
2. Use strong JWT secrets
3. Enable HTTPS in production
4. Configure firewall rules
5. Regular security updates
6. Monitor logs for suspicious activity

---

## 📊 Performance

### Optimization
- Connection pooling (2-20 connections)
- Redis caching (1 hour TTL)
- Query optimization with indexes
- Cluster mode for multi-core
- Compression middleware
- Rate limiting

### Monitoring
```bash
# PM2 monitoring
pm2 monit

# Database stats
psql -U pos_user -d pos_enterprise -c "SELECT * FROM pg_stat_database"

# Redis stats
redis-cli INFO stats
```

---

## 🗄️ Database

### Tables (15+)
- `branches` - Branch information
- `users` - User accounts
- `products` - Product master
- `product_stocks` - Stock per branch
- `customers` - Customer data
- `suppliers` - Supplier data
- `sales` - Sales transactions
- `sale_items` - Sales line items
- `purchases` - Purchase orders
- `purchase_items` - Purchase line items
- `sync_logs` - Sync tracking
- `audit_logs` - Audit trail

### Backup
```bash
# Manual backup
pg_dump -U pos_user -F c pos_enterprise > backup.dump

# Restore
pg_restore -U pos_user -d pos_enterprise backup.dump

# Automated backup (see DEPLOYMENT.md)
```

---

## 🧪 Testing

See [TESTING.md](TESTING.md) for comprehensive testing guide.

### Quick Test
```bash
# Health check
curl http://localhost:3001/api/v2/health

# Login
curl -X POST http://localhost:3001/api/v2/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

---

## 🐛 Troubleshooting

### Server won't start
```bash
pm2 logs --err
pm2 restart all
```

### Database connection error
```bash
# Check PostgreSQL
pg_isready -U pos_user -d pos_enterprise

# Check connections
psql -U pos_user -d pos_enterprise -c "SELECT count(*) FROM pg_stat_activity"
```

### Redis not responding
```bash
redis-cli ping  # Should return PONG
```

### Port already in use
```bash
# Windows
netstat -ano | findstr :3001
taskkill /F /PID <PID>

# Linux
lsof -ti:3001 | xargs kill -9
```

---

## 📚 Documentation

- **[Architecture](../ARCHITECTURE.md)** - System architecture
- **[Deployment](DEPLOYMENT.md)** - Production deployment
- **[Testing](TESTING.md)** - API testing guide
- **[Quick Start](../QUICKSTART.md)** - 15-minute setup

---

## 🔄 Updates

### Version 2.0.0 (Current)
- ✅ Complete rewrite with PostgreSQL
- ✅ Redis caching
- ✅ Socket.IO real-time
- ✅ Multi-branch support
- ✅ JWT authentication
- ✅ Cluster mode
- ✅ Comprehensive logging

### Roadmap
- [ ] GraphQL API
- [ ] Microservices architecture
- [ ] Docker support
- [ ] Kubernetes deployment
- [ ] Advanced analytics
- [ ] Machine learning integration

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

---

## 📄 License

MIT License - see [LICENSE](../LICENSE) file

---

## 💡 Tips

### Development
- Use `npm run dev` for auto-reload
- Check logs: `tail -f logs/combined-*.log`
- Use Postman/Insomnia for API testing

### Production
- Always use PM2 cluster mode
- Setup automated backups
- Monitor with `pm2 monit`
- Enable SSL/TLS
- Configure firewall

### Performance
- Use Redis caching extensively
- Optimize database queries
- Monitor slow queries
- Use connection pooling
- Enable compression

---

## 🆘 Support

- 📧 Email: support@yourcompany.com
- 💬 Discord: [Join community](#)
- 🐛 Issues: [GitHub Issues](#)
- 📖 Docs: See markdown files

---

**Built with ❤️ using Node.js, PostgreSQL, Redis & Socket.IO**

Version: 2.0.0-enterprise  
Last Updated: October 2025
