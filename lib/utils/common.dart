import 'dart:ui' as ui;

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart'; 
import 'package:intl/intl.dart';
import 'package:lunar/calendar/Solar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pay/constant.dart';
import 'package:path/path.dart' show basename;
import 'package:timeago/timeago.dart' as timeago;

// checkPhotoPermission
Future<PermissionStatus> checkPhotoPermission() async {
  late PermissionStatus status;
  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt <= 32) {
      status = await Permission.storage.request();
    } else {
      status = await Permission.photos.request();
    }
  } else {
    status = await Permission.photos.request();
    debugPrint("asdsad" + status.toString());
    await Permission.photos.isDenied.then((value) async {
      if (value) {
        // 打开应用设置，让用户手动授予权限
        await openAppSettings();
      }
    });
    print("ios permission" + status.toString());
  }
  return status;
}

const String pravicyLink = 'https://revenue-api.fancyzh.top/privacy.html';

const String homeWidgetUrl =
    'http://qiniu.fancyzh.top/quote/video/quote_home_widget.mp4';

// 分类设置常量
const String categotyIntroImg =
    'http://qiniu.fancyzh.top/quote/img/StockCake-Heartfelt%20Nature%20Love_1718980766.jpg';

// toast
// utils/toast_utils.dart

void zToast(String message,
    {String? position = 'center', BuildContext? context}) {
  final positionMap = {
    'top': StyledToastPosition.top,
    'center': StyledToastPosition.center,
    'bottom': StyledToastPosition.bottom,
    'right': StyledToastPosition.right,
    'left': StyledToastPosition.left
  };
  showToast(
    message,
    textPadding: EdgeInsets.all(14),
    context: context,
    borderRadius: BorderRadius.circular(16),
    animation: StyledToastAnimation.slideToTopFade,
    reverseAnimation: StyledToastAnimation.slideToTopFade,
    position: positionMap[position],
  );
}

// 全局提示
ToastFuture globalToast(String message, BuildContext context,
    {StyledToastPosition? position}) {
  return showToast(message,
      context: context,
      borderRadius: BorderRadius.circular(16),
      animation: StyledToastAnimation.slideToTopFade,
      reverseAnimation: StyledToastAnimation.slideToTopFade,
      position: position ?? StyledToastPosition.center);
}

// 获取今日日期信息(农历)
Map<String, String> getTodayDateInfo() {
  DateTime now = DateTime.now();
  // DateTime now = DateTime.now().toUtc().add(Duration(hours: 8));
  // Lunar now = Lunar.fromDate(DateTime.now());
  String formattedDate = DateFormat('dd').format(now);
  Solar date = Solar.fromYmd(now.year, now.month, now.day);
  final input = date.getLunar();

  String nongliDay = input.getDayInChinese();

  String nongliMonth = input.getMonthInChinese().toString();

  String week = input.getWeekInChinese().toString();
  String day = formattedDate;
  debugPrint("nongli $nongliMonth$nongliDay, week $week");
  return {"day": day, "lunar": '$nongliMonth月$nongliDay', "week": '周$week'};
}

// 需要某种能力值时候进行内购,如'svip'字段。如果没有会自动唤起订阅墙
Future<PaywallResult> checkPro() async {
  final paywallResult =
      await RevenueCatUI.presentPaywallIfNeeded(entitlementKey);
  debugPrint('Paywall result: $paywallResult');
  return paywallResult;
}

Future<void> saveUserId(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('userId', userId);
}

Future<String?> getUserId() async {
  final prefs = await SharedPreferences.getInstance();
  final userIdentifier = prefs.getString('userIdentifier');
  return userIdentifier;
}

// 获取用户唯一标识
Future<String> getUserIdentifier() async {
  final prefs = await SharedPreferences.getInstance();
  // 假设登录了
  await prefs.setString('userIdentifier', 'cherish-zwt-test');
  final id = prefs.get('userIdentifier') ?? '';
  return id.toString();
}

Future<void> clearUserIdentifier() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('userIdentifier');
}

