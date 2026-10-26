import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gamers_shield_vpn/screen/drawer/animated_drawer.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'di_container.dart' as di;
import 'firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
        designSize: const Size(360, 810),
        minTextAdapt: true,
        splitScreenMode: true,
      builder: (context,child) {
        return GetMaterialApp(
            title: 'izi vpn',
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              inputDecorationTheme: const InputDecorationTheme(
                border: OutlineInputBorder(),
              ),
            ),
            debugShowCheckedModeBanner: false,
            home: AnimatedSplashScreen(
              splash: 'assets/images/app_logo.png',
              splashIconSize: 200,
              backgroundColor: Color(0xffF57D1F),
              nextScreen: AnimatedDrawerScreen(),
              splashTransition: SplashTransition.rotationTransition,
            )
        );
      }
    );
  }
}

