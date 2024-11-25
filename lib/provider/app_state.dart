import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState with ChangeNotifier {
  // 是否显示滚动条
  bool _showScrollbar = true;
  bool isHomeSwiperAutoPlay = true;
  int homeSwiperInterval = 2000;
  final List<bool> schemes = [true, false];
  // 创建 FlexScheme 与中文名称的映射
  final Map<bool, String> schemeNames = {
    true: '自动播放',
    false: '不自动播放',
  };
  File? selectedImage;
  /* 
   * isTxtPhotoMerge：
   *  false: 默认。关闭图文混排，视频和文本单独存储、展示、编辑。不影响文本内容展示
   *  true: 开启图文混排。文本和视频混排模式。内容较长（适合markdown模式）
   */
  bool isTxtPhotoMerge = false; //默认关闭图文混排
  void setSelectedImage(File? image) async {
    selectedImage = image;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedImage', image?.path ?? '');
    notifyListeners();
  }

  AppState() {
    init();
    log("sadasd");
  }
// 设置播放模式
  Future<void> setHomeSwiperAutoPlay(bool value) async {
    isHomeSwiperAutoPlay = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isHomeSwiperAutoPlay', value);
    notifyListeners(); // 通知状态发生改变
  }

  Future<void> setEditState(bool value) async {
    isTxtPhotoMerge = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTxtPhotoMerge', value);
    notifyListeners(); // 通知状态发生改变
  }

  init() async {
    final prefs = await SharedPreferences.getInstance();
    isHomeSwiperAutoPlay = prefs.getBool('isHomeSwiperAutoPlay') ?? true;
    isTxtPhotoMerge = prefs.getBool('isTxtPhotoMerge') ?? false;
    final tmpPath = prefs.getString('selectedImage') ?? 'assets/header.jpg';
    if (tmpPath.isNotEmpty) {
      if (tmpPath.startsWith('assets/')) {
        log("tmp$tmpPath");
        selectedImage = await copyAssetToTemp(tmpPath, path.basename(tmpPath));
      } else {
        selectedImage = File(tmpPath);
      }
    }
    notifyListeners();
  }

  // 下面是一个复制资产文件到临时目录的示例方法
  Future<File> copyAssetToTemp(String assetPath, String fileName) async {
    // 读取资产文件并写入到临时路径
    ByteData data = await rootBundle.load(assetPath);
    final tmpDir = await getTemporaryDirectory();
    final tmpFilePath = path.join(tmpDir.path, fileName);

    File file = File(tmpFilePath);
    await file.writeAsBytes(data.buffer.asUint8List());
    return file;
  }
  // 使用    final prefs = await SharedPreferences.getInstance();缓存

  void updateShowScrollbar(bool show) {
    _showScrollbar = show;
    notifyListeners(); // 通知状态发生改变
  }

  // 获取滚动条的显示状态
  bool get showScrollbar => _showScrollbar;
}
