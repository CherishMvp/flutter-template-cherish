import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:com.cherish.mingji/model/data.dart';
import 'package:com.cherish.mingji/utils/db_note.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart'; // 用于处理文件路径
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import 'package:com.cherish.mingji/components/common/cherish_appbar.dart';

class Export extends StatefulWidget {
  const Export({super.key});

  @override
  State<Export> createState() => _ExportState();
}

class _ExportState extends State<Export> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // 或 false
  // 用于存储导出的信息
  final TextEditingController _controller = TextEditingController();
  // 当前上传图片路径
  String? uploadImagePath;
  // 获取应用文档目录路径
  Directory? directory;

// 获取源数据内容
  File? selectedZipFile;

  Directory? imagesDirectory;

  // 测试图片路径
  String? testImagePath = '1727160163921_微信图片_20240919150049.jpg';

  @override
  void initState() {
    super.initState();
    _initializeDirectory();
  }

  @override
  void dispose() {
    _controller.dispose();
    deposeHandle();
    super.dispose();
  }

  deposeHandle() async {
    final rs = await selectedZipFile?.delete();
    print("删除结果:${rs.toString()}");
  }

  void _initializeDirectory() async {
    // 获取应用文档目录
    final tempDirectory = await getApplicationDocumentsDirectory();
    // 如果目标文件夹不存在，创建文件夹
    final imageDirectory = Directory('${tempDirectory.path}/images');
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

  void reloadPage() {
    updateKeepAlive();
    _initializeDirectory();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        appBar: CherishAppbar(
          title: 'My Custom AppBar',
          iconSize: 18.0, // 调整图标大小
          fontSize: 16.0, // 调整文字大小
          actions: [
            IconButton(
              icon: Icon(Icons.search, size: 18.0),
              onPressed: () {
                print("Search button pressed");
              },
            ),
            IconButton(
              icon: Icon(Icons.more_vert, size: 18.0),
              onPressed: () {
                print("More button pressed");
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
            child: Center(
          child: Column(children: [
            // 上传图片内容
            directory != null && uploadImagePath != null
                ? Image.file(File(join(directory!.path, uploadImagePath!)),
                    width: 200, height: 200)
                : Container(),
            const SizedBox(height: 20),
            Text(
              "测试图片路径${directory.toString()}",
              maxLines: 4,
            ),
            testImagePath != null && directory != null
                ? File(join(directory!.path, 'images', testImagePath))
                        .existsSync()
                    ? Image.file(
                        height: 200,
                        width: 300,
                        File(join(directory!.path, 'images', testImagePath)))
                    : const Text("图片不存在")
                : const SizedBox.shrink(),

            // 上传图片
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '输入你要导入的信息',
                  labelText: '导入信息'),
            ),
            CupertinoButton(
              child: Text("上传图片"),
              onPressed: () {
                uploadImage();
              },
            ),
            CupertinoButton(
              child: Text("云盘备份"),
              onPressed: () {
                cloudBackup();
              },
            ),
            CupertinoButton(
              child: Text("导出数据"),
              onPressed: () {
                exportDataAndFiles();
              },
            ),
            ElevatedButton(
              onPressed: _pickZipFile,
              child: Text('选择 ZIP 文件'),
            ),
            // 开始导入
            //  _handleImport
            if (selectedZipFile != null)
              ElevatedButton(
                onPressed: () => _handleImport(context),
                child: Text('开始导入'),
              ),
            SizedBox(height: 20),
          ]),
        )));
  }

  Future<void> uploadImage() async {
    // 1. 请求存储和相机权限
    await _requestPermissions();

    // 初始化ImagePicker
    final ImagePicker picker = ImagePicker();

    // 让用户从图库中选择图片
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      print('未选择图片');
      return;
    }

    // 定义保存路径
    final String fileName = basename(image.path); // 获取文件名
    final File newImage = File(
        '${directory?.path}/images/${DateTime.now().millisecondsSinceEpoch}_$fileName');

    // 将选择的图片复制到应用目录下
    // await File(image.path).copy(newImage.path);
    String imageUrl = newImage.path;
    debugPrint("newImage.path: $imageUrl");

    final newFile = File(imageUrl);

    // Copy the image to the new file
    await newFile.writeAsBytes(await image.readAsBytes());
    // 构建图片链接或路径（存储在数据库中的路径）

    // TODO: 上传图片到服务器
    // 2. 假设已经实现了图片上传逻辑，返回远程URL或存储路径
    // String imageUrl = await uploadImageToServer(imageFile); // 上传并获取URL
    // 构建doodle数据
    Map<String, dynamic> doodleData = {
      'name': '示例Doodle',
      'time': DateTime.now().toString(),
      'content': '这是一个示例内容+${DateTime.now().toString()}',
      'doodle': fileName, // 存储图片路径到数据库  // 存储filename就行了
    };

    // 插入数据到数据库
// 创建方法
// 删除image
    File(image.path).delete();
    setState(() {
      uploadImagePath = imageUrl;
    });
    print('图片上传成功并存储路径：$imageUrl');
  }

