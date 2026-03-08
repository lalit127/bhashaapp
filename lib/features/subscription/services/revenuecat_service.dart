import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService extends GetxService {
  static const _proEntitlement = 'pro_access';

  // Your RevenueCat API keys — set via --dart-define or environment
  static const _androidKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_KEY',
    defaultValue: 'goog_YOUR_KEY_HERE',
  );
  static const _iosKey = String.fromEnvironment(
    'REVENUECAT_IOS_KEY',
    defaultValue: 'appl_YOUR_KEY_HERE',
  );

  final _isPro = false.obs;
  bool get isPro => _isPro.value;

  static Future<void> init() async {
    await Purchases.setLogLevel(LogLevel.info);
    final config = PurchasesConfiguration(
      Platform.isIOS ? _iosKey : _androidKey,
    );
    await Purchases.configure(config);
    Get.put(RevenueCatService())._checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final info = await Purchases.getCustomerInfo();
      _isPro.value = info.entitlements.active.containsKey(_proEntitlement);
    } catch (_) {
      _isPro.value = false;
    }
    // Listen to future changes
    Purchases.addCustomerInfoUpdateListener((info) {
      _isPro.value = info.entitlements.active.containsKey(_proEntitlement);
    });
  }

  /// Returns available packages for the current offering
  Future<List<Package>> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? [];
    } catch (_) {
      return [];
    }
  }

  /// Purchase a package. Returns true on success.
  Future<bool> purchasePackage(Package package) async {
    try {
      final info = await Purchases.purchasePackage(package);
      _isPro.value = info.customerInfo.entitlements.active.containsKey(_proEntitlement);
      return _isPro.value;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) return false;
      rethrow;
    }
  }

  /// Restore previous purchases
  Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      _isPro.value = info.entitlements.active.containsKey(_proEntitlement);
      return _isPro.value;
    } catch (_) {
      return false;
    }
  }
}