Future<void> clearUserId() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('userId');
}

/// 判断用户是否已经登录
Future<bool> isUserLoggedIn() async {
  String? userId = await getUserId();
  return userId != null && userId.isNotEmpty;
}

/// 获取用户ID(后台唯一生成)
Future<String> getUserIdFromBackend() async {
  // 通过用户登录后，从您的后台系统获取唯一用户ID
  String userId = await getUserId() ?? '';
  if (userId.isEmpty) {
    String userId = '1'; //后台获取
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }
  return userId;
}

Future<void> logoutUser() async {
  await Purchases.logOut();
  // 清理本地用户信息，准备下次登录
}

// 处理md中图片路径拼接
List<dynamic> processJsonData(List<dynamic> jsonData) {
  // 遍历每个 item
  for (var item in jsonData) {
    // 检查 item 是否是 Map 类型，并且 insert 是否包含媒体字段
    if (item is Map && item.containsKey('insert') && item['insert'] is Map) {
      _processMediaPath(item['insert'], 'image');
      _processMediaPath(item['insert'], 'video');
      _processAudioPath(item['insert'], 'audio');
    }
  }
  return jsonData;
}

// 通用处理图片和视频路径的函数
void _processMediaPath(Map<String, dynamic> insert, String mediaType) {
  if (insert.containsKey(mediaType)) {
    String originPath = insert[mediaType];
    insert[mediaType] = '/${basename(originPath)}';
  }
}

// 专门处理音频路径的函数
void _processAudioPath(Map<String, dynamic> insert, String mediaType) {
  if (insert.containsKey(mediaType)) {
    String originAudioPath = insert[mediaType]['path'];
    insert[mediaType]['path'] = '/${basename(originAudioPath)}';
  }
}

///拼接content中video和image路径
List<dynamic> reverseProcessJsonData(
    List<dynamic> jsonData, String prefixPath) {
  // 遍历每个 item
  for (var item in jsonData) {
    // 检查 item 是否是 Map 类型，并且 insert 是否包含对应的媒体字段
    if (item is Map && item.containsKey('insert') && item['insert'] is Map) {
      var insert = item['insert'];

      // 检查是否有 image 字段并拼接前缀
      if (insert.containsKey('image')) {
        String imagePath = insert['image'];
        // 拼接前缀路径
        String newImagePath = prefixPath + imagePath;
        // 更新 image 字段
        insert['image'] = newImagePath;
      }

      // 检查是否有 video 字段并拼接前缀
      if (insert.containsKey('video')) {
        String videoPath = insert['video'];
        // 拼接前缀路径
        String newVideoPath = prefixPath + videoPath;
        // 更新 video 字段
        insert['video'] = newVideoPath;
      }

      // 检查是否有 audio 字段并拼接前缀
      if (insert.containsKey('audio')) {
        String audioPath = insert['audio']['path'];
        // 拼接前缀路径
        String newAudioPath = prefixPath + audioPath;
        // 更新 audio 字段
        insert['audio']['path'] = newAudioPath;
      }
    }
  }
  // 返回处理后的数据
  return jsonData;
}

// item['insert'] is Map &&
//     item['insert'].containsKey('video')) {
//   String newImagePath = item['insert']['video'];
// 获取content中的image信息()
// TODO 或者通过连表查询获得根据ID
String extractImagePaths(List<dynamic> jsonData, String prefixPath) {
  List<String> imagePaths = [];

  // 遍历每个 item
  for (var item in jsonData) {
    // 检查 item 是否是 Map 类型，并且 insert 是否包含 image 字段
    if (item is Map &&
        item.containsKey('insert') &&
        item['insert'] is Map &&
        item['insert'].containsKey('image')) {
      String newImagePath = item['insert']['image'];
      // 添加到结果数组中
      // String newImagePath = prefixPath + imagePath;
      imagePaths.add(newImagePath);
    }
  }
  // debugPrint("yyy: $imagePaths");
  return imagePaths.join(',');
}

