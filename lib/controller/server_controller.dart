import 'dart:convert';
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

  // Fetch servers from Firestore with timeout protection (never crashes)
  Future<void> fetchServers({bool showToastOnResult = false}) async {
    isLoading = true;
    update();

    try {
      // 6-second timeout so it never hangs if Firestore is filtered/blocked
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
          .instance
          .collection('servers')
          .get()
          .timeout(const Duration(seconds: 6));

      if (querySnapshot.docs.isNotEmpty) {
        List<dynamic> freshList = querySnapshot.docs.map((doc) {
          var data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        serverData.assignAll(freshList);
        filteredServerData.assignAll(serverData);

        // Cache locally for offline/filtered resilience
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_servers', jsonEncode(freshList));

        if (showToastOnResult) {
          Fluttertoast.showToast(msg: "Server list updated (${freshList.length} servers)");
        }
      }
    } catch (error) {
      print('Firestore fetch error (likely filtered or network timeout): $error');
      if (showToastOnResult) {
        Fluttertoast.showToast(msg: "Could not reach server, using offline list");
      }
    } finally {
      // Ensure we always have servers populated
      if (serverData.isEmpty) {
        serverData.assignAll(defaultServers);
        filteredServerData.assignAll(serverData);
      }
      isLoading = false;
      update();
    }
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
    // 2. In background, try to fetch fresh list from Firestore (6s timeout)
    fetchServers();
    super.onInit();
  }
}
