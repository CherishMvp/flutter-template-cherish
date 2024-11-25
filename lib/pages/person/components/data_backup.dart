import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:com.cherish.mingji/components/common/cherish_appbar.dart';
import 'package:com.cherish.mingji/model/data.dart';
import 'package:com.cherish.mingji/pages/export/tools/common.dart';
import 'package:com.cherish.mingji/utils/constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class DataBackup extends StatefulWidget {
  const DataBackup({super.key});

  @override
  State<DataBackup> createState() => _DataBackupState();
}

class _DataBackupState extends State<DataBackup> {
  final List<Map<String, dynamic>> items = [
    {
      'title': '数据导出',
      'subtitle': '将日记数据导出到zip文件中',
      'icon': CupertinoIcons.arrow_up_doc,
    },
    {
      'title': '数据导入',
      'subtitle': '从zip文件中导入日记数据',
      'icon': CupertinoIcons.arrow_down_doc,
    },
    {
      'title': '注意事项',
      'subtitle': '在进行数据导入/导出时，请先备份数据',
      'icon': CupertinoIcons.info_circle,
    },
  ];
  // 获取应用文档目录路径
  Directory? directory;

// 获取源数据内容
  File? selectedZipFile;

  Directory? imagesDirectory;
  @override
  void initState() {
    super.initState();
    _initializeDirectory();
  }

  void _initializeDirectory() async {
    // 获取应用文档目录
    final tempDirectory = await getApplicationDocumentsDirectory();
    // 如果目标文件夹不存在，创建文件夹
    final imageDirectory = Directory('${tempDirectory.path}/noteImages');
    if (!await imageDirectory.exists()) {
      await imageDirectory.create(recursive: true);
    }
    setState(() {
      directory = tempDirectory;
      imagesDirectory = imageDirectory;
    });
    debugPrint('response data is ${imagesDirectory!.path}');
    debugPrint('response data is ${directory!.path}');
  }

  @override
  void dispose() {
    deposeHandle();
    super.dispose();
  }

  deposeHandle() async {
    final rs = await selectedZipFile?.delete();
    print("删除结果:${rs.toString()}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CherishAppbar(title: '数据备份'),
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(items[index]['icon'],
                        color: Theme.of(context).primaryColor),
                    title: Text(items[index]['title']),
                    subtitle: Text(items[index]['subtitle']),
                    isThreeLine: true,
                    trailing: const Icon(
                        Icons.chevron_right), // Material 风格的 Chevron 图标
                    onTap: () => _handleTap(context, index),
                    horizontalTitleGap: 8,
                    visualDensity: VisualDensity(horizontal: -4), // 减少水平间距
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  void _handleTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        _cloudBackup(context);
        break;
      case 1:
        _pickZipFile(context);
        break;
      case 2:
        // 第三个 section 的点击事件
        print('第三个点击事件');
        _notification(context);
        // 这里可以调用具体的逻辑
        break;
    }
  }

