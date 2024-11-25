import 'dart:io';

import 'package:com.cherish.mingji/components/label/label_admin.dart';
import 'package:com.cherish.mingji/components/tabbar/tabbar.dart';
import 'package:com.cherish.mingji/pages/index/index_page.dart';

import 'package:com.cherish.mingji/pages/person/components/data_backup.dart';
import 'package:com.cherish.mingji/pages/person/cupertino_appleIdLogin.dart';
import 'package:com.cherish.mingji/pages/person/login_page.dart';
import 'package:com.cherish.mingji/pages/test/network_page.dart';

import 'package:com.cherish.mingji/pages/upload/upload.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'package:secure_app_switcher/secure_app_switcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:com.cherish.mingji/pages/person/components/change_theme.dart';
import 'package:upgrader/upgrader.dart';
import '../pages/person/index.dart';

GoRouter get approuter => AppRouter.router;

Future<Map<String, dynamic>> isFirstOpen() async {
  final prefs = await SharedPreferences.getInstance();
  final currentState = prefs.getBool('firstLaunch') ?? true;
  final shouldUpgrade = prefs.getBool('shouldUpgrade') ?? false;
  prefs.setBool('firstLaunch', false); // 设置为 false，避免下次再触发
  return {"currentState": currentState, "shouldUpgrade": shouldUpgrade};
}

class AppRouter {
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  static Future<void> setLoginStatus(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', status);
  }

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GoRouter router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/', // 指定初始页面
      // 全局重定向
      redirect: (context, state) async {
        return null;

        // test
      },
      routes: [
        GoRoute(
            path: '/',
            // builder: (context, state) => const MyTabBar(),
            builder: (context, state) {
              return FutureBuilder<Map<String, dynamic>>(
                future: isFirstOpen(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  const defaultInfo = {
                    "currentState": false,
                    "shouldUpgrade": false
                  };
                  final snapInfo = snapshot.data ?? defaultInfo;

                  return UpgradeAlert(
                      dialogStyle: Platform.isIOS
                          ? UpgradeDialogStyle.cupertino
                          : UpgradeDialogStyle.material,
                      showLater: true,
                      onIgnore: () {
                        SharedPreferences.getInstance().then(
                            (val) => {val.setBool('shouldUpgrade', true)});
                        return false;
                      },
                      upgrader: Upgrader(
                        debugLogging: true,
                        debugDisplayAlways: false, //调试开关
                        debugDisplayOnce: false,

                        willDisplayUpgrade: (
                                {required display,
                                installedVersion,
                                versionInfo}) =>
                            {
                          if (snapInfo['shouldUpgrade'] == false &&
                              (versionInfo!.installedVersion !=
                                  versionInfo.appStoreVersion))
                            {
                              SharedPreferences.getInstance().then(
                                  (val) => {val.setBool('shouldUpgrade', true)})
                            }
                          else
                            {
                              SharedPreferences.getInstance().then((val) =>
                                  {val.setBool('shouldUpgrade', false)})
                            }
                        },
                      ),
                      child: IndexPage());
                },
              );
              // builder: (context, state) => const TimelinePage(
              //   title: '时间线测试页面',
              // ),
            }),

        // setting
        GoRoute(
          path: '/setting',
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: '/theme_change',
          builder: (context, state) => const ChangeTheme(),
        ),
        // LoginPage
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        // CupertinoAppleidlogin
        GoRoute(
          path: '/appleidlogin',
          builder: (context, state) => const CupertinoAppleidlogin(),
        ),
        // DataBackup
        GoRoute(
          path: '/data_backup',
          builder: (context, state) => const DataBackup(),
        ),
        // ChangeTheme
        GoRoute(
          path: '/change_theme',
          builder: (context, state) => const ChangeTheme(),
        ),
        GoRoute(
          path: '/network_test_page',
          builder: (context, state) => const NetworkPage(),
        ),
        GoRoute(
          path: '/label_admin',
          builder: (context, state) => const LabelAdmin(),
        ),

        GoRoute(
          path: '/upload',
          builder: (context, state) => const ImageUploadScreen(),
        ),
        // LivePhotoPicker

        // chat_page
      ]);

  static CustomTransitionPage<void> animateRoute(
      GoRouterState state, Widget widget) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: widget,
      transitionDuration: const Duration(milliseconds: 150),
      transitionsBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) {
        // 使用SlideTransition实现从小往上的动画
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }
}
