import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/constants/app_routes.dart';
import 'core/constants/app_theme.dart';
import 'core/services/storage_service.dart';
import 'core/services/api_service.dart';
import 'features/subscription/revenuecat_service.dart';
import 'features/progress/progress_controller.dart';
import 'shared/models/progress_model.dart';

class BhashaApp extends StatelessWidget {
  const BhashaApp({super.key});

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(UserProgressAdapter());
    await Hive.openBox<UserProgress>('progress');
    await Hive.openBox('settings');
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BhashaApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.welcome,
      getPages: AppRoutes.pages,
      initialBinding: BindingsBuilder(() {
        Get.put(StorageService());
        Get.put(ApiService());
        Get.put(RevenueCatService());
        Get.put(ProgressController());
      }),
    );
  }
}
