module.exports = {
  apps: [
    {
      name: "pos-api",
      script: "./src/server.js",
      instances: "max", // Auto-scale berdasarkan CPU cores
      exec_mode: "cluster",
      watch: false,
      max_memory_restart: "1G",
      env: {
        NODE_ENV: "development",
        PORT: 3001,
      },
      env_production: {
        NODE_ENV: "production",
        PORT: 3001,
      },
      error_file: "./logs/pm2-error.log",
      out_file: "./logs/pm2-out.log",
      log_date_format: "YYYY-MM-DD HH:mm:ss Z",
      merge_logs: true,
      autorestart: true,
      max_restarts: 10,
      min_uptime: "10s",
      listen_timeout: 3000,
      kill_timeout: 5000,
    },
    {
      name: "pos-worker",
      script: "./src/workers/sync-worker.js",
      instances: 1,
      exec_mode: "fork",
      watch: false,
      max_memory_restart: "500M",
      env: {
        NODE_ENV: "development",
      },
      env_production: {
        NODE_ENV: "production",
      },
      autorestart: true,
    },
    {
      name: "pos-scheduler",
      script: "./src/workers/scheduler.js",
      instances: 1,
      exec_mode: "fork",
      watch: false,
      max_memory_restart: "300M",
      env: {
        NODE_ENV: "development",
      },
      env_production: {
        NODE_ENV: "production",
      },
      autorestart: true,
    },
  ],
};
