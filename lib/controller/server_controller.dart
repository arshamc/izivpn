import 'dart:convert';
import 'dart:io';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/default_servers.dart';

class ServerController extends GetxController {
  RxList<dynamic> serverData = <dynamic>[].obs;
  RxList<dynamic> filteredServerData = <dynamic>[].obs;
  bool isLoading = false;

  // Ping tracking: server id -> ping in ms (-1 = timeout/error)
  RxMap<String, int> pingMap = <String, int>{}.obs;
  RxBool isPinging = false.obs;

  late final FlutterV2ray _v2ray = FlutterV2ray(onStatusChanged: (status) {});
  bool _isV2rayInitialized = false;

  // Censorship-resistant endpoints (tried sequentially)
  final List<String> _serverEndpoints = [
    // 1. Primary CDN mirror: jsDelivr (very fast & widely accessible in Iran)
    'https://cdn.jsdelivr.net/gh/arshamc/izivpn@main/servers.json',
    // 2. Fastly CDN mirror
    'https://fastly.jsdelivr.net/gh/arshamc/izivpn@main/servers.json',
    // 3. GCore CDN mirror
    'https://gcore.jsdelivr.net/gh/arshamc/izivpn@main/servers.json',
    // 4. Raw GitHub mirror
    'https://raw.githubusercontent.com/arshamc/izivpn/main/servers.json',
  ];

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
      // Allow connection even on filtered/re-routed networks with self-signed proxies
      client.badCertificateCallback = (cert, host, port) => true;

      HttpClientRequest request = await client.getUrl(Uri.parse(url)).timeout(timeout);
      request.headers.set('User-Agent', 'Mozilla/5.0 (Linux; Android 14; iziVPN)');
      request.headers.set('Accept', 'application/json, text/plain, */*');

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

  // Parse server JSON or Base64-encoded JSON (to bypass DPI keyword filters)
  List<dynamic>? _parseServerResponse(String rawBody) {
    try {
      String trimmed = rawBody.trim();
      // If response is Base64 encoded, decode it first
      if (!trimmed.startsWith('[') && !trimmed.startsWith('{')) {
        try {
          trimmed = utf8.decode(base64.decode(trimmed));
        } catch (_) {}
      }
      dynamic parsed = jsonDecode(trimmed);
      if (parsed is List && parsed.isNotEmpty) {
        return parsed;
      }
    } catch (e) {
      print('Error parsing server list: $e');
    }
    return null;
  }

  // Multi-Source Fetch with Automatic Fallback:
  // 1. CDN mirrors (jsDelivr / Fastly / GCore)
  // 2. GitHub Raw
  // 3. Firebase Firestore (if unblocked)
  // 4. Local SharedPreferences Cache
  // 5. Bundled default servers
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

      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_servers', jsonEncode(freshList));
      } catch (e) {
        print('Error saving cached servers: $e');
      }

      if (showToastOnResult) {
        Fluttertoast.showToast(msg: "Updated ${freshList.length} servers ($sourceUsed)");
      }
    } else {
      // Step 4: Ensure fallback is populated if serverData is somehow empty
      if (serverData.isEmpty) {
        await loadCachedOrFallbackServers();
      }
      if (showToastOnResult) {
        Fluttertoast.showToast(msg: "Offline mode: loaded ${serverData.length} servers");
      }
    }

    isLoading = false;
    update();
  }

  // Ping a single server
  Future<int> pingServer(String id, String configUrl) async {
    try {
      await _ensureInit();
      V2RayURL parser = FlutterV2ray.parseFromURL(configUrl);
      int delay = await _v2ray.getServerDelay(
        config: parser.getFullConfiguration(),
        url: 'https://cp.cloudflare.com/generate_204',
      );
      pingMap[id] = delay;
      update();
      return delay;
    } catch (e) {
      print('Ping error for $id: $e');
      pingMap[id] = -1;
      update();
      return -1;
    }
  }

  // Ping all servers sequentially
  Future<void> pingAllServers() async {
    if (isPinging.value) return;
    isPinging.value = true;
    update();

    try {
      for (var server in serverData) {
        String id = server['id'] ?? server['serverName'] ?? '';
        String config = server['config'] ?? '';
        if (config.isNotEmpty && id.isNotEmpty) {
          await pingServer(id, config);
        }
      }
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
      String id = server['id'] ?? server['serverName'] ?? '';
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
    // 1. Immediately load cache or default servers without blocking UI
    loadCachedOrFallbackServers();
    // 2. In background, attempt multi-source fetch
    fetchServers();
    super.onInit();
  }
}
