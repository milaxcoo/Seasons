import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:seasons/core/services/rudn_auth_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WebsocketService {
  static final WebsocketService _instance = WebsocketService._internal();
  factory WebsocketService() => _instance;
  WebsocketService._internal();

  WebSocketChannel? _channel;
  final _eventController = BehaviorSubject<dynamic>(); // Broadcast stream
  Stream<dynamic> get events => _eventController.stream;

  bool _isConnected = false;
  Timer? _reconnectTimer;
  
  static const String _wsUrl = 'https://seasons.rudn.ru/api/v1/voters/ws_connect';

  /// Connects to the WebSocket server using the current auth cookie.
  Future<void> connect() async {
    // If we are already connected or connecting, skip (unless forcing disconnect?)
    // For simplicity, if we have a channel, we assume connected or dealing with it.
    if (_isConnected) return;

    try {
      final cookie = await RudnAuthService().getCookie();
      if (cookie == null || cookie.isEmpty) {
        if (kDebugMode) print("WS: No auth cookie, skipping connection");
        return;
      }

      final headers = {
        'Cookie': 'session=$cookie',
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
      };

      if (kDebugMode) print("WS: Negotiating connection at $_wsUrl...");

      // Step 1: Get the actual WebSocket URL
      final response = await http.get(
        Uri.parse(_wsUrl), // Ensure _wsUrl is the REST endpoint
        headers: headers,
      );

      if (response.statusCode != 200) {
        if (kDebugMode) print("WS Headers: $headers");
        throw Exception("Failed to negotiate WS URL: ${response.statusCode} ${response.body}");
      }

      final data = jsonDecode(response.body);
      final realWsUrl = data['url'] as String;
      
      if (kDebugMode) print("WS: Connecting to dynamic URL: $realWsUrl");

      // Step 2: Connect to the dynamic URL
      _channel = IOWebSocketChannel.connect(
        Uri.parse(realWsUrl),
        headers: {
          ...headers,
          'Origin': 'https://seasons.rudn.ru',
        },
      );

      _isConnected = true;
      _reconnectTimer?.cancel();

      _channel!.stream.listen(
        (message) {
          if (kDebugMode) print("WS Received: $message");
          _eventController.add(message);
        },
        onDone: () {
          if (kDebugMode) print("WS: Connection closed by server");
          _handleDisconnect();
        },
        onError: (error) {
          if (kDebugMode) print("WS: Connection error: $error");
          _handleDisconnect();
        },
      );
    } catch (e) {
      if (kDebugMode) print("WS: Connection failed: $e");
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _channel = null;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive ?? false) return;
    
    if (kDebugMode) print("WS: Scheduling reconnect in 5s...");
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      connect();
    });
  }

  /// Disconnect manually (e.g. on logout)
  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }
}
