import { createClient } from "redis";
import dotenv from "dotenv";

dotenv.config();

// Redis Client Configuration
const redisConfig = {
  socket: {
    host: process.env.REDIS_HOST || "localhost",
    port: parseInt(process.env.REDIS_PORT) || 6379,
    reconnectStrategy: (retries) => {
      if (retries > 10) {
        console.error("Redis connection failed after 10 retries");
        return new Error("Redis connection failed");
      }
      return Math.min(retries * 100, 3000);
    },
  },
  password: process.env.REDIS_PASSWORD || undefined,
  database: parseInt(process.env.REDIS_DB) || 0,
};

// Create Redis client
const redisClient = createClient(redisConfig);

// Redis Pub/Sub clients
const publisherClient = createClient(redisConfig);
const subscriberClient = createClient(redisConfig);

// Error handlers
redisClient.on("error", (err) => {
  console.error("Redis Client Error:", err);
});

redisClient.on("connect", () => {
  console.log("✓ Redis connected successfully");
});

redisClient.on("reconnecting", () => {
  console.log("Redis reconnecting...");
});

redisClient.on("ready", () => {
  console.log("Redis client ready");
});

// Connect to Redis
const connectRedis = async () => {
  try {
    await redisClient.connect();
    await publisherClient.connect();
    await subscriberClient.connect();
    console.log("✓ All Redis clients connected");
  } catch (error) {
    console.error("Failed to connect to Redis:", error);
    process.exit(1);
  }
};

/**
 * Cache wrapper with automatic serialization
 */
class RedisCache {
  constructor(client) {
    this.client = client;
    this.defaultTTL = parseInt(process.env.REDIS_CACHE_TTL) || 3600;
  }

  /**
   * Set cache with TTL
   * @param {string} key
   * @param {any} value
   * @param {number} ttl - Time to live in seconds
   */
  async set(key, value, ttl = this.defaultTTL) {
    try {
      const serialized = JSON.stringify(value);
      await this.client.setEx(key, ttl, serialized);
      return true;
    } catch (error) {
      console.error("Redis SET error:", error);
      return false;
    }
  }

  /**
   * Get cache value
   * @param {string} key
   * @returns {Promise<any>}
   */
  async get(key) {
    try {
      const value = await this.client.get(key);
      return value ? JSON.parse(value) : null;
    } catch (error) {
      console.error("Redis GET error:", error);
      return null;
    }
  }

  /**
   * Delete cache key
   * @param {string} key
   */
  async del(key) {
    try {
      await this.client.del(key);
      return true;
    } catch (error) {
      console.error("Redis DEL error:", error);
      return false;
    }
  }

  /**
   * Delete keys by pattern
   * @param {string} pattern
   */
  async delPattern(pattern) {
    try {
      const keys = await this.client.keys(pattern);
      if (keys.length > 0) {
        await this.client.del(keys);
      }
      return keys.length;
    } catch (error) {
      console.error("Redis DEL pattern error:", error);
      return 0;
    }
  }

  /**
   * Check if key exists
   * @param {string} key
   */
  async exists(key) {
    try {
      return await this.client.exists(key);
    } catch (error) {
      console.error("Redis EXISTS error:", error);
      return false;
    }
  }

  /**
   * Increment counter
   * @param {string} key
   */
  async incr(key) {
    try {
      return await this.client.incr(key);
    } catch (error) {
      console.error("Redis INCR error:", error);
      return null;
    }
  }

  /**
   * Set expiration on key
   * @param {string} key
   * @param {number} seconds
   */
  async expire(key, seconds) {
    try {
      return await this.client.expire(key, seconds);
    } catch (error) {
      console.error("Redis EXPIRE error:", error);
      return false;
    }
  }

  /**
   * Get or set cache (cache-aside pattern)
   * @param {string} key
   * @param {Function} fetchFn - Function to fetch data if cache miss
   * @param {number} ttl
   */
  async getOrSet(key, fetchFn, ttl = this.defaultTTL) {
    try {
      // Try to get from cache
      const cached = await this.get(key);
      if (cached !== null) {
        return cached;
      }

      // Cache miss - fetch data
      const data = await fetchFn();
      if (data !== null) {
        await this.set(key, data, ttl);
      }
      return data;
    } catch (error) {
      console.error("Redis getOrSet error:", error);
      // Fallback to direct fetch on error
      return await fetchFn();
    }
  }

  /**
   * Clear all cache
   */
  async flush() {
    try {
      await this.client.flushDb();
      return true;
    } catch (error) {
      console.error("Redis FLUSH error:", error);
      return false;
    }
  }
}

/**
 * Sync Queue Manager using Redis
 */
class SyncQueue {
  constructor(client) {
    this.client = client;
    this.queueKey = "sync:queue";
  }

  /**
   * Add item to sync queue
   * @param {Object} item
   */
  async add(item) {
    try {
      const data = {
        ...item,
        timestamp: Date.now(),
        id: `sync_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      };
      await this.client.rPush(this.queueKey, JSON.stringify(data));
      return data.id;
    } catch (error) {
      console.error("Queue add error:", error);
      return null;
    }
  }

  /**
   * Get next item from queue
   */
  async next() {
    try {
      const item = await this.client.lPop(this.queueKey);
      return item ? JSON.parse(item) : null;
    } catch (error) {
      console.error("Queue next error:", error);
      return null;
    }
  }

  /**
   * Get queue length
   */
  async length() {
    try {
      return await this.client.lLen(this.queueKey);
    } catch (error) {
      console.error("Queue length error:", error);
      return 0;
    }
  }

  /**
   * Clear queue
   */
  async clear() {
    try {
      await this.client.del(this.queueKey);
      return true;
    } catch (error) {
      console.error("Queue clear error:", error);
      return false;
    }
  }
}

// Create instances
const cache = new RedisCache(redisClient);
const syncQueue = new SyncQueue(redisClient);

/**
 * Redis health check
 */
const healthCheck = async () => {
  try {
    await redisClient.ping();
    return true;
  } catch (error) {
    console.error("Redis health check failed:", error);
    return false;
  }
};

/**
 * Close all Redis connections
 */
const closeRedis = async () => {
  try {
    await redisClient.quit();
    await publisherClient.quit();
    await subscriberClient.quit();
    console.log("Redis connections closed");
  } catch (error) {
    console.error("Error closing Redis connections:", error);
  }
};

export {
  redisClient,
  publisherClient,
  subscriberClient,
  cache,
  syncQueue,
  connectRedis,
  healthCheck,
  closeRedis,
};

export default {
  client: redisClient,
  publisher: publisherClient,
  subscriber: subscriberClient,
  cache,
  syncQueue,
  connect: connectRedis,
  healthCheck,
  close: closeRedis,
};
