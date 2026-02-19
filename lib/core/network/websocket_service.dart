import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../storage/local_storage.dart';

class WebSocketService extends GetxService {
  WebSocketChannel? _channel;

  final _dataController = StreamController<MarketUpdate>.broadcast();
  final connectionStatus = Rx<ConnectionStatus>(ConnectionStatus.disconnected);

  Timer? _reconnectTimer;
  Timer? _pingTimer;
  Timer? _pongTimer;
  int _reconnectAttempts = 0;

  final Map<String, dynamic> _lastKnownData = {};
  final Set<String> _subscribedChannels = {};

  String? _authToken;
  StreamSubscription? _connectivitySubscription;

  Stream<MarketUpdate> get dataStream => _dataController.stream;
  Map<String, dynamic> get cachedData => Map.unmodifiable(_lastKnownData);

  @override
  void onInit() {
    super.onInit();
    _setupConnectivityListener();
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.isNotEmpty &&
          results.any((r) => r != ConnectivityResult.none);
      if (hasConnection && connectionStatus.value == ConnectionStatus.disconnected) {
        connect(_authToken ?? '');
      }
    });
  }

  Future<void> connect(String token) async {
    if (connectionStatus.value == ConnectionStatus.connected ||
        connectionStatus.value == ConnectionStatus.connecting) {
      return;
    }

    _authToken = token;
    connectionStatus.value = ConnectionStatus.connecting;

    try {
      final uri = Uri.parse('${ApiConstants.wsUrl}/market?token=$token');
      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready;

      connectionStatus.value = ConnectionStatus.connected;
      _reconnectAttempts = 0;

      _startPingPong();
      _resubscribeChannels();

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      debugPrint('WebSocket connected');
    } catch (e) {
      debugPrint('WebSocket connection failed: $e');
      connectionStatus.value = ConnectionStatus.error;
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;

      switch (data['type']) {
        case 'pong':
          _pongTimer?.cancel();
          break;

        case 'data':
          _handleDataMessage(data);
          break;

        case 'error':
          debugPrint('Server error: ${data['message']}');
          break;

        case 'subscribed':
          debugPrint('Subscribed to: ${data['channel']}');
          break;
      }
    } catch (e) {
      debugPrint('Message parse error: $e');
    }
  }

  void _handleDataMessage(Map<String, dynamic> data) {
    final channel = data['channel'] as String;
    final payload = data['payload'];
    final timestamp = DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now();

    _lastKnownData[channel] = payload;

    // Also cache locally for offline access
    LocalStorage.cacheMarketData(channel, {
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
    });

    _dataController.add(MarketUpdate(
      channel: channel,
      payload: payload,
      timestamp: timestamp,
      isStale: false,
    ));
  }

  void _onError(error) {
    debugPrint('WebSocket error: $error');
    connectionStatus.value = ConnectionStatus.error;
  }

  void _onDone() {
    debugPrint('WebSocket closed');
    _cleanup();
    connectionStatus.value = ConnectionStatus.disconnected;
    _scheduleReconnect();
  }

  void _startPingPong() {
    _pingTimer?.cancel();
    _pongTimer?.cancel();

    _pingTimer = Timer.periodic(
      const Duration(seconds: AppConstants.websocketPingInterval),
      (_) {
        if (_channel != null && connectionStatus.value == ConnectionStatus.connected) {
          send({'type': 'ping', 'timestamp': DateTime.now().toIso8601String()});

          _pongTimer = Timer(
            const Duration(seconds: AppConstants.websocketPongTimeout),
            () {
              debugPrint('Pong timeout - reconnecting');
              _forceReconnect();
            },
          );
        }
      },
    );
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= AppConstants.maxReconnectAttempts) {
      debugPrint('Max reconnect attempts reached');
      connectionStatus.value = ConnectionStatus.failed;
      return;
    }

    _reconnectTimer?.cancel();

    final delay = Duration(
      seconds: (1 << _reconnectAttempts).clamp(
        AppConstants.initialReconnectDelay,
        AppConstants.maxReconnectDelay,
      ),
    );

    debugPrint('Reconnecting in ${delay.inSeconds}s (attempt ${_reconnectAttempts + 1})');

    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      connect(_authToken ?? '');
    });
  }

  void _forceReconnect() {
    _cleanup();
    connectionStatus.value = ConnectionStatus.disconnected;
    _reconnectAttempts = 0;
    connect(_authToken ?? '');
  }

  void _resubscribeChannels() {
    for (final channel in _subscribedChannels) {
      send({'type': 'subscribe', 'channel': channel});
    }
  }

  void subscribe(String channel) {
    _subscribedChannels.add(channel);
    if (connectionStatus.value == ConnectionStatus.connected) {
      send({'type': 'subscribe', 'channel': channel});
    }

    // Immediately emit cached data if available
    if (_lastKnownData.containsKey(channel)) {
      _dataController.add(MarketUpdate(
        channel: channel,
        payload: _lastKnownData[channel],
        timestamp: DateTime.now(),
        isStale: true,
      ));
    } else {
      // Try to load from local storage
      final cachedData = LocalStorage.getCachedMarketData(channel);
      if (cachedData != null) {
        _lastKnownData[channel] = cachedData['payload'];
        _dataController.add(MarketUpdate(
          channel: channel,
          payload: cachedData['payload'],
          timestamp: DateTime.tryParse(cachedData['timestamp'] ?? '') ?? DateTime.now(),
          isStale: true,
        ));
      }
    }
  }

  void unsubscribe(String channel) {
    _subscribedChannels.remove(channel);
    if (connectionStatus.value == ConnectionStatus.connected) {
      send({'type': 'unsubscribe', 'channel': channel});
    }
  }

  void send(Map<String, dynamic> message) {
    if (_channel != null && connectionStatus.value == ConnectionStatus.connected) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  dynamic getCachedData(String channel) => _lastKnownData[channel];

  void _cleanup() {
    _pingTimer?.cancel();
    _pongTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _cleanup();
    _subscribedChannels.clear();
    connectionStatus.value = ConnectionStatus.disconnected;
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
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
  failed,
}

class MarketUpdate {
  final String channel;
  final dynamic payload;
  final DateTime timestamp;
  final bool isStale;

  MarketUpdate({
    required this.channel,
    required this.payload,
    required this.timestamp,
    required this.isStale,
  });
}
