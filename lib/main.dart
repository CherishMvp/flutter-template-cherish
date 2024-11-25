import 'dart:developer';
import 'dart:io';

import 'package:com.cherish.mingji/provider/app_state.dart';
import 'package:com.cherish.mingji/provider/pro_status_provider.dart';
import 'package:com.cherish.mingji/provider/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:com.cherish.mingji/provider/auth_provider.dart';
import 'package:com.cherish.mingji/provider/note_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
// import 'package:secure_app_switcher/secure_app_switcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'generated/l10n.dart';
import 'provider/mode.dart';
import 'router/index.dart';
import 'utils/common.dart';
import 'provider/md_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 使用 await 来等待屏幕方向设置完成
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, // 仅允许竖屏正向
    DeviceOrientation.portraitDown, // 可选：允许竖屏反向
  ]);

  final prefs = await SharedPreferences.getInstance();

  //TODO 针对开发环境，清除缓存中的上一次构建的相对路径（相当于换设备后内容导入）
  prefs.remove("noteImagesPath");

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  log("packageInfo${packageInfo.version}");
  String version = packageInfo.version;
  prefs.setString('app_version', version);
  // noteImages
  String? noteImagesPath = prefs.getString('noteImagesPath');
  String? noteImagesDir = prefs.getString('noteImagesDir');
  if (noteImagesPath != null) {
    log('Cached noteImagesPath: $noteImagesPath');
  } else {
    log('No cached noteImagesPath found');
  }
  if (noteImagesDir != null) {
    log('Cached noteImagesDir: $noteImagesDir');
  } else {
    log('No cached noteImagesDir found');
  }
  // SecureAppSwitcher.on(
  //     iosStyle: SecureMaskStyle.blurLight); //开启iOS后台切换模糊效果（隐私保护）

  if (noteImagesPath == null) {
    final d1 = await getApplicationDocumentsDirectory();
    Directory directory = Directory('${d1.path}/noteImages');
    await directory.create();
    await prefs.setString('noteImagesPath', directory.path);
    log('Initialized noteImagesPath: ${directory.path}');
  }
  if (noteImagesDir == null) {
    final d1 = await getApplicationDocumentsDirectory();
    Directory directory = Directory('${d1.path}/noteImages');
    await directory.create();
    await prefs.setString('noteImagesDir', directory.path);
    log('Initialized noteImagesDir: ${directory.path}');
  }
  final sb = await getLoadPreferences(); //初始化主题内容
  ThemeMode themeMode = sb['themeMode'];
  int themeIndex = sb['currentThemeIndex'];
  // 创建 ModeProvider 实例
  ModeProvider modeProvider = ModeProvider();

  // 从 SharedPreferences 加载模式
  await modeProvider.loadModeFromPreferences();
  configLoading(); // 初始化 EasyLoading 的配置

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
          create: (context) => AuthProvider(AppRouter.router)),
      Provider(
          create: (_) =>
              AppRouter.router), //注入route路由表到上下文。待会在AuthProvider要注入使用
      ChangeNotifierProvider(
        create: (context) => AuthProvider(context.read<GoRouter>()),
      ),
      ChangeNotifierProvider(
        create: (context) => NoteProvider(),
      ),
      ChangeNotifierProvider(
        create: (context) => SettingsState(),
      ),
      ChangeNotifierProvider(
        create: (context) =>
            ThemeProvider(themeMode, themeIndex), //传入初始化主题信息，避免闪烁
      ),
      ChangeNotifierProvider(
        create: (context) => AppState(),
      ),
      ChangeNotifierProvider(create: (_) => modeProvider),
      ChangeNotifierProvider(create: (_) => ProStatusProvider()),

      // 添加其他需要共享的Provider
    ],
    child: const MainApp(),
  ));
  // 延时两秒
  // Future.delayed(const Duration(seconds: 2));
}

void configLoading() {
  EasyLoading.instance
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..dismissOnTap = false; // 是否允许点击背景取消 loading
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  RouteObserver routeObserver = RouteObserver();
  // Locale _appLocale = window.locale;
  final Locale _appLocale = const Locale('zh', 'CN'); //设置语言默认为中文
  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return Consumer<ThemeProvider>(builder: (context, themeController, child) {
      {
        var materialApp = MaterialApp.router(
          routerConfig: AppRouter.router, //路由配置
          // 注：这里可以添加多个 NavigatorObserver
          debugShowCheckedModeBanner: false,
          // theme: themeController.themeLight(),
          // darkTheme: themeController.themeDark(),
          // themeMode: ThemeMode.system,
          // TODO 使用自定义主题
          theme: themeController.lightTheme,
          darkTheme: themeController.darkTheme,
          themeMode: themeController.themeMode,
          // theme: Theme.of(context).brightness == Brightness
          //     ? themeController.iosLightTheme
          //     : themeController.iosDarkTheme,
          // theme: themeController.iosTheme,
          localizationsDelegates: const [
            // 2
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate
          ],
          locale: _appLocale,
          supportedLocales: S.delegate.supportedLocales,
          localeResolutionCallback: (locale, supportedLocales) {
            // 如果语言是英语
            if (locale?.languageCode == 'en') {
              //注意大小写，返回美国英语
              return const Locale('en', 'US');
            } else {
              return locale;
            }
          },
          onGenerateTitle: (context) {
            return "韶华纪";
          }, //不能直接设置title，因为没有父树
          builder: EasyLoading.init(),
        );

        return materialApp;
      }
    });
  }
}
