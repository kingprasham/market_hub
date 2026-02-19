# Market Hub - Backend & Real-Time Architecture

## 1. SYSTEM OVERVIEW

```
                                    ┌──────────────────────────────────┐
                                    │         DATA SOURCES             │
                                    │  ┌────────┐ ┌────────┐ ┌──────┐  │
                                    │  │  LME   │ │  SHFE  │ │COMEX │  │
                                    │  └───┬────┘ └───┬────┘ └──┬───┘  │
                                    │  ┌───┴────┐ ┌───┴────┐ ┌──┴───┐  │
                                    │  │   FX   │ │Economic│ │ News │  │
                                    │  └────────┘ └────────┘ └──────┘  │
                                    └──────────────┬───────────────────┘
                                                   │
                                                   ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                              BACKEND SERVER                                   │
│                                                                              │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────────┐  │
│  │   SCRAPER       │    │   REDIS CACHE   │    │    API SERVER           │  │
│  │   SERVICE       │───▶│                 │◀───│    (Express/Fastify)    │  │
│  │                 │    │  - Market Data  │    │                         │  │
│  │  - LME Scraper  │    │  - Spot Prices  │    │  - REST Endpoints       │  │
│  │  - SHFE Scraper │    │  - FX Rates     │    │  - Authentication       │  │
│  │  - COMEX Scraper│    │  - Reference    │    │  - User Management      │  │
│  │  - FX Scraper   │    │    Rates        │    │  - Content Management   │  │
│  │  - News Scraper │    │  - Sessions     │    │                         │  │
│  └─────────────────┘    └─────────────────┘    └─────────────────────────┘  │
│           │                      ▲                         │                 │
│           │                      │                         │                 │
│           ▼                      │                         ▼                 │
│  ┌─────────────────┐    ┌───────┴─────────┐    ┌─────────────────────────┐  │
│  │  WEBSOCKET      │    │    MONGODB      │    │    FILE STORAGE         │  │
│  │  SERVER         │    │                 │    │    (S3/Cloudinary)      │  │
│  │                 │    │  - Users        │    │                         │  │
│  │  - Market Feed  │    │  - Plans        │    │  - Visiting Cards       │  │
│  │  - Spot Feed    │    │  - Content      │    │  - News Images          │  │
│  │  - FX Feed      │    │  - Watchlists   │    │  - PDFs                 │  │
│  │  - News Feed    │    │  - Feedback     │    │  - Circulars            │  │
│  └────────┬────────┘    └─────────────────┘    └─────────────────────────┘  │
│           │                                                                  │
└───────────┼──────────────────────────────────────────────────────────────────┘
            │
            ▼
┌───────────────────────────────────────────────────────────────────────────────┐
│                              CLIENTS                                          │
│                                                                               │
│   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐   │
│   │   Flutter   │    │   Flutter   │    │    Admin    │    │    Admin    │   │
│   │   Android   │    │     iOS     │    │  Dashboard  │    │   Mobile    │   │
│   │     App     │    │     App     │    │    (Web)    │    │    (App)    │   │
│   └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘   │
│                                                                               │
└───────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. SCRAPER SERVICE SPECIFICATIONS

### 2.1 Scraper Architecture

```javascript
// scraper/index.js
const cron = require('node-cron');
const redis = require('./redis');
const { scrapeLME, scrapeSHFE, scrapeCOMEX, scrapeFX } = require('./scrapers');

class ScraperService {
  constructor() {
    this.isRunning = false;
    this.intervals = {
      market: 5000,      // 5 seconds for market data
      fx: 5000,          // 5 seconds for FX rates
      reference: 300000, // 5 minutes for reference rates
      news: 60000,       // 1 minute for live news feed
      economic: 30000,   // 30 seconds for economic calendar
    };
  }

