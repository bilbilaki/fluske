import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'common/global.dart';
import 'my_app.dart';
import '/services/repository/database_creator.dart';
import 'package:flutter_translate/flutter_translate.dart';

import 'services/di/locator.dart';
import 'services/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  setUpLocator();
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
    // set observer
    FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance);
  } catch (e) {
    print("Failed to initialize Firebase: $e");
  }
  FlutterDownloader.initialize();
  await DatabaseCreator().initDatabase();

  var delegate = await LocalizationDelegate.create(
      fallbackLocale: 'en',
      supportedLocales: ['en', 'ar', 'es', 'hi', 'fa', "tr"]);

  HttpOverrides.global = new MyHttpOverrides();

  authToken = await storage.read(key: "token");
  await getKidsModeState();
  runApp(LocalizedApp(delegate, MyApp(token: authToken)));
}

// Solutions For : HandshakeException: Handshake error in client (CERTIFICATE_VERIFY_FAILED: certificate has expired)
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        return host == "linux.server-three.ir" ? true : false;
      };
  }
}
