import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCO9ODZDF10jPoEEBdkuBerulX54CumMFc',
    appId: '1:106015853692:web:fb69444c1d1eba8dda0df9',
    messagingSenderId: '106015853692',
    projectId: 'com-almhdy24-nabd',
    authDomain: 'com-almhdy24-nabd.firebaseapp.com',
    storageBucket: 'com-almhdy24-nabd.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCO9ODZDF10jPoEEBdkuBerulX54CumMFc',
    appId: '1:106015853692:android:fb69444c1d1eba8dda0df9',
    messagingSenderId: '106015853692',
    projectId: 'com-almhdy24-nabd',
    storageBucket: 'com-almhdy24-nabd.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCO9ODZDF10jPoEEBdkuBerulX54CumMFc',
    appId: '1:106015853692:ios:fb69444c1d1eba8dda0df9',
    messagingSenderId: '106015853692',
    projectId: 'com-almhdy24-nabd',
    storageBucket: 'com-almhdy24-nabd.firebasestorage.app',
    iosBundleId: 'com.almhdy24.nabd',
  );
}