  async start() {
    if (this.isRunning) return;
    this.isRunning = true;

    // Market Data (LME, SHFE, COMEX) - every 5 seconds
    this.marketInterval = setInterval(async () => {
      await this.scrapeMarketData();
    }, this.intervals.market);

    // FX Rates - every 5 seconds
    this.fxInterval = setInterval(async () => {
      await this.scrapeFXData();
    }, this.intervals.fx);

    // Reference Rates - every 5 minutes
    this.refInterval = setInterval(async () => {
      await this.scrapeReferenceRates();
    }, this.intervals.reference);

    // News Feed - every 1 minute
    this.newsInterval = setInterval(async () => {
      await this.scrapeNewsFeed();
    }, this.intervals.news);

    // Economic Calendar - every 30 seconds
    this.economicInterval = setInterval(async () => {
      await this.scrapeEconomicCalendar();
    }, this.intervals.economic);

    console.log('Scraper service started');
  }

  async scrapeMarketData() {
    try {
      const [lme, shfe, comex] = await Promise.allSettled([
        scrapeLME(),
        scrapeSHFE(),
        scrapeCOMEX(),
      ]);

      if (lme.status === 'fulfilled') {
        await redis.set('market:lme', JSON.stringify(lme.value), 'EX', 60);
        this.publishUpdate('lme', lme.value);
      }

      if (shfe.status === 'fulfilled') {
        await redis.set('market:shfe', JSON.stringify(shfe.value), 'EX', 60);
        this.publishUpdate('shfe', shfe.value);
      }

      if (comex.status === 'fulfilled') {
        await redis.set('market:comex', JSON.stringify(comex.value), 'EX', 60);
        this.publishUpdate('comex', comex.value);
      }
    } catch (error) {
      console.error('Market scrape error:', error);
      // Continue with cached data
    }
  }

  publishUpdate(channel, data) {
    // Publish to Redis Pub/Sub for WebSocket server
    redis.publish(`market:${channel}`, JSON.stringify({
      channel,
      payload: data,
      timestamp: new Date().toISOString(),
    }));
  }
}
```

### 2.2 Individual Scraper Example (LME)

```javascript
// scraper/scrapers/lme.js
const axios = require('axios');
const cheerio = require('cheerio');

async function scrapeLME() {
  try {
    // Use proper API or scrape from authorized source
    const response = await axios.get('https://lme-data-source.com/api/prices', {
      headers: {
        'User-Agent': 'MarketHub/1.0',
      },
      timeout: 5000,
    });

    const data = response.data;
    
    return data.map(item => ({
      symbol: item.symbol,
      name: item.name,
      exchange: 'LME',
      lastTradePrice: parseFloat(item.lastPrice),
      previousClose: parseFloat(item.previousClose),
      high: parseFloat(item.high),
      low: parseFloat(item.low),
      open: parseFloat(item.open),
      change: parseFloat(item.change),
      changePercent: parseFloat(item.changePercent),
      volume: parseInt(item.volume) || 0,
      lastTradeTime: new Date(item.timestamp).toISOString(),
      updatedAt: new Date().toISOString(),
    }));
  } catch (error) {
    console.error('LME scrape failed:', error.message);
    throw error;
  }
}

module.exports = { scrapeLME };
```

### 2.3 Redis Caching Strategy

```javascript
// redis/cache.js
const Redis = require('ioredis');

const redis = new Redis({
  host: process.env.REDIS_HOST,
  port: process.env.REDIS_PORT,
  password: process.env.REDIS_PASSWORD,
});

const CACHE_TTL = {
  market: 60,        // 1 minute
  spot: 300,         // 5 minutes
  reference: 3600,   // 1 hour
  news: 300,         // 5 minutes
  economic: 60,      // 1 minute
};

class CacheService {
  async getMarketData(exchange) {
    const cached = await redis.get(`market:${exchange}`);
    return cached ? JSON.parse(cached) : null;
  }

  async setMarketData(exchange, data) {
    await redis.set(
      `market:${exchange}`,
      JSON.stringify(data),
      'EX',
      CACHE_TTL.market
    );
  }

  async getSpotPrice(metalId) {
    const cached = await redis.get(`spot:${metalId}`);
    return cached ? JSON.parse(cached) : null;
  }

