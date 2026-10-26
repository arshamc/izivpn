import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.'
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.'
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.'
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.'
        );
    }
  }
  static const FirebaseOptions web = FirebaseOptions(
      apiKey: "AIzaSyBK-DBAsfERD0P70LCSwHt5zwD-TRMyzhg",
      authDomain: "german-vpn-8bf1d.firebaseapp.com",
      projectId: "german-vpn-8bf1d",
      storageBucket: "german-vpn-8bf1d.firebasestorage.app",
      messagingSenderId: "607597774886",
      appId: "1:607597774886:android:300454c48f65ee8b65bee7",
  );
  static const FirebaseOptions android = FirebaseOptions(
      apiKey: "AIzaSyBK-DBAsfERD0P70LCSwHt5zwD-TRMyzhg",
      authDomain: "german-vpn-8bf1d.firebaseapp.com",
      projectId: "german-vpn-8bf1d",
      storageBucket: "german-vpn-8bf1d.firebasestorage.app",
      messagingSenderId: "607597774886",
      appId: "1:607597774886:android:300454c48f65ee8b65bee7",
  );

}
