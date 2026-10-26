
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ServerController extends GetxController {
  RxList<dynamic> serverData = <dynamic>[].obs;
  RxList<dynamic> filteredServerData = <dynamic>[].obs; // New list for filtered data
  bool isLoading = false;

  Future<void> fetchServers() async {
    isLoading = true;
    try {

        // Fetch data from Firestore
        QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await FirebaseFirestore.instance.collection('servers').get();

        serverData.assignAll(querySnapshot.docs.map((doc) {
          var data = doc.data();
          data['id'] = doc.id;
          return data;
        }));

        filteredServerData.assignAll(serverData); // Initialize filtered list
        isLoading = false;
        update();

    } catch (error) {
      isLoading = false;
      print('Error fetching servers: $error');
    }
  }

  // New method for searching/filtering servers
  void searchServers(String query) {
    if (query.isEmpty) {
      // If the query is empty, show all servers
      filteredServerData.assignAll(serverData);
    } else {
      // Otherwise, filter the servers based on the query
      filteredServerData.assignAll(serverData
          .where((server) => server['serverName'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList());
      update();
    }
    update(); // Trigger UI update
  }

  @override
  void onInit() {
    // Fetch servers when the controller is initialized
    fetchServers();
    super.onInit();
  }
}
