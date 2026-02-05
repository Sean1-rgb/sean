const express = require('express');
const redis = require('redis');
const app = express();
const PORT = process.env.PORT || 5000;

// Redis 配置
const REDIS_HOST = process.env.REDIS_HOST || 'redis';
const REDIS_PORT = process.env.REDIS_PORT || 6379;

// 初始化 Redis 客户端
let redisClient = null;

async function initRedis() {
    try {
        redisClient = redis.createClient({
            socket: {
                host: REDIS_HOST,
                port: REDIS_PORT
            }
        });

        redisClient.on('error', (err) => {
            console.error('Redis 客户端错误:', err);
        });

        redisClient.on('connect', () => {
            console.log('Redis 连接成功');
        });

        await redisClient.connect();
        console.log(`Redis 已连接到 ${REDIS_HOST}:${REDIS_PORT}`);
    } catch (error) {
        console.warn('Redis 连接失败，应用将继续运行（Redis 功能不可用）:', error.message);
        redisClient = null;
    }
}

// 启动时初始化 Redis
initRedis();

app.get('/', async (req, res) => {
    let visitCount = null;
    
    // 如果 Redis 可用，获取访问计数
    if (redisClient) {
        try {
            visitCount = await redisClient.incr('visit_count');
            await redisClient.set('last_visit', new Date().toISOString());
        } catch (error) {
            console.error('Redis 操作错误:', error);
        }
    }

    res.json({
        message: 'CI/CD演示应用运行成功！',
        version: '1.0.0',
        timestamp: new Date().toISOString(),
        redis: {
            connected: redisClient !== null,
            visitCount: visitCount
        }
    });
});

app.get('/health', async (req, res) => {
    const redisStatus = redisClient ? 'connected' : 'disconnected';
    
    res.json({
        status: 'healthy',
        redis: redisStatus,
        timestamp: new Date().toISOString()
    });
});

app.get('/redis/test', async (req, res) => {
    if (!redisClient) {
        return res.status(503).json({
            error: 'Redis 未连接',
            message: '请检查 Redis 服务是否正常运行'
        });
    }

    try {
        const testKey = 'test_key';
        const testValue = `测试值_${Date.now()}`;
        
        await redisClient.set(testKey, testValue);
        const retrievedValue = await redisClient.get(testKey);
        
        res.json({
            success: true,
            message: 'Redis 测试成功',
            data: {
                set: testValue,
                get: retrievedValue,
                match: testValue === retrievedValue
            }
        });
    } catch (error) {
        res.status(500).json({
            error: 'Redis 操作失败',
            message: error.message
        });
    }
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`服务器运行在端口 ${PORT}`);
    console.log(`Redis 配置: ${REDIS_HOST}:${REDIS_PORT}`);
});
