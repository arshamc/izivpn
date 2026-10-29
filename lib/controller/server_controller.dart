import 'dart:convert';
import 'dart:io';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ads/ads_service.dart';
import '../utils/default_servers.dart';

class ServerController extends GetxController {
  RxList<dynamic> serverData = <dynamic>[].obs;
  RxList<dynamic> filteredServerData = <dynamic>[].obs;
  bool isLoading = false;

  // Ping tracking: server id -> ping in ms (-1 = timeout/error)
  RxMap<String, int> pingMap = <String, int>{}.obs;
  RxBool isPinging = false.obs;
  RxString lastSyncTime = ''.obs;
  RxString lastSyncSource = ''.obs;

  late final FlutterV2ray _v2ray = FlutterV2ray(onStatusChanged: (status) {});
  bool _isV2rayInitialized = false;

  // Censorship-resistant server list endpoints
  final List<String> _serverEndpoints = [
    // 0. Live Admin Dashboard Tunnel (Active from developer's machine)
    'https://vast-peas-beam.loca.lt/api/v1/servers',
    // 1. Localhost aliases (Android emulator, LAN, USB cable via adb reverse)
    'http://10.0.2.2:3000/api/v1/servers',
    'http://localhost:3000/api/v1/servers',
    // 2. Primary CDN mirror: jsDelivr (very fast & widely accessible in Iran)
    'https://cdn.jsdelivr.net/gh/arshamc/izivpn@main/servers.json',
    // 3. Fastly CDN mirror
    'https://fastly.jsdelivr.net/gh/arshamc/izivpn@main/servers.json',
    // 4. GCore CDN mirror
    'https://gcore.jsdelivr.net/gh/arshamc/izivpn@main/servers.json',
    // 5. Raw GitHub mirror
    'https://raw.githubusercontent.com/arshamc/izivpn/main/servers.json',
  ];

  // Remote config endpoints (AdMob, maintenance, announcements)
  final List<String> _configEndpoints = [
    'https://vast-peas-beam.loca.lt/api/v1/config',
    'http://10.0.2.2:3000/api/v1/config',
    'http://localhost:3000/api/v1/config',
    'https://cdn.jsdelivr.net/gh/arshamc/izivpn@main/app_config.json',
    'https://fastly.jsdelivr.net/gh/arshamc/izivpn@main/app_config.json',
    'https://raw.githubusercontent.com/arshamc/izivpn/main/app_config.json',
  ];

  // Config URL sanitizer (fixes percent-encoded base64 padding in Shadowsocks and whitespace)
  static String sanitizeConfig(String url) {
    var trimmed = url.trim();
    if (trimmed.startsWith('ss://')) {
      final atIndex = trimmed.lastIndexOf('@');
      if (atIndex > 5) {
        final userInfoPart = trimmed.substring(5, atIndex);
        final rest = trimmed.substring(atIndex);
        final cleanedUserInfo = Uri.decodeComponent(userInfoPart).replaceAll('%3D', '=');
        return 'ss://$cleanedUserInfo$rest';
      }
    }
    return trimmed;
  }

  Future<void> _ensureInit() async {
    if (!_isV2rayInitialized) {
      try {
        await _v2ray.initializeV2Ray();
        _isV2rayInitialized = true;
      } catch (e) {
        print('Error initializing v2ray for ping: $e');
      }
    }
  }

