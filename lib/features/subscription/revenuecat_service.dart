import 'dart:io';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/analytics_service.dart';

class RevenueCatService extends GetxService {
  final _isPro = false.obs;
  bool get isPro => _isPro.value;

  // RevenueCat API keys — replace with real keys from RevenueCat dashboard
  static const _iosKey     = 'appl_YOUR_IOS_KEY_HERE';
  static const _androidKey = 'goog_YOUR_ANDROID_KEY_HERE';

  Future<RevenueCatService> init() async {
    await Purchases.setLogLevel(LogLevel.debug);
    final config = PurchasesConfiguration(
      Platform.isIOS ? _iosKey : _androidKey,
    );
    await Purchases.configure(config);
    await checkSubscriptionStatus();
    return this;
  }

  Future<void> checkSubscriptionStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _isPro.value = customerInfo.entitlements.active
          .containsKey(AppStrings.proEntitlement);
    } catch (_) {
      _isPro.value = false;
    }
  }

  Future<List<Package>> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> purchasePackage(Package package) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      final isNowPro = customerInfo.customerInfo.entitlements.active
          .containsKey(AppStrings.proEntitlement);
      _isPro.value = isNowPro;
      if (isNowPro) {
        await Get.find<AnalyticsService>()
            .logSubscriptionStart(package.packageType.name);
      }
      return isNowPro;
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) return false;
      rethrow;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      _isPro.value = customerInfo.entitlements.active
          .containsKey(AppStrings.proEntitlement);
      return _isPro.value;
    } catch (_) {
      return false;
    }
  }
}
