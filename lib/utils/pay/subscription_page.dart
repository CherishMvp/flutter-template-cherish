import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionPage extends StatefulWidget {
  @override
  _SubscriptionPageState createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  bool _isLoading = true;
  bool _hasProAccess = false;
  final String entitlementKey = 'pro_access'; // 替换为你的 entitlementKey

  @override
  void initState() {
    super.initState();
    _checkProStatus();
  }

  Future<void> _checkProStatus() async {
    setState(() {
      _isLoading = true;
    });

    // 检查用户是否拥有特定的 entitlement
    final customerInfo = await Purchases.getCustomerInfo();
    _hasProAccess =
        customerInfo.entitlements.all[entitlementKey]?.isActive ?? false;

    // 如果用户没有该权限，则显示订阅墙
    if (!_hasProAccess) {
      // final paywallResult =
      //     await RevenueCatUI.presentPaywallIfNeeded(entitlementKey);
      // if (paywallResult.status == PaywallStatus.purchaseSuccess) {
      //   setState(() {
      //     _hasProAccess = true;
      //   });
      // }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Loading...")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Subscription Page")),
      body: Center(
        child: _hasProAccess
            ? Text("You have Pro Access!")
            : Text("You don't have Pro Access. Subscribe to unlock."),
      ),
    );
  }
}