  // Fallback to stale data if scraper fails
  async getWithFallback(key, fetchFn, ttl) {
    const cached = await redis.get(key);
    
    if (cached) {
      return JSON.parse(cached);
    }

    try {
      const data = await fetchFn();
      await redis.set(key, JSON.stringify(data), 'EX', ttl);
      return data;
    } catch (error) {
      // Try to get stale data
      const stale = await redis.get(`${key}:stale`);
      if (stale) {
        return { ...JSON.parse(stale), isStale: true };
      }
      throw error;
    }
  }
}

module.exports = new CacheService();
```

---

## 3. WEBSOCKET SERVER

### 3.1 WebSocket Server Implementation

```javascript
// websocket/server.js
const WebSocket = require('ws');
const Redis = require('ioredis');
const jwt = require('jsonwebtoken');

class WebSocketServer {
  constructor(server) {
    this.wss = new WebSocket.Server({ server, path: '/ws/market' });
    this.redis = new Redis();
    this.subscriber = new Redis();
    this.clients = new Map(); // Map of userId -> Set of sockets
    this.subscriptions = new Map(); // Map of channel -> Set of sockets

    this.init();
  }

  init() {
    // Handle new connections
    this.wss.on('connection', (ws, req) => {
      this.handleConnection(ws, req);
    });

    // Subscribe to Redis channels for market updates
    this.subscriber.subscribe('market:lme', 'market:shfe', 'market:comex', 'market:fx', 'market:spot');
    
    this.subscriber.on('message', (channel, message) => {
      this.broadcastToChannel(channel, message);
    });

    // Heartbeat to keep connections alive
    setInterval(() => {
      this.wss.clients.forEach((ws) => {
        if (!ws.isAlive) {
          return ws.terminate();
        }
        ws.isAlive = false;
        ws.ping();
      });
    }, 30000);
  }

  async handleConnection(ws, req) {
    ws.isAlive = true;
    ws.subscriptions = new Set();

    // Authenticate connection
    const token = this.extractToken(req);
    if (token) {
      try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        ws.userId = decoded.userId;
      } catch (error) {
        ws.close(4001, 'Invalid token');
        return;
      }
    }

    ws.on('pong', () => {
      ws.isAlive = true;
    });

    ws.on('message', (message) => {
      this.handleMessage(ws, message);
    });

    ws.on('close', () => {
      this.handleDisconnect(ws);
    });

    // Send initial cached data
    await this.sendInitialData(ws);
  }

  handleMessage(ws, message) {
    try {
      const data = JSON.parse(message);

      switch (data.type) {
        case 'subscribe':
          this.subscribeToChannel(ws, data.channel);
          break;
        case 'unsubscribe':
          this.unsubscribeFromChannel(ws, data.channel);
          break;
        case 'ping':
          ws.send(JSON.stringify({ type: 'pong', timestamp: Date.now() }));
          break;
      }
    } catch (error) {
      console.error('WebSocket message error:', error);
    }
  }

  subscribeToChannel(ws, channel) {
    ws.subscriptions.add(channel);
    
    if (!this.subscriptions.has(channel)) {
      this.subscriptions.set(channel, new Set());
    }
    this.subscriptions.get(channel).add(ws);

    // Send current cached data immediately
    this.sendCachedData(ws, channel);
  }

  unsubscribeFromChannel(ws, channel) {
    ws.subscriptions.delete(channel);
    
    if (this.subscriptions.has(channel)) {
      this.subscriptions.get(channel).delete(ws);
    }
  }

  broadcastToChannel(channel, message) {
    const channelName = channel.replace('market:', '');
    const subscribers = this.subscriptions.get(channelName);
    
    if (subscribers) {
      subscribers.forEach((ws) => {
        if (ws.readyState === WebSocket.OPEN) {
          ws.send(message);
        }
      });
    }
  }

  async sendCachedData(ws, channel) {
    const cached = await this.redis.get(`market:${channel}`);
    if (cached) {
      ws.send(JSON.stringify({
        type: 'data',
        channel,
        payload: JSON.parse(cached),
        timestamp: Date.now(),
        cached: true,
      }));
    }
  }

  handleDisconnect(ws) {
    ws.subscriptions.forEach((channel) => {
      if (this.subscriptions.has(channel)) {
        this.subscriptions.get(channel).delete(ws);
      }
    });
  }

  extractToken(req) {
    const url = new URL(req.url, 'http://localhost');
    return url.searchParams.get('token');
  }
}

