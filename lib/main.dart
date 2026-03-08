import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'app.dart';
import 'core/services/storage_service.dart';
import 'core/services/analytics_service.dart';
import 'features/subscription/revenuecat_service.dart';
import 'shared/models/progress_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Hive local DB
  await Hive.initFlutter();
  Hive.registerAdapter(UserProgressAdapter());
  await Hive.openBox<UserProgress>('progress');
  await Hive.openBox('settings');

  // Firebase
  await Firebase.initializeApp();

  // Register core services
  Get.put(StorageService());
  Get.put(AnalyticsService());
  Get.put(RevenueCatService());

  // Init RevenueCat
  await Get.find<RevenueCatService>().init();

  runApp(const BhashaApp());
}
