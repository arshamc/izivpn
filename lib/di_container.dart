import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import 'controller/notification_controller.dart';
import 'controller/server_controller.dart';

final sl = GetIt.instance;

Future<void> init() async {

  /// Controller
  Get.lazyPut(() => NotificationController(), fenix: true);
  Get.lazyPut(() => ServerController(), fenix: true);

}