module.exports = WebSocketServer;
```

### 3.2 Client-Side WebSocket Service (Flutter)

```dart
// lib/core/network/websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:get/get.dart';

class WebSocketService extends GetxService {
  WebSocketChannel? _channel;
  final _dataController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStatus = Rx<ConnectionStatus>(ConnectionStatus.disconnected);
  
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  
  Stream<Map<String, dynamic>> get dataStream => _dataController.stream;
  Rx<ConnectionStatus> get connectionStatus => _connectionStatus;

  Future<void> connect(String token) async {
    if (_connectionStatus.value == ConnectionStatus.connected) return;
    
    _connectionStatus.value = ConnectionStatus.connecting;
    
    try {
      final uri = Uri.parse('wss://api.markethubindia.com/ws/market?token=$token');
      _channel = WebSocketChannel.connect(uri);
      
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
      
      _connectionStatus.value = ConnectionStatus.connected;
      _reconnectAttempts = 0;
      _startPingTimer();
      
    } catch (e) {
      _connectionStatus.value = ConnectionStatus.error;
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);
      
      if (data['type'] == 'pong') {
        // Heartbeat received
        return;
      }
      
      _dataController.add(data);
    } catch (e) {
      print('WebSocket message parse error: $e');
    }
  }

  void _onError(error) {
    print('WebSocket error: $error');
    _connectionStatus.value = ConnectionStatus.error;
    _scheduleReconnect();
  }

  void _onDone() {
    print('WebSocket closed');
    _connectionStatus.value = ConnectionStatus.disconnected;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('Max reconnect attempts reached');
      return;
    }
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(seconds: (2 << _reconnectAttempts).clamp(2, 30)),
      () {
        _reconnectAttempts++;
        connect(_getStoredToken());
      },
    );
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(Duration(seconds: 25), (_) {
      send({'type': 'ping'});
    });
  }

  void subscribe(String channel) {
    send({'type': 'subscribe', 'channel': channel});
  }

  void unsubscribe(String channel) {
    send({'type': 'unsubscribe', 'channel': channel});
  }

  void send(Map<String, dynamic> message) {
    if (_channel != null && _connectionStatus.value == ConnectionStatus.connected) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  String _getStoredToken() {
    // Get token from secure storage
    return '';
  }

  void disconnect() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _connectionStatus.value = ConnectionStatus.disconnected;
  }

  @override
  void onClose() {
    disconnect();
    _dataController.close();
    super.onClose();
  }
}

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}
```

---

## 4. DATABASE SCHEMAS (MongoDB)

### 4.1 User Schema

```javascript
// models/User.js
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

const userSchema = new mongoose.Schema({
  fullName: {
    type: String,
    required: true,
    trim: true,
    maxLength: 50,
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true,
  },
  whatsappNumber: {
    type: String,
    required: true,
  },
  whatsappCountryCode: {
    type: String,
    default: '+91',
  },
  phoneNumber: {
    type: String,
    required: true,
  },
  countryCode: {
    type: String,
    default: '+91',
  },
  pincode: {
    type: String,
    required: true,
    maxLength: 8,
  },
  visitingCardUrl: {
    type: String,
  },
  pin: {
    type: String,  // Encrypted
  },
  isEmailVerified: {
    type: Boolean,
    default: false,
  },
  isApproved: {
    type: Boolean,
    default: false,
  },
  isRejected: {
    type: Boolean,
    default: false,
  },
  rejectionMessage: {
    type: String,
  },
  approvedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin',
  },
  approvedAt: {
    type: Date,
  },
  plan: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Plan',
  },
  planStartDate: {
    type: Date,
  },
  planExpiryDate: {
    type: Date,
  },
  deviceToken: {
    type: String,
  },
  fcmToken: {
    type: String,
  },
  lastLoginAt: {
    type: Date,
  },
  status: {
    type: String,
    enum: ['pending', 'active', 'expired', 'rejected', 'suspended'],
    default: 'pending',
  },
}, {
  timestamps: true,
});

