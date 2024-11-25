import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:com.cherish.mingji/model/data.dart';
import 'package:com.cherish.mingji/model/label_info.dart';
import 'package:com.cherish.mingji/pages/export/tools/common.dart';
import 'package:com.cherish.mingji/utils/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:sqflite/sqflite.dart';
import 'package:sqflite_sqlcipher/sqflite.dart'; // 使用加密的 sqflite_sqlcipher
import 'package:path/path.dart';

class SQLHelper {
  static final SQLHelper _instance = SQLHelper._internal();
  final _secureStorage = FlutterSecureStorage();
  static String dbName = 'time_line.db';
  static String tableDoodles = 'doodles';
  static String tableLabel = 'labels';

  Database? _database;

  factory SQLHelper() {
    return _instance;
  }

  SQLHelper._internal();

  Future<Database> get database async {
    debugPrint("_database: $_database");
    if (_database != null) return _database!;
    _database = await _initDB(dbName);
    return _database!;
  }

// 初始化数据库内容
  Future<Database> _initDB(String dbName) async {
    String path = join(await getDatabasesPath(), dbName);
    debugPrint('response data is $path');
    // 从 secure storage 中获取加密密钥
    String? encryptionKey = await _secureStorage.read(key: 'db_encryption_key');
    debugPrint('response data is $encryptionKey');
    encryptionKey ??= await getOrCreateEncryptionKey();
    debugPrint('response data is $encryptionKey');

    try {
      return await openDatabase(
        path,
        version: 1,
        password: encryptionKey, // 通过加密密钥打开数据库
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } on Exception catch (e) {
      // 如果数据库格式不对，说明数据库未加密，进行加密迁移
      if (e.toString().contains("file is not a database")) {
        return await _migrateToEncryptedDB(path, encryptionKey);
      } else {
        throw Exception("${e}Make sure the database is created and stored.");
      }
    }
  }

// 数据库表创建逻辑
  Future<void> _onCreate(Database db, int version) async {
    await _createDoodleTable(db);
    await _createLabelTable(db);
  }

// 更新表结构
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (newVersion > oldVersion) {
      try {
        await updateDoodleTableWeather(db);
        debugPrint("执行完成");
      } on Exception catch (e) {
        // TODO
        debugPrint(e.toString());
      }
    }
  }

// 创建doodle表
  Future<void> _createDoodleTable(Database database) async {
    await database.execute("""CREATE TABLE doodles(
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    name TEXT,
    time TEXT,
    content TEXT,
    doodle TEXT,   
    label TEXT DEFAULT '1',
    weather TEXT DEFAULT '',
    location TEXT DEFAULT '',
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
    """);
  }

// label、weather、location等
// 更新表doodles结构
  Future<void> updateDoodleTableWeather(Database database) async {
    // 添加新的列 label, weather, location
    await database
        .execute('ALTER TABLE doodles ADD COLUMN label TEXT DEFAULT \'1\'');
    await database
        .execute('ALTER TABLE doodles ADD COLUMN weather TEXT DEFAULT \'\'');
    await database
        .execute('ALTER TABLE doodles ADD COLUMN location TEXT DEFAULT \'\'');

    // 你可以根据需求，选择是否更新现有数据。
    // 如果你需要为已有数据设置这些列的默认值，下面这行可以用来更新所有的旧数据。
    await database.execute(
        'UPDATE doodles SET label = \'1\', weather = \'\', location = \'\'');
  }

// 创建标签表
  Future<void> _createLabelTable(Database database) async {
    await database.execute("""CREATE TABLE $tableLabel(
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      title TEXT NOT NULL,
      subtitle TEXT,
      bgColor TEXT NOT NULL,
      isUserAdd INTEGER NOT NULL DEFAULT 0,
      createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
     )
     """);
    //  插入默认标签值
    final count = await database.rawQuery('SELECT COUNT(*) FROM labels');
    final isEmpty = count.first['COUNT(*)'] == 0;
    log("isEmpty$isEmpty");
    if (isEmpty) {
      await database
          .execute("""INSERT INTO labels (title, subtitle, bgColor, isUserAdd)
      VALUES
          ('默认分类', '默认分类', '#CC5500', 0),
          ('Todo', '待办事项', '#B22222', 0),
          ('Goal', '目标类别', '#FFBF00', 0)
    """);
    }
  }

