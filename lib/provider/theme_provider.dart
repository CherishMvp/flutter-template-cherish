import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

/* 
dark:
bg:1f1f1f
item:292929
light:
bg:ffffff
item:f5f5f5
 */
// 定义各个平台的路由行为
const pageTransitionsTheme = PageTransitionsTheme(
  builders: <TargetPlatform, PageTransitionsBuilder>{
    // TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(), //缓慢上拉出现
    // TargetPlatform.android: ZoomPageTransitionsBuilder(), //放大显示
    TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(), //朝下往上渐变
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.linux: NoAnimationPageTransitionsBuilder(),
    TargetPlatform.macOS: NoAnimationPageTransitionsBuilder(),
    TargetPlatform.windows: NoAnimationPageTransitionsBuilder(),
  },
);

class ThemeProvider with ChangeNotifier {
  static const String themeIndexKey = 'themeIndexKey';
  static const String darkModeKey = 'darkModeKey';

  final List<FlexScheme> schemes = [
    FlexScheme.aquaBlue,
    FlexScheme.mandyRed,
    FlexScheme.indigo,
    FlexScheme.gold,
    FlexScheme.materialBaseline,
    FlexScheme.materialHc,
    FlexScheme.mango,
  ];
  // 创建 FlexScheme 与中文名称的映射
  final Map<FlexScheme, String> schemeNames = {
    FlexScheme.aquaBlue: '海蓝色',
    FlexScheme.indigo: '靛蓝',
    FlexScheme.gold: '金色',
    FlexScheme.mandyRed: '曼迪红',
    FlexScheme.materialBaseline: '浅紫色',
    FlexScheme.materialHc: '高对比度',
    FlexScheme.mango: '芒果',
  };
  String getSchemesNameByIndex(int index) => schemeNames[schemes[index]]!;

  int _currentThemeIndex = 0;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = true; // 添加加载状态
  bool get isLoading => _isLoading;
  int get currentThemeIndex => _currentThemeIndex;
  // 获取当前主题名称
  String get currentThemeName => schemes[_currentThemeIndex].name;
  FlexScheme get currentScheme => schemes[_currentThemeIndex];
  ThemeMode get themeMode => _themeMode;
  ThemeData get lightTheme => FlexColorScheme.light(
        background: HexColor("#f5f5f5"),
        scaffoldBackground: HexColor("#f5f5f5"),
        appBarBackground: HexColor("#f5f5f5"),
        fontFamily: 'HarmonyOS_Sans_SC_Regular',
        pageTransitionsTheme: pageTransitionsTheme, //定义路由行为
        scheme: schemes[_currentThemeIndex],
        appBarStyle: FlexAppBarStyle.surface,
      ).toTheme.copyWith(brightness: Brightness.light);
  ThemeData get darkTheme => FlexColorScheme.dark(
        fontFamily: 'HarmonyOS_Sans_SC_Regular',
        pageTransitionsTheme: pageTransitionsTheme, //定义路由行为
        scheme: schemes[_currentThemeIndex],
        appBarStyle: FlexAppBarStyle.surface,
      ).toTheme.copyWith(
            brightness: Brightness.dark,
          );

  // ThemeProvider() {
  //   _loadPreferences();
  // }
  // 初始化时通过构造函数传入之前存储的主题模式
  ThemeProvider(this._themeMode, this._currentThemeIndex);

  void switchTheme() {
    _currentThemeIndex = (_currentThemeIndex + 1) % schemes.length;
    _savePreferences();
    notifyListeners();
  }

  void setThemeByIndex(int index) {
    _currentThemeIndex = index;
    _savePreferences();
    notifyListeners();
  }

  void setTheme(FlexScheme scheme) {
    _currentThemeIndex = schemes.indexOf(scheme);
    _savePreferences();
    notifyListeners();
  }

  void toggleDarkMode() {
    debugPrint("切换前" + _themeMode.toString());
    if (_themeMode == ThemeMode.system) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    debugPrint("_themeMode: $_themeMode");
    _savePreferences();
    notifyListeners();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _currentThemeIndex = prefs.getInt(themeIndexKey) ?? 0;
    int themeModeIndex = prefs.getInt(darkModeKey) ?? 0;
    _themeMode = ThemeMode.values[themeModeIndex];
    debugPrint("_themeMode: $_themeMode");
    _isLoading = false;
    debugPrint("加载成功" + _currentThemeIndex.toString());
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(themeIndexKey, _currentThemeIndex);
    await prefs.setInt(darkModeKey, _themeMode.index);
    debugPrint("保存成功" + _currentThemeIndex.toString());
    notifyListeners();
  }

  // 保存当前主题模式
  Future<void> updateThemeMode(ThemeMode mode) async {
    debugPrint("切换前" + _themeMode.toString());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
    _themeMode = mode;
    _savePreferences();
    debugPrint("切换后" + _themeMode.toString());
    notifyListeners();
  }
}