  // Load from local cache first, or fallback to default servers immediately
  Future<void> loadCachedOrFallbackServers() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cachedJson = prefs.getString('cached_servers');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        List<dynamic> list = jsonDecode(cachedJson);
        if (list.isNotEmpty) {
          serverData.assignAll(list);
          filteredServerData.assignAll(serverData);
          update();
          return;
        }
      }
    } catch (e) {
      print('Error reading cached servers: $e');
    }

    // Fallback: bundled default servers (works even with 100% blocked internet)
    serverData.assignAll(defaultServers);
    filteredServerData.assignAll(serverData);
    update();
  }

  // HTTP GET fetcher with timeout and TLS resilience
  Future<String?> _fetchFromHttp(String url, {Duration timeout = const Duration(seconds: 4)}) async {
    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = timeout;
      client.badCertificateCallback = (cert, host, port) => true;

      HttpClientRequest request = await client.getUrl(Uri.parse(url)).timeout(timeout);
      request.headers.set('User-Agent', 'Mozilla/5.0 (Linux; Android 14; iziVPN)');
      request.headers.set('Accept', 'application/json, text/plain, */*');
      request.headers.set('Bypass-Tunnel-Reminder', 'true');

      HttpClientResponse response = await request.close().timeout(timeout);
      if (response.statusCode == 200) {
        String body = await response.transform(utf8.decoder).join().timeout(timeout);
        return body;
      }
    } catch (e) {
      print('Fetch error from $url: $e');
    } finally {
      client?.close(force: true);
    }
    return null;
  }

  // Fetch Remote Config (AdMob policies & App settings)
  Future<void> fetchRemoteConfig() async {
    for (String endpoint in _configEndpoints) {
      String? body = await _fetchFromHttp(endpoint);
      if (body != null && body.isNotEmpty) {
        try {
          dynamic parsed = jsonDecode(body.trim());
          if (parsed is Map) {
            final admobMap = parsed['admob'];
            if (admobMap is Map) {
              AdConfig.updateFromMap(Map<String, dynamic>.from(admobMap));
            }
            break;
          }
        } catch (e) {
          print('Error applying remote config: $e');
        }
      }
    }
  }

  // Parse server JSON or Base64-encoded JSON (to bypass DPI keyword filters)
  List<dynamic>? _parseServerResponse(String rawBody) {
    try {
      String trimmed = rawBody.trim();
      if (!trimmed.startsWith('[') && !trimmed.startsWith('{')) {
        try {
          trimmed = utf8.decode(base64.decode(trimmed));
        } catch (_) {}
      }
      dynamic parsed = jsonDecode(trimmed);
      if (parsed is Map && parsed['data'] is List) {
        final list = (parsed['data'] as List).map((s) {
          if (s is Map) {
            if (s['flag'] == null && s['countryCode'] != null) {
              s['flag'] = s['countryCode'];
            }
          }
          return s;
        }).toList();
        if (list.isNotEmpty) return list;
      }
      if (parsed is List && parsed.isNotEmpty) {
        return parsed;
      }
    } catch (e) {
      print('Error parsing server list: $e');
    }
    return null;
  }

  Future<void> fetchServers({bool showToastOnResult = false}) async {
    isLoading = true;
    update();

    List<dynamic>? freshList;
    String sourceUsed = "";

    // Step 1: Try CDN and HTTP mirrors sequentially
    for (String endpoint in _serverEndpoints) {
      String? body = await _fetchFromHttp(endpoint);
      if (body != null && body.isNotEmpty) {
        freshList = _parseServerResponse(body);
        if (freshList != null && freshList.isNotEmpty) {
          sourceUsed = "CDN/Cloud";
          break;
        }
      }
    }

    // Step 2: If CDN mirrors failed, try Firebase Firestore as fallback
    if (freshList == null || freshList.isEmpty) {
      try {
        QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
            .instance
            .collection('servers')
            .get()
            .timeout(const Duration(seconds: 4));

        if (querySnapshot.docs.isNotEmpty) {
          freshList = querySnapshot.docs.map((doc) {
            var data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
          sourceUsed = "Firebase";
        }
      } catch (e) {
        print('Firestore fallback also unavailable: $e');
      }
    }

    // Step 3: If fresh data was acquired from any source, apply & cache it
    if (freshList != null && freshList.isNotEmpty) {
      serverData.assignAll(freshList);
      filteredServerData.assignAll(serverData);
      final now = DateTime.now();
      lastSyncTime.value = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      lastSyncSource.value = sourceUsed;

      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_servers', jsonEncode(freshList));
      } catch (e) {
        print('Error saving cached servers: $e');
      }

      if (showToastOnResult) {
        Fluttertoast.showToast(msg: "Updated ${freshList.length} servers (Synced at ${lastSyncTime.value})");
      }
    } else {
      if (serverData.isEmpty) {
        await loadCachedOrFallbackServers();
      }
      final now = DateTime.now();
      if (lastSyncTime.value.isEmpty) {
        lastSyncTime.value = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
        lastSyncSource.value = "Local DB";
      }
      if (showToastOnResult) {
        Fluttertoast.showToast(msg: "Loaded ${serverData.length} servers (${lastSyncSource.value})");
      }
    }

    isLoading = false;
    update();
  }

  // Ping a single server using official Google connectivity check URL (with strict 2.5s hard timeout)
  Future<int> pingServer(String id, String configUrl) async {
    try {
      await _ensureInit();
      final cleanUrl = sanitizeConfig(configUrl);
      V2RayURL parser = FlutterV2ray.parseFromURL(cleanUrl);
      final fullConfig = parser.getFullConfiguration();
      if (fullConfig.isEmpty) {
        pingMap[id] = -1;
        update();
        return -1;
      }
      int delay = await _v2ray.getServerDelay(
        config: fullConfig,
        url: 'http://www.gstatic.com/generate_204',
      ).timeout(
        const Duration(milliseconds: 2500),
        onTimeout: () => -1,
      );
      pingMap[id] = delay;
      update(); // Real-time UI update per server
      return delay;
    } catch (_) {
      pingMap[id] = -1;
      update();
      return -1;
    }
  }

  // Ping all servers with high-speed parallel execution (like v2rayNG Real Delay test)
  Future<void> pingAllServers() async {
    if (isPinging.value) return;
    isPinging.value = true;
    update();

    try {
      final validServers = serverData.where((s) {
        final id = (s['id'] ?? s['serverName'] ?? '').toString();
        final config = (s['config'] ?? '').toString();
        return id.isNotEmpty && config.isNotEmpty;
      }).toList();

      // Fire all server real-delay pings concurrently with bounded 2.5s timeout each
      await Future.wait(validServers.map((server) {
        final id = (server['id'] ?? server['serverName'] ?? '').toString();
        final config = (server['config'] ?? '').toString();
        return pingServer(id, config);
      }));
    } finally {
      isPinging.value = false;
      update();
    }
  }

  // Get the server with lowest positive delay
  Map<String, dynamic>? getBestServer() {
    Map<String, dynamic>? best;
    int lowestDelay = 999999;

    for (var server in serverData) {
      String id = (server['id'] ?? server['serverName'] ?? '').toString();
      int? delay = pingMap[id];
      if (delay != null && delay > 0 && delay < lowestDelay) {
        lowestDelay = delay;
        best = Map<String, dynamic>.from(server);
      }
    }
    return best;
  }

  void searchServers(String query) {
    if (query.isEmpty) {
      filteredServerData.assignAll(serverData);
    } else {
      filteredServerData.assignAll(serverData
          .where((server) => server['serverName']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList());
    }
    update();
  }

  @override
  void onInit() {
    loadCachedOrFallbackServers();
    fetchServers();
    fetchRemoteConfig();
    super.onInit();
  }
}