// Pre-save hook to hash PIN
userSchema.pre('save', async function(next) {
  if (this.isModified('pin') && this.pin) {
    this.pin = await bcrypt.hash(this.pin, 10);
  }
  next();
});

// Method to verify PIN
userSchema.methods.verifyPin = async function(enteredPin) {
  return await bcrypt.compare(enteredPin, this.pin);
};

module.exports = mongoose.model('User', userSchema);
```

### 4.2 Plan Schema

```javascript
// models/Plan.js
const mongoose = require('mongoose');

const planSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    unique: true,
  },
  description: {
    type: String,
  },
  features: [{
    type: String,
  }],
  price: {
    type: Number,
    required: true,
  },
  duration: {
    type: String,
    enum: ['monthly', 'quarterly', 'half-yearly', 'yearly'],
    required: true,
  },
  durationDays: {
    type: Number,
    required: true,
  },
  isPopular: {
    type: Boolean,
    default: false,
  },
  isActive: {
    type: Boolean,
    default: true,
  },
  sortOrder: {
    type: Number,
    default: 0,
  },
  // Content access levels
  accessLevels: {
    news: { type: Boolean, default: true },
    hindiNews: { type: Boolean, default: true },
    circulars: { type: Boolean, default: true },
    liveFeed: { type: Boolean, default: true },
    economicCalendar: { type: Boolean, default: true },
    spotPrice: { type: Boolean, default: true },
    futureData: { type: Boolean, default: true },
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model('Plan', planSchema);
```

### 4.3 Content Schemas

```javascript
// models/Update.js
const mongoose = require('mongoose');

const updateSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  imageUrl: {
    type: String,
  },
  pdfUrl: {
    type: String,
  },
  isActive: {
    type: Boolean,
    default: true,
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin',
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model('Update', updateSchema);

// models/News.js
const newsSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  summary: {
    type: String,
  },
  imageUrl: {
    type: String,
  },
  pdfUrl: {
    type: String,
  },
  sourceLink: {
    type: String,
  },
  newsType: {
    type: String,
    enum: ['english', 'hindi', 'live_feed'],
    required: true,
  },
  targetPlans: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Plan',
  }],
  isActive: {
    type: Boolean,
    default: true,
  },
  publishedAt: {
    type: Date,
    default: Date.now,
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin',
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model('News', newsSchema);

// models/Circular.js
const circularSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
  },
  imageUrl: {
    type: String,
  },
  pdfUrl: {
    type: String,
    required: true,
  },
  targetPlans: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Plan',
  }],
  isActive: {
    type: Boolean,
    default: true,
  },
  publishedAt: {
    type: Date,
    default: Date.now,
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin',
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model('Circular', circularSchema);
```

### 4.4 Watchlist Schema

```javascript
// models/Watchlist.js
const mongoose = require('mongoose');

const watchlistSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  itemType: {
    type: String,
    enum: ['future', 'spot'],
    required: true,
  },
  itemId: {
    type: String,
    required: true,
  },
  symbol: {
    type: String,
    required: true,
  },
  name: {
    type: String,
    required: true,
  },
  exchange: {
    type: String,  // For future items
  },
  metalId: {
    type: String,  // For spot items
  },
  location: {
    type: String,  // For spot items
  },
}, {
  timestamps: true,
});

// Compound index to prevent duplicates
watchlistSchema.index({ userId: 1, itemType: 1, itemId: 1 }, { unique: true });

module.exports = mongoose.model('Watchlist', watchlistSchema);
```

---

## 5. ADMIN PANEL API ROUTES

### 5.1 User Management

```javascript
// routes/admin/users.js
const router = require('express').Router();
const { adminAuth } = require('../../middleware/auth');