  // 迁移未加密数据库到加密数据库
  Future<Database> _migrateToEncryptedDB(
      String path, String encryptionKey) async {
    try {
      // 尝试打开未加密的数据库
      Database db = await openDatabase(path);

      // 执行加密迁移
      await db.execute(
          'ATTACH DATABASE ? AS encrypted KEY ?', [path, encryptionKey]);
      await db.execute('SELECT sqlcipher_export("encrypted");');
      await db.execute('DETACH DATABASE encrypted;');

      print("Database successfully migrated to encrypted format.");

      // 关闭未加密的数据库
      await db.close();

      // 重新打开加密数据库
      return await openDatabase(
        path,
        password: encryptionKey,
        version: 1,
        onCreate: _onCreate,
      );
    } catch (e) {
      throw Exception("Failed to migrate database: $e");
    }
  }

  // 打开数据库
  Future<void> open() async {
    if (_database == null || !_database!.isOpen) {
      _database = await _initDB('doodles.db');
      debugPrint('Database opened.');
    } else {
      debugPrint('Database is already open.');
    }
  }

  // 关闭数据库
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
      debugPrint('Database closed.');
    } else {
      debugPrint('Database is already closed or not initialized.');
    }
  }

  ///具体的sql操作
  Future<int> createDoodle(Doodle doodle) async {
    final db = await database;
    final data = doodle.toMap();
    data['createdAt'] = DateTime.now().toString();
    log("插入内容${data.toString()}");
    final id = await db.insert('doodles', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  Future<int> updateDoodle(Doodle doodle) async {
    final db = await database;
    final data = doodle.toMap();
    final id = await db.update(
      'doodles',
      data,
      where: 'id = ?',
      whereArgs: [doodle.id],
    );
    return id;
  }

  ///拿到指定id的所有图片
  Future<int> _deleteImageInFile(int id) async {
    final db = await database;
    final data = await db.query('doodles', where: 'id = ?', whereArgs: [id]);
    log("拿到数据${data.toString()}");
    final filePaths = data.first['doodle'] as String;
    final paths = filePaths.split(','); //多个图片
    log("删除图片${paths.toString()}");
    var rowsDeleted = 0;
    try {
      await Future.forEach(paths, (path) async {
        final p = path.replaceFirst('noteImages/', '');
        await deleteAssetsByPath(p);
      });
      // 执行删除数据库内容
      final db = await database;
      rowsDeleted = await db.delete(
        'doodles',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error deleting image: $e');
    } finally {
      return rowsDeleted;
    }
  }

  ///删除指定路径中的图片
  Future<void> deleteAssetsByPath(String filePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final noteImagesPath = Directory('${directory.path}/noteImages');
    try {
      final file = File('${noteImagesPath.path}/$filePath');
      // final file = File(filePath); //如果存的是完整路径则不需要拼接
      await file.delete();
      log("删除图片$filePath");
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  Future<bool> deleteDoodle(int id) async {
    var rowsDeleted = 0;
    try {
      rowsDeleted = await _deleteImageInFile(id);
      log("删除对象$rowsDeleted");
      return true;
    } on Exception catch (e) {
      // TODO
      return false;
    } finally {
      // await database;
      log("删除成功$id,结果：$rowsDeleted");
    }
  }

// 得到md固定格式content内容
  Future<String> _getEditInfo(Doodle info, String prefixPath) async {
    final info2 = jsonDecode(info.content);
    List<dynamic> newJsonData = reverseProcessJsonData(info2, prefixPath);
    debugPrint("newJsonData: $newJsonData");
    return jsonEncode(newJsonData);
  }

  /// sql获取内容 拼接路径
  // TODO 考虑全局处理内容
  Future<List<Doodle>> getDoodles() async {
    final db = await database;
    final maps = await db.rawQuery('SELECT * FROM doodles ORDER BY id DESC');
    final res = maps.map((map) => Doodle.fromMap(map)).toList();
    final prefs = await SharedPreferences.getInstance();
    // TODO 两个的图片路径其实是一样的
    final String noteImagesPath = (prefs.getString('noteImagesPath')!);
    final String noteImagesDir =
        prefs.getString('noteImagesPath')!; //main.dart处理了，必有;
    log("noteImagesPath$noteImagesPath");
    // 在sql拿到的时候已经处理过路径拼接了
    for (var note in res) {
      if (note.doodle.isNotEmpty) {
        note.doodle =
            note.doodle.split(',').map((n) => noteImagesPath + n).join(',');
      }
      if (note.content.isNotEmpty) {
        note.content = await _getEditInfo(note, noteImagesDir);
        note.doodle =
            extractImagePaths(jsonDecode(note.content), noteImagesDir);
      }
    }

    log("数据库获取数据完成${res[0].doodle}");
    log(res.toString());
    return res;
  }

// label分类标签相关
// 假设你有一个 SQLite 数据库，表名为 'label_items'
  Future<List<LabelItem>> getLabelListItems() async {
    final db = await database;
    final List<Map<String, dynamic>> data =
        await db.rawQuery('SELECT * FROM labels');
    // 将读取到的数据转换为 LabelListItems
    final List<LabelItem> labelListItems = data.map((item) {
      return LabelItem(
        id: item['id'],
        title: item['title'],
        subtitle: item['subtitle'],
        bgColor: HexColor(item['bgColor']),
        isUserAdd: item['isUserAdd'],
      );
    }).toList();

    return labelListItems;
  }

// 默认label的id从1-6 不允许修改
  final defaultLabelListID = [1, 2, 3, 4, 5, 6];

  /// 根据id删除label
  Future<int> deleteLabelItem(int id) async {
    if (defaultLabelListID.contains(id)) {
      return 0;
    }
    final db = await database;
    return await db.delete('labels', where: 'id = ?', whereArgs: [id]);
  }

  /// 根据id修改label
  Future<int> updateLabelItem(LabelItem item) async {
    if (defaultLabelListID.contains(item.id)) {
      return 0;
    }
    final db = await database;
    return await db.update(
      'labels',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// 创建label
  Future<int> createLabelItem(
      String title, String subtitle, String bgColor, bool isUserAdd) async {
    final db = await database;
    return await db.insert(
      'labels',
      {
        'title': title,
        'subtitle': subtitle,
        'bgColor': bgColor,
        'isUserAdd': isUserAdd ? 1 : 0,
      },
    );
  }

  // 获取当前note的label信息
  Future<List<LabelItem>> getLabelListItemsByIds(List<int> labelIds) async {
    // 将 id 列表转换为字符串，用于 SQL IN 查询
    final String idList = labelIds.join(',');

    // 获取数据库实例
    final db = await database;

    // 使用 SQL 的 IN 子句查找多个 id 对应的标签
    final List<Map<String, dynamic>> data = await db.rawQuery(
      'SELECT * FROM labels WHERE id IN ($idList)',
    );

    // 将读取到的数据转换为 LabelItem 对象列表
    final List<LabelItem> labelListItems = data.map((item) {
      return LabelItem(
        id: item['id'],
        title: item['title'],
        subtitle: item['subtitle'],
        bgColor: HexColor(item['bgColor']),
        isUserAdd: item['isUserAdd'],
      );
    }).toList();

    return labelListItems;
  }

  ///获取每日记录数 统计每天的数量，用于计数，createdAt作为key
  Future<Map<DateTime, int>> getHeatMapDatasets() async {
    final db = await database;
    final List<Map<String, dynamic>> data = await db.rawQuery(
        'SELECT createdAt, COUNT(*) as count FROM doodles GROUP BY createdAt');

// mock data为空
    if (data.isEmpty) {
      return {};
    }
    final Map<DateTime, int> heatMapDatasets = {};
    for (var item in data) {
      // 解析 'createdAt' 为 DateTime
      final DateTime date = DateTime.parse(item['createdAt']);

      // 创建一个新的 DateTime，只保留年、月、日，忽略时间部分
      final DateTime dayOnly = DateTime(date.year, date.month, date.day);

      // 如果 heatMapDatasets 已经包含该日期，则累加 count，否则创建新的 entry
      if (heatMapDatasets.containsKey(dayOnly)) {
        heatMapDatasets[dayOnly] =
            (heatMapDatasets[dayOnly]! + item['count']).toInt();
      } else {
        heatMapDatasets[dayOnly] = item['count'];
      }
    }

    debugPrint("heatMapDatasets ${heatMapDatasets.toString()}");
    return heatMapDatasets;
  }
}
