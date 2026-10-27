import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> fetchServers() async {
    isLoading = true;
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance.collection('servers').get();

      serverData.assignAll(querySnapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        return data;
      }));

      filteredServerData.assignAll(serverData);
      isLoading = false;
      update();
    } catch (error) {
      isLoading = false;
      print('Error fetching servers: $error');
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

  // Get the server with the lowest positive delay
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
    fetchServers();
    super.onInit();
  }
}
