// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.macOS:
        return macos;
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
    apiKey: 'AIzaSyCLU0zWm3Vx3ClJsbub2lEn0imzclElYNY',
    appId: '1:1040552503123:web:5be81367475c641033a3a6',
    messagingSenderId: '1040552503123',
    projectId: 'brilnix-9b1d5',
    authDomain: 'brilnix-9b1d5.firebaseapp.com',
    databaseURL: 'https://brilnix-9b1d5-default-rtdb.firebaseio.com',
    storageBucket: 'brilnix-9b1d5.appspot.com',
    measurementId: 'G-JW79VHSLWZ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDMeQL8gcKzANelJ-pjj_vGqtO18Uetf1E',
    appId: '1:1040552503123:android:00e68132d8c8036733a3a6',
    messagingSenderId: '1040552503123',
    projectId: 'brilnix-9b1d5',
    databaseURL: 'https://brilnix-9b1d5-default-rtdb.firebaseio.com',
    storageBucket: 'brilnix-9b1d5.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDi0rklPz6cz-GxMcFyuqhpen51iAZyWXE',
    appId: '1:1040552503123:ios:190a0f0fcf30257533a3a6',
    messagingSenderId: '1040552503123',
    projectId: 'brilnix-9b1d5',
    databaseURL: 'https://brilnix-9b1d5-default-rtdb.firebaseio.com',
    storageBucket: 'brilnix-9b1d5.appspot.com',
    iosClientId: '1040552503123-mmss26kmrunuhconi5raok2fr5b9731t.apps.googleusercontent.com',
    iosBundleId: 'com.example.brilnix',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDi0rklPz6cz-GxMcFyuqhpen51iAZyWXE',
    appId: '1:1040552503123:ios:190a0f0fcf30257533a3a6',
    messagingSenderId: '1040552503123',
    projectId: 'brilnix-9b1d5',
    databaseURL: 'https://brilnix-9b1d5-default-rtdb.firebaseio.com',
    storageBucket: 'brilnix-9b1d5.appspot.com',
    iosClientId: '1040552503123-mmss26kmrunuhconi5raok2fr5b9731t.apps.googleusercontent.com',
    iosBundleId: 'com.example.brilnix',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCLU0zWm3Vx3ClJsbub2lEn0imzclElYNY',
    appId: '1:1040552503123:web:5e1c73d3747d709d33a3a6',
    messagingSenderId: '1040552503123',
    projectId: 'brilnix-9b1d5',
    authDomain: 'brilnix-9b1d5.firebaseapp.com',
    databaseURL: 'https://brilnix-9b1d5-default-rtdb.firebaseio.com',
    storageBucket: 'brilnix-9b1d5.appspot.com',
    measurementId: 'G-EHLS1JT83S',
  );
}