  void _notification(BuildContext context) {
    showCupertinoModalBottomSheet(
      context: context,
      builder: (context) {
        return Material(
          child: Container(
            padding: const EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * 0.3,
            child: const Padding(
              padding: EdgeInsets.only(left: 18.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '注意事项',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '1. 请在网络良好的情况下进行数据备份',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '2. 请确保您的设备有足够的存储空间',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '3. 数据备份可能会花费一些时间',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 具体的导出文件操作
  Future<String> _exportDataAndFiles(BuildContext context) async {
    // 获取数据库数据
    final sql = SQLHelper();
    List<Doodle> doodles = await sql.getDoodlesByBackup();
    String dbName = sql.databaseName; // 替换为实际的数据库名称

    // 转换数据库数据为JSON格式
    String dbDataJson = jsonEncode(doodles);

    // 获取应用文档目录
    final directory = await getApplicationDocumentsDirectory();
    // 创建ZIP文件
    final zipFile = File('${directory.path}/backup.zip');
    final encoder = ZipFileEncoder();
    encoder.create(zipFile.path);

    // 获取SQLite数据库的实际路径
    final dbDirectory = await getDatabasesPath();
    final dbPath = join(dbDirectory, dbName); // 替换为实际的数据库名称

    // 检查数据库文件是否存在
    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      debugPrint("数据库文件存在，路径为：$dbPath");
      sql.close();
      // 将现有的SQLite数据库文件添加到ZIP文件
      encoder.addFile(dbFile);
    } else {
      debugPrint("数据库文件不存在，路径为：$dbPath");
    }

    // 添加数据库数据的JSON文件到ZIP
    final jsonFile = File('${directory.path}/doodles.json');
    await jsonFile.writeAsString(dbDataJson);
    encoder.addFile(jsonFile);

    // 创建用于存储图像的临时文件夹路径
    final tempImageDirectory = Directory('${directory.path}/temp_images');
    // 如果临时文件夹不存在则创建
    if (!await tempImageDirectory.exists()) {
      await tempImageDirectory.create();
    }

    // 图像文件夹路径
    final imagesDirectory = Directory('${directory.path}/noteImages');

    // 将图像文件复制到临时文件夹并添加到压缩包
    if (await imagesDirectory.exists()) {
      List<FileSystemEntity> files = imagesDirectory.listSync();
      for (var file in files) {
        if (file is File) {
          // 复制图像文件到临时文件夹
          final targetFile =
              File('${tempImageDirectory.path}/${file.uri.pathSegments.last}');
          await file.copy(targetFile.path);
        }
      }
      // ---- 处理密钥文件 ----
      // 创建密钥文件的路径
      final encryptionKeyFile =
          File('${tempImageDirectory.path}/encryption_key.txt');
      // 假设有一个获取加密密钥的方法
      String encryptionKey = await getOrCreateEncryptionKey();
      // 将加密密钥写入文件
      await encryptionKeyFile.writeAsString(encryptionKey);

      // 将整个临时文件夹添加到压缩包
      encoder.addDirectory(tempImageDirectory);
    }

    // 关闭ZIP文件
    encoder.close();

    // 清理临时文件和目录
    await jsonFile.delete(); // 删除doodles.json
    await tempImageDirectory.delete(recursive: true); // 递归删除临时文件夹
    if (zipFile.existsSync()) {
      zToast('数据备份完成', position: 'center', context: context);
    }
    // 返回ZIP文件路径
    return zipFile.path;
  }

  /// 选择 ZIP 文件并导入
  Future<void> _pickZipFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    debugPrint("result.files.single.path: ${result?.files.single.path}");
    if (!mounted) return;
    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedZipFile = File(result.files.single.path!); // 更新状态
      });
      _handleImport(context);
    } else {
      print('未选择文件');
      zToast('未选择文件', position: 'center', context: context);
    }
  }

// 检查是否有现有数据
  Future<bool> _hasExistingData() async {
    final sql = SQLHelper();
    List<Doodle> doodles = await sql.getDoodles();
    bool imagesExist = await imagesDirectory!.exists() &&
        imagesDirectory!.listSync().isNotEmpty;

    return doodles.isNotEmpty || imagesExist;
  }

  // 处理导入逻辑
  Future<void> _handleImport(BuildContext context) async {
    debugPrint("selectedZipFile: $selectedZipFile");
    if (selectedZipFile != null) {
      bool hasExistingData = await _hasExistingData();

      // 检测到有现有数据，询问是否覆盖
      if (hasExistingData) {
        bool? shouldOverwrite = await _confirmOverwrite(context);
        if (shouldOverwrite == true) {
          await _clearExistingData(); // 清除现有数据
        } else {
          return; // 用户选择不覆盖，直接返回
        }
      }
      EasyLoading.showToast('正在导入数据...', dismissOnTap: false);
      // 执行数据和文件导入
      await _importDataAndFiles(selectedZipFile!);
      // 提示
      EasyLoading.showSuccess('数据和文件导入完成，请重启应用');
    } else {
      EasyLoading.showError('请选择要导入的文件');
    }
  }

  /// 具体的执行导入的操作
  Future<void> _importDataAndFiles(File zipFile) async {
    // 重新打开数据库，确保读取到新的数据库
    final sqlHelper = SQLHelper();
    String dbName = sqlHelper.databaseName;

    // 获取当前应用文档目录
    final directory = await getApplicationDocumentsDirectory();
    final imagesDirectory = Directory('${directory.path}/noteImages');
    final archive = ZipDecoder().decodeBytes(await zipFile.readAsBytes());
    // 获取当前应用的数据库目录
    final dbDirectory = await getDatabasesPath();
    final dbPath = join(dbDirectory, dbName); // 目标数据库路径
    for (final file in archive) {
      debugPrint("file.name: ${file.name}");
      // 处理 SQLite 数据库文件
      if (file.isFile && file.name == dbName) {
        // 覆盖现有的 SQLite 数据库文件
        final dbFile = File(dbPath);
        if (await dbFile.exists()) {
          await dbFile.delete();
        }
        await File(dbPath).writeAsBytes(file.content);

        debugPrint('新数据库文件已成功导入: $dbPath');
      } else if (file.isFile && file.name.startsWith('encryption_key')) {
        // 将加密密钥存储到安全存储区
        final secureStorage = FlutterSecureStorage();
        final newEncryptionKey = utf8.decode(file.content);
        await secureStorage.write(
            key: 'db_encryption_key', value: newEncryptionKey);
        // 打开数据库
        await sqlHelper.close(); // 重新打开数据库连接，使用新的数据库文件
        await sqlHelper.open(); // 重新打开数据库连接，使用新的数据库文件
      }
      // 处理图片文件
      else if (file.isFile && file.name.startsWith('temp_images/')) {
        // 获取图片文件名并去除临时文件夹前缀
        final relativeImagePath = file.name.replaceFirst('temp_images/', '');

        // 确保 images 目录存在
        if (!await imagesDirectory.exists()) {
          await imagesDirectory.create(recursive: true);
        }

        // 目标图片文件路径
        final imageFile = File('${imagesDirectory.path}/$relativeImagePath');

        // 写入图片文件到 images 文件夹
        await imageFile.writeAsBytes(file.content);
        debugPrint('已成功导入图片: ${imageFile.path}');
      }
    }
  }

  // 确认是否覆盖现有数据
  Future<bool?> _confirmOverwrite(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog.adaptive(
          title: const Text('确认覆盖'),
          content: const Text('检测到已有数据，是否覆盖现有数据和文件？'),
          actions: [
            TextButton(
              child: const Text('取消'),
              onPressed: () => context.pop(false), // 返回 false
            ),
            TextButton(
              child: const Text('覆盖'),
              onPressed: () => context.pop(true), // 返回 true
            ),
          ],
        );
      },
    );
  }

// 删除现有数据和图片文件
  Future<void> _clearExistingData() async {
    // 删除现有图片文件
    if (await imagesDirectory!.exists()) {
      await imagesDirectory!.delete(recursive: true); // 删除图片目录及其内容
      await imagesDirectory!.create(); // 重新创建空的图片目录
    }

    // 获取 SQLite 数据库路径并删除现有的数据库文件
    String dbName = SQLHelper().databaseName;
    final dbDirectory = await getDatabasesPath();
    final dbPath = join(dbDirectory, dbName);

    final currentDbFile = File(dbPath);
    if (await currentDbFile.exists()) {
      SQLHelper().close();
      await currentDbFile.delete();
      debugPrint('已删除现有的数据库文件: $dbPath');
    }
  }

  Future<void> _cloudBackup(BuildContext context) async {
    EasyLoading.showInfo('正在备份数据...', dismissOnTap: false);
    final filePath = await _exportDataAndFiles(context);
    debugPrint("filePath: $filePath");

    // 准备分享云盘
    final result = await Share.shareXFiles(
      [XFile(filePath, name: '韶华纪备份导出文件')], // 修改文件名为 'NewFileName.jpg'
    );
    debugPrint("result: $result");
    if (result.status == ShareResultStatus.success) {
      EasyLoading.showInfo('数据备份成功 ');
    }
  }
}