String extractVideoPaths(List<dynamic> jsonData, String prefixPath) {
  List<String> imagePaths = [];

  // 遍历每个 item
  for (var item in jsonData) {
    // 检查 item 是否是 Map 类型，并且 insert 是否包含 image 字段
    if (item is Map &&
        item.containsKey('insert') &&
        item['insert'] is Map &&
        item['insert'].containsKey('video')) {
      String newImagePath = item['insert']['video'];
      // 添加到结果数组中
      // String newImagePath = prefixPath + imagePath;
      imagePaths.add(newImagePath);
    }
  }
  // debugPrint("videoxxx: $imagePaths");
  return imagePaths.join(',');
}

String extractAudioPaths(List<dynamic> jsonData, String prefixPath) {
  List<String> imagePaths = [];

  // 遍历每个 item
  for (var item in jsonData) {
    // 检查 item 是否是 Map 类型，并且 insert 是否包含 image 字段
    if (item is Map &&
        item.containsKey('insert') &&
        item['insert'] is Map &&
        item['insert'].containsKey('audio')) {
      String newImagePath = item['insert']['audio']['path'];
      // 添加到结果数组中
      // String newImagePath = prefixPath + imagePath;
      imagePaths.add(newImagePath);
    }
  }
  debugPrint("audioxxx: $imagePaths");
  return imagePaths.join(',');
}

// 合并方法，一次性处理
// 创建一个包含图片、视频、音频路径的对象
class MediaPaths {
  List<String> imagePaths;
  List<String> videoPaths;
  List<String> audioPaths;

  MediaPaths({
    required this.imagePaths,
    required this.videoPaths,
    required this.audioPaths,
  });
}

// 提取图片、视频、音频路径，一次性遍历
MediaPaths extractMediaPaths(List<dynamic> jsonData) {
  List<String> imagePaths = [];
  List<String> videoPaths = [];
  List<String> audioPaths = [];

  // 遍历每个 item
  for (var item in jsonData) {
    // 检查 item 是否是 Map 类型，并且 insert 是否包含对应的媒体字段
    if (item is Map && item.containsKey('insert') && item['insert'] is Map) {
      var insert = item['insert'];

      // 检查是否有 image 字段
      if (insert.containsKey('image')) {
        String imagePath = insert['image'];
        imagePaths.add(imagePath); // 添加图片路径
      }

      // 检查是否有 video 字段
      if (insert.containsKey('video')) {
        String videoPath = insert['video'];
        videoPaths.add(videoPath); // 添加视频路径
      }

      // 检查是否有 audio 字段
      if (insert.containsKey('audio')) {
        String audioPath = insert['audio']['path'];
        audioPaths.add(audioPath); // 添加音频路径
      }
    }
  }

  // 返回一个包含图片、视频和音频路径的对象
  return MediaPaths(
    imagePaths: imagePaths,
    videoPaths: videoPaths,
    audioPaths: audioPaths,
  );
}

// 创建一个包含图片、视频、音频路径的对象，同时添加前缀
class MediaPathsWithPrefix {
  List<String> imagePaths;
  List<String> videoPaths;
  List<String> audioPaths;

  MediaPathsWithPrefix({
    required this.imagePaths,
    required this.videoPaths,
    required this.audioPaths,
  });
}