// 请求权限
  Future<void> _requestPermissions() async {
    PermissionStatus storagePermission = await Permission.storage.status;
    PermissionStatus cameraPermission = await Permission.camera.status;

    // 检查并请求存储权限
    if (!storagePermission.isGranted) {
      storagePermission = await Permission.storage.request();
    }

    // 检查并请求相机权限
    if (!cameraPermission.isGranted) {
      cameraPermission = await Permission.camera.request();
    }

    if (!storagePermission.isGranted || !cameraPermission.isGranted) {
      throw Exception('存储或相机权限未授权');
    }
  }

// 设置数据库文件可写
  Future<void> setWritablePermissions(String dbPath) async {
    // 检查数据库文件是否存在
    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      // 设置文件为可读写
      // await dbFile.setPermissions(FilePermission.readWrite);
    }
  }

// 这里是上传图片的示例方法，假设实现了上传逻辑
  Future<String> uploadImageToServer(File imageFile) async {
    // 假设上传到服务器并返回图片的 URL
    // 上传逻辑略去，可以使用 http 包或者其他工具上传文件
    return 'https://your-server.com/uploads/${basename(imageFile.path)}';
  }

  Future<void> deleteDoodleExample(int doodleId) async {}

  Future<String> exportDataAndFiles() async {
    // 获取数据库数据
    final sql = SQLHelper();
    List<Doodle> doodles = await sql.getDoodles();
    String dbName = 'doodles.db'; // 替换为实际的数据库名称

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
    final imagesDirectory = Directory('${directory.path}/images');

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
      // 将整个临时文件夹添加到压缩包
      encoder.addDirectory(tempImageDirectory);
    }

    // 关闭ZIP文件
    encoder.close();

    // 清理临时文件和目录
    await jsonFile.delete(); // 删除doodles.json
    await tempImageDirectory.delete(recursive: true); // 递归删除临时文件夹

    // 返回ZIP文件路径
    return zipFile.path;
  }

// 检查是否有现有数据
  Future<bool> _hasExistingData() async {
    final sql = SQLHelper();
    List<Doodle> doodles = await sql.getDoodles();
    bool imagesExist = await imagesDirectory!.exists() &&
        imagesDirectory!.listSync().isNotEmpty;

    return doodles.isNotEmpty || imagesExist;
  }

// 选择 ZIP 文件
  Future<void> _pickZipFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    debugPrint("result.files.single.path: ${result?.files.single.path}");
    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedZipFile = File(result.files.single.path!); // 更新状态
        _controller.text = selectedZipFile!.path;
      });
    } else {
      print('未选择文件');
    }
  }

// 确认是否覆盖现有数据
  Future<bool?> _confirmOverwrite(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认覆盖'),
          content: const Text('检测到已有数据，是否覆盖现有数据和文件？'),
          actions: [
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(context).pop(false), // 返回 false
            ),
            TextButton(
              child: const Text('覆盖'),
              onPressed: () => Navigator.of(context).pop(true), // 返回 true
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
    String dbName = 'doodles.db';
    final dbDirectory = await getDatabasesPath();
    final dbPath = join(dbDirectory, dbName);

    final currentDbFile = File(dbPath);
    if (await currentDbFile.exists()) {
      await currentDbFile.delete();
      debugPrint('已删除现有的数据库文件: $dbPath');
    }
  }

// 导入新的数据库文件
  Future<void> importDatabase(File newDatabaseFile) async {
    // 获取 SQLite 默认数据库路径
    String dbName = 'doodles.db';
    final dbDirectory = await getDatabasesPath();
    final dbPath = join(dbDirectory, dbName);

    // 将新的数据库文件复制到应用的数据库路径
    await newDatabaseFile.copy(dbPath);
    debugPrint('新数据库文件已成功导入到: $dbPath');
  }

// 导入数据和文件
// 导入数据和文件
  Future<void> _importDataAndFiles(File zipFile) async {
    String dbName = 'doodles.db';

    // 获取当前应用文档目录
    final directory = await getApplicationDocumentsDirectory();
    final imagesDirectory = Directory('${directory.path}/images');
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
    // 重新打开数据库，确保读取到新的数据库
    final sql = SQLHelper();
    await sql.close(); // 关闭旧的数据库连接
    await sql.open(); // 重新打开数据库连接，使用新的数据库文件
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

      // 执行数据和文件导入
      await _importDataAndFiles(selectedZipFile!);
      debugPrint('数据和文件导入完成');
      // 提示
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('数据和文件导入完成'),
      ));
      reloadPage();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('请选择要导入的文件'),
      ));
    }
  }

// 清空数据库主表内容
  Future<void> clearDatabase() async {
    // 获取数据库实例
    SQLHelper sqlHelper = SQLHelper();
    Database db = await sqlHelper.database;

    // 获取数据库中的所有表名
    List<Map<String, dynamic>> tables =
        await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");

    // 遍历每个表，并清空它的内容
    for (var table in tables) {
      String tableName = table['name'];
      if (tableName != 'sqlite_sequence') {
        // 这里不清空 SQLite 的内部表 `sqlite_sequence`
        await db.delete(tableName);
      }
    }

    print("数据库已清空");
  }

  Future<void> cloudBackup() async {
    final filePath = await exportDataAndFiles();
    debugPrint("filePath: $filePath");
    // 准备分享云盘
    final result =
        await Share.shareXFiles([XFile(filePath)], text: 'Cloud Backup');
    debugPrint("result: $result");
    if (result.status == ShareResultStatus.success) {
      print('Thank you for sharing the picture!');
    }
  }
}
