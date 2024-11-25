import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

mixin UpdateMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkForUpdates();
    });
  }

  void checkForUpdates() {
    print("准备检查");
    // 使用 upgrader 库弹出更新弹窗
    UpgradeAlert(
        dialogStyle: UpgradeDialogStyle.cupertino,
        child: Center(child: Text('Checking...')));
  }
}