// 提取图片、视频、音频路径，并加上前缀
MediaPathsWithPrefix extractMediaPathsWithPrefix(
    List<dynamic> jsonData, String prefixPath) {
  List<String> imagePaths = [];
  List<String> videoPaths = [];
  List<String> audioPaths = [];

  // 遍历每个 item
  for (var item in jsonData) {
    // 检查 item 是否是 Map 类型，并且 insert 是否包含对应的媒体字段
    if (item is Map && item.containsKey('insert') && item['insert'] is Map) {
      var insert = item['insert'];

      // 检查是否有 image 字段并加上前缀
      if (insert.containsKey('image')) {
        String imagePath = insert['image'];
        String newImagePath = prefixPath + imagePath; // 添加前缀
        imagePaths.add(newImagePath);
        insert['image'] = newImagePath; // 修改原始路径
      }

      // 检查是否有 video 字段并加上前缀
      if (insert.containsKey('video')) {
        String videoPath = insert['video'];
        String newVideoPath = prefixPath + videoPath; // 添加前缀
        videoPaths.add(newVideoPath);
        insert['video'] = newVideoPath; // 修改原始路径
      }

      // 检查是否有 audio 字段并加上前缀
      if (insert.containsKey('audio')) {
        String audioPath = insert['audio']['path'];
        String newAudioPath = prefixPath + audioPath; // 添加前缀
        audioPaths.add(newAudioPath);
        insert['audio']['path'] = newAudioPath; // 修改原始路径
      }
    }
  }

  // 返回一个包含图片、视频和音频路径的对象
  return MediaPathsWithPrefix(
    imagePaths: imagePaths,
    videoPaths: videoPaths,
    audioPaths: audioPaths,
  );
}

String extractPath(String input) {
  // 调整正则表达式来匹配 `path: "/something"`
  RegExp regExp = RegExp(r'path:\s*"([^"]+)"');
  Match? match = regExp.firstMatch(input);

  if (match != null) {
    return match.group(1)!;
  }

  return ''; // 如果没有匹配到，返回空字符串或其他默认值
}

Future<Map<String, dynamic>> getLoadPreferences() async {
  const String themeIndexKey = 'themeIndexKey';
  const String darkModeKey = 'darkModeKey';
  final prefs = await SharedPreferences.getInstance();
  int themeModeIndex = prefs.getInt(darkModeKey) ?? 0;
  int currentThemeIndex = prefs.getInt(themeIndexKey) ?? 0;
  debugPrint("currentThemeIndex: $currentThemeIndex" +
      "themeModeIndex: $themeModeIndex");
  await prefs.setInt(themeIndexKey, currentThemeIndex);
  await prefs.setInt(darkModeKey, themeModeIndex);
  final themeMode = ThemeMode.values[themeModeIndex];
  return {"themeMode": themeMode, "currentThemeIndex": currentThemeIndex};
}

final remoteImages = [
  Image.network('https://picsum.photos/400?image=9'),
  Image.network('https://picsum.photos/800?image=1'),
  Image.network('https://picsum.photos/900/350?image=2'),
  Image.network('https://picsum.photos/1000?image=7'),
  Image.network('https://picsum.photos/100?image=4'),
];

final localImages = [
  'assets/images/screenshot_1.png',
  'assets/images/screenshot_1.png',
  'assets/images/screenshot_1.png',
];

// 自定义数据结构
class ImageItem {
  final String localPath;

  ImageItem({required this.localPath});
}

// 计算文字行数
int calculateTextLines({
  required String text,
  required double maxWidth,
  TextStyle? style,
  int maxLines = 100,
}) {
  final TextPainter textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: maxLines,
    textDirection: ui.TextDirection.ltr, // 文字方向
  )..layout(maxWidth: maxWidth);

  return textPainter.computeLineMetrics().length;
}

// 时间计算
String formatDate(DateTime? date) {
  if (date == null) {
    return '';
  }
  return '${date.year}年${date.month}月${date.day}日';
}

String daysDifference(DateTime date) {
  // 配置中文显示
  timeago.setLocaleMessages('zh_CN', timeago.ZhCnMessages());
  // 计算时间差并返回相应的描述
  return timeago.format(date, locale: 'zh_CN');
}

/// 创建document下的文件夹
Future<Directory> getOrCreateDirectory(String folderName) async {
  final directory = await getApplicationDocumentsDirectory();
  final folderPath = '${directory.path}/$folderName';
  final folder = Directory(folderPath);

  if (!await folder.exists()) {
    await folder.create();
  }

  return folder;
}

UploadLimits getUploadLimits(bool isMember) {
  return isMember ? memberLimits : nonMemberLimits;
}
