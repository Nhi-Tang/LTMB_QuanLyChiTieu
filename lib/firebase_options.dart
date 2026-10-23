
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
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBVpj4mPBWy0Af2Cgagycrpj-heb0CKQ8k',
    appId: '1:252576636037:web:39c8f17263a8bb6e099dec',
    messagingSenderId: '252576636037',
    projectId: 'quan-ly-chi-65a86',
    authDomain: 'quan-ly-chi-65a86.firebaseapp.com',
    storageBucket: 'quan-ly-chi-65a86.firebasestorage.app',
    measurementId: 'G-L1721MJ9H2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA7bH2kGhjdcgHLmENUrjL8dEQaVk2OwWs',
    appId: '1:252576636037:android:a006dc7296fd084a099dec',
    messagingSenderId: '252576636037',
    projectId: 'quan-ly-chi-65a86',
    storageBucket: 'quan-ly-chi-65a86.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBVpj4mPBWy0Af2Cgagycrpj-heb0CKQ8k',
    appId: '1:252576636037:web:22a609b51b4550e3099dec',
    messagingSenderId: '252576636037',
    projectId: 'quan-ly-chi-65a86',
    authDomain: 'quan-ly-chi-65a86.firebaseapp.com',
    storageBucket: 'quan-ly-chi-65a86.firebasestorage.app',
    measurementId: 'G-SV6XDMTYT2',
  );
}
