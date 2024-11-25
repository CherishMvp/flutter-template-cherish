import 'dart:developer';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../pay/constant.dart';
import '../pay/store_config.dart';

///检查内购内容
Future<void> payConfigure() async {
  // 开始处理
  log("Platform.isIOS${Platform.isIOS}");
  log("Platform.isIOS${Platform.isMacOS}");
  log("await Purchases.canMakePayments${await Purchases.canMakePayments()}");

  if (!Platform.isIOS && !await Purchases.canMakePayments()) {
    EasyLoading.showError('暂不支持购买');
    debugPrint("内购未配置");
    throw Exception("内购未配置");
  }
// 检查网络
  final payState = await checkAppPurchase();
  if (!payState) {
    EasyLoading.showError('请检查网络');
    throw HttpException("请检查网络");
  }
  debugPrint("_payConfigure==内购配置项");
  StoreConfig(
    store: Store.appStore,
    apiKey: appleApiKey,
  );
  await Purchases.setLogLevel(LogLevel.debug);
  PurchasesConfiguration configuration;
  if (StoreConfig.isForAmazonAppstore()) {
    configuration = AmazonConfiguration(StoreConfig.instance.apiKey);
  } else {
    configuration = PurchasesConfiguration(StoreConfig.instance.apiKey);
  }
  configuration.entitlementVerificationMode =
      EntitlementVerificationMode.informational;
  await Purchases.configure(configuration);
  await Purchases.enableAdServicesAttributionTokenCollection();
  //
  debugPrint("初始化配置内购成功");
  final purchaseUserInfo = await Purchases.getCustomerInfo();
  log("内购用户信息$purchaseUserInfo");
  // 在这里你可以检查用户是否已经有活动的权益 (entitlements)
  if (purchaseUserInfo.entitlements.active.isNotEmpty) {
    log("用户有活动的权益: ${purchaseUserInfo.entitlements.active}");
  } else {
    log("没有找到用户的活动权益");
  }
}

/// 恢复内购
Future<void> restorePurchases(BuildContext context) async {
  try {
    if (!await Purchases.isConfigured) {
      EasyLoading.showInfo('获取配置信息中...');
      await payConfigure();
    }
    EasyLoading.showToast('正在执行操作...');
    final restoredInfo = await Purchases.restorePurchases();
    // 处理恢复后的用户信息
    log("购买信息: $restoredInfo");
    // 检查用户恢复的权益 (Entitlements)
    if (restoredInfo.entitlements.active.isNotEmpty) {
      // 例如，检查某个特定的权益是否有效
      if (restoredInfo.entitlements.active.containsKey(entitlementKey)) {
        log("用户恢复了 premium 权益");
        EasyLoading.showSuccess('恢复成功');
      }
    } else {
      EasyLoading.showInfo('未找到用户的会员权益');
    }
  } catch (e) {
    log("恢复内购失败: $e");
    EasyLoading.showError('未找到用户的会员权益');
  }
}

Future<bool> isRevenueCatConfigured() async {
  try {
    await Purchases.getCustomerInfo();
    return true; // 已配置
  } catch (e) {
    debugPrint("RevenueCat 未配置: $e");
    return false; // 未配置
  }
}

// 重置当前用户
Future<void> resetRevenueCatUser() async {
  await Purchases.logOut(); // 退出当前用户，重置为匿名用户
  debugPrint("RevenueCat 用户已重置为匿名用户");
}

Future<void> handlePayGlobal() async {
  try {
    EasyLoading.showToast('正在获取会员权限...');
    await Future.delayed(const Duration(milliseconds: 2500));
    final paywallResult = await RevenueCatUI.presentPaywall();
    debugPrint('Paywall result: $paywallResult');
    EasyLoading.showError('获取优惠列表失败');
  } on Exception catch (e) {
    // TODO
    EasyLoading.showError('获取优惠列表失败');
  } finally {
    // TODO
    EasyLoading.dismiss();
  }
}

Future<bool> checkAppPurchase() async {
  final List<ConnectivityResult> connectivityResult =
      await (Connectivity().checkConnectivity());
  if (connectivityResult.contains(ConnectivityResult.mobile) ||
      connectivityResult.contains(ConnectivityResult.wifi)) {
    //
    return true;
  } else {
    return false;
  }
}
