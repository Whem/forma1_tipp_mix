import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions not configured for ${defaultTargetPlatform.name}',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDFKOEtUplFLIJszeHnGVpfKABQzJc-Krw',
    appId: '1:665311372347:android:dab89e4fc546286ab8e81e',
    messagingSenderId: '665311372347',
    projectId: 'forma1mix',
    storageBucket: 'forma1mix.firebasestorage.app',
  );
}