// Get pending users for verification
router.get('/pending', adminAuth, async (req, res) => {
  const users = await User.find({ 
    isApproved: false, 
    isRejected: false,
    isEmailVerified: true 
  })
  .populate('plan')
  .sort({ createdAt: -1 });
  
  res.json({ success: true, data: users });
});

// Approve user
router.post('/:id/approve', adminAuth, async (req, res) => {
  const user = await User.findById(req.params.id);
  if (!user) {
    return res.status(404).json({ success: false, message: 'User not found' });
  }
  
  user.isApproved = true;
  user.status = 'active';
  user.approvedBy = req.admin._id;
  user.approvedAt = new Date();
  
  // Set plan dates
  if (user.plan) {
    const plan = await Plan.findById(user.plan);
    user.planStartDate = new Date();
    user.planExpiryDate = new Date(Date.now() + plan.durationDays * 24 * 60 * 60 * 1000);
  }
  
  await user.save();
  
  // Send push notification
  if (user.fcmToken) {
    await sendPushNotification(user.fcmToken, {
      title: 'Account Approved',
      body: 'Your Market Hub account has been approved.',
      data: { type: 'approval', status: 'approved' },
    });
  }
  
  res.json({ success: true, message: 'User approved successfully' });
});

// Reject user
router.post('/:id/reject', adminAuth, async (req, res) => {
  const { reason } = req.body;
  
  const user = await User.findById(req.params.id);
  if (!user) {
    return res.status(404).json({ success: false, message: 'User not found' });
  }
  
  user.isRejected = true;
  user.status = 'rejected';
  user.rejectionMessage = reason;
  await user.save();
  
  // Send push notification
  if (user.fcmToken) {
    await sendPushNotification(user.fcmToken, {
      title: 'Account Not Approved',
      body: reason || 'Your account could not be verified. Please contact support.',
      data: { type: 'approval', status: 'rejected' },
    });
  }
  
  res.json({ success: true, message: 'User rejected' });
});

module.exports = router;
```

---

## 6. PUSH NOTIFICATIONS (Firebase)

```javascript
// services/notification.js
const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

async function sendPushNotification(token, { title, body, data }) {
  try {
    await admin.messaging().send({
      token,
      notification: {
        title,
        body,
      },
      data,
      android: {
        priority: 'high',
        notification: {
          channelId: 'market_hub_notifications',
        },
      },
      apns: {
        headers: {
          'apns-priority': '10',
        },
        payload: {
          aps: {
            alert: {
              title,
              body,
            },
            sound: 'default',
          },
        },
      },
    });
    return true;
  } catch (error) {
    console.error('Push notification error:', error);
    return false;
  }
}

module.exports = { sendPushNotification };
```

---

## 7. DEPLOYMENT ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────────┐
│                        PRODUCTION                                │
│                                                                  │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐  │
│  │ CloudFlare  │    │    Nginx    │    │  Docker Container   │  │
│  │    CDN      │───▶│   Reverse   │───▶│                     │  │
│  │             │    │    Proxy    │    │  ┌────────────────┐ │  │
│  └─────────────┘    └─────────────┘    │  │   API Server   │ │  │
│                                        │  │   (Node.js)    │ │  │
│                                        │  └────────────────┘ │  │
│                                        │                     │  │
│                                        │  ┌────────────────┐ │  │
│                                        │  │   WebSocket    │ │  │
│                                        │  │    Server      │ │  │
│                                        │  └────────────────┘ │  │
│                                        │                     │  │
│                                        │  ┌────────────────┐ │  │
│                                        │  │   Scraper      │ │  │
│                                        │  │   Service      │ │  │
│                                        │  └────────────────┘ │  │
│                                        └─────────────────────┘  │
│                                                                  │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐  │
│  │   Redis     │    │  MongoDB    │    │    AWS S3           │  │
│  │  (Managed)  │    │   Atlas     │    │  (File Storage)     │  │
│  └─────────────┘    └─────────────┘    └─────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

This document provides the complete backend architecture and implementation specifications for the Market Hub application.
