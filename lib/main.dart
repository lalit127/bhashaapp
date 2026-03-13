import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'core/services/storage_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/api_service.dart';
import 'features/subscription/revenuecat_service.dart';
import 'shared/models/progress_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Hive local DB
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(UserProgressAdapter());
  }
  await Hive.openBox<UserProgress>('progress');
  await Hive.openBox('settings');

  // Firebase - Commented out to prevent crash if not configured
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Register core services
  Get.put(StorageService());
  Get.put(LiveApiService());
  // Get.put(AnalyticsService()); // Also depends on Firebase
  
  // RevenueCat - Initializing with safe error handling
  final rcService = Get.put(RevenueCatService());
  try {
    // await rcService.init(); 
  } catch (e) {
    debugPrint('RevenueCat initialization failed: $e');
  }

  runApp(const BhashaApp());
}
