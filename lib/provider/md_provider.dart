import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

// 定义 DefaultScreen 枚举
enum DefaultScreen {
  home,
  settings,
  defaultSample,
  imagesSample,
  videosSample,
  textSample,
  emptySample,
}

// 创建 SettingsState 类，使用 ChangeNotifier 进行状态管理
class SettingsState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  DefaultScreen _defaultScreen = DefaultScreen.home;
  bool _useCustomQuillToolbar = true;

  // 获取当前主题模式
  ThemeMode get themeMode => _themeMode;

  // 设置新的主题模式，并通知监听者
  set themeMode(ThemeMode newMode) {
    _themeMode = newMode;
    notifyListeners(); // 当状态变化时，通知所有监听者
  }

  // 获取默认屏幕
  DefaultScreen get defaultScreen => _defaultScreen;

  // 设置新的默认屏幕，并通知监听者
  set defaultScreen(DefaultScreen newScreen) {
    _defaultScreen = newScreen;
    notifyListeners(); // 当状态变化时，通知所有监听者
  }

  // 获取是否使用自定义 Quill 工具栏
  bool get useCustomQuillToolbar => _useCustomQuillToolbar;

  // 设置自定义 Quill 工具栏开关，并通知监听者
  set useCustomQuillToolbar(bool useCustomToolbar) {
    _useCustomQuillToolbar = useCustomToolbar;
    notifyListeners(); // 当状态变化时，通知所有监听者
  }

  /// 保存图片临时路径
  final List<String> _imageTmpPaths = [
    '/Users/cherish/Library/Developer/CoreSimulator/Devices/9AC7F961-ADEB-4567-825E-30FB2A5F9B77/data/Containers/Data/Application/2F126B7B-2AF3-4026-AC9B-B1EAA1DBC532/Documents/2024-09-01T23:34:01.224795.jpg'
  ];

  /// 添加图片临时路径
  void addImageTmpPath(String path) {
    _imageTmpPaths.add(path);
  }

  /// 删除图片临时路径
  void removeImageTmpPath(String path) {
    _imageTmpPaths.remove(path);
  }

  // 删除全部临时路径中的图片路径
  Future<void> removeAllImageTmpPath() async {
    // 内存中的也要删除
    // 通过file的delete方法
    debugPrint("1==删除全部临时路径中的图片路径$_imageTmpPaths");
    await Future.forEach(_imageTmpPaths, (path) async {
      await deleteAssetsByPath(path);
    });
    _imageTmpPaths.clear();
    debugPrint("222=删除全部临时路径中的图片路径$_imageTmpPaths");
  }

  ///删除指定路径中的图片
  static Future<void> deleteAssetsByPath(String filePath) async {
    try {
      final file = File(filePath);
      await file.delete();
      debugPrint("删除图片$filePath");
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }
}
