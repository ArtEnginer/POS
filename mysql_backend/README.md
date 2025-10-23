# MySQL REST API Backend untuk POS

Backend sederhana untuk sync data antara Flutter POS dan MySQL Server.

## Prerequisites

- Node.js (v14 atau lebih baru)
- MySQL Server (v5.7 atau lebih baru)
- npm atau yarn

## Instalasi

1. Install dependencies:
```bash
npm install
```

2. Buat database MySQL:
```sql
CREATE DATABASE pos_db;
```

3. Import schema dari file `schema.sql`

4. Konfigurasi environment variables di `.env`:
```
PORT=3306
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=pos_db
JWT_SECRET=your_jwt_secret
```

5. Jalankan server:
```bash
npm start
```

## Development

Jalankan dengan auto-reload:
```bash
npm run dev
```

## Endpoints

### Health Check
- `GET /api/v1/health` - Check server status

### Tables (Generic CRUD)
- `GET /api/v1/tables/:table` - Query data
- `POST /api/v1/tables/:table` - Insert data
- `POST /api/v1/tables/:table/batch` - Batch insert
- `PUT /api/v1/tables/:table` - Update data
- `DELETE /api/v1/tables/:table` - Delete data

### Query
- `POST /api/v1/query` - Execute custom query

## Security

API menggunakan basic authentication dengan username dan password database.
Untuk production, gunakan JWT atau OAuth.

## Tables Supported

- products
- categories
- suppliers
- customers
- purchases
- purchase_items
- receivings
- receiving_items
- purchase_returns
- purchase_return_items
- transactions
- transaction_items
- stock_movements
