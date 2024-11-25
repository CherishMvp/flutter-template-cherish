import 'dart:io';
import 'package:com.cherish.mingji/utils/revenuecat/pay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '/utils/pay/constant.dart';

/// 会员状态维护
class ProStatusProvider with ChangeNotifier {
  bool _isPro = false;
  bool get isPro => _isPro;
  CustomerInfo get customerInfo => _customerInfo!;
  CustomerInfo? _customerInfo;
  late Offerings _offerings;
  Offerings get offerings => _offerings;
  Future<bool> checkProStatus() async {
    // return true;
    if (Platform.isIOS) {
      if (!(await Purchases.isConfigured)) {
        await payConfigure();
      }
      _customerInfo = await Purchases.getCustomerInfo();
      _isPro = customerInfo.entitlements.active.containsKey(entitlementKey);
      debugPrint("_isPro$_isPro");
      notifyListeners(); // 通知监听者状态已更改
      return _isPro;
    } else {
      return true;
    }
  }

  Future<void> getOffering() async {
    Offerings? list;
    try {
      list = await Purchases.getOfferings();
    } on PlatformException catch (e) {
      debugPrint(e.toString());
    }
    _offerings = list!;
  }
}
