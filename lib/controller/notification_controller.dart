import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationController extends GetxController {
  RxList<Map<String, dynamic>> notifications = <Map<String, dynamic>>[].obs;
  bool isLoading = false;

  Future<void> fetchNotifications() async {
    isLoading = true;
    try {
        // Fetch data from Firestore
        QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await FirebaseFirestore.instance.collection('notifications').get();

        notifications.assignAll(querySnapshot.docs.map((doc) {
          var data = doc.data();
          data['id'] = doc.id; // Add unique ID to each notification
          return data;
        }));
        isLoading = false;
        update();
    } catch (error) {
      isLoading = false;
      print('Error fetching notifications: $error');
    }
  }

  @override
  void onInit() {
    // Fetch notifications when the controller is initialized
    fetchNotifications();
    super.onInit();
  }
}
